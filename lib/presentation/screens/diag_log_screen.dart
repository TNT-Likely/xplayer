import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:xplayer/utils/toast.dart';

/// 诊断日志中心:
/// - 原生 `diag/logcat` 通道读取本应用 logcat(含 MediaCodec 解码器行等)。
/// - 屏上显示 + 关键字过滤 + 复制。
/// - 起一个局域网 HTTP 服务,给出 `http://<本机IP>:8099/`,同 WiFi 的电脑可 curl/浏览器取全文
///   —— 用于电视等无法连 adb 的设备把日志导出。
class DiagLogScreen extends StatefulWidget {
  const DiagLogScreen({super.key});

  @override
  State<DiagLogScreen> createState() => _DiagLogScreenState();
}

class _DiagLogScreenState extends State<DiagLogScreen> {
  static const MethodChannel _channel = MethodChannel('diag/logcat');
  static const int _port = 8099;

  String _logs = '';
  String _codecs = '';
  String _appLog = ''; // ExoPlayer 进程内截获日志(电视也能看)
  String _filter = '';
  HttpServer? _server;
  String _exportInfo = '局域网导出:启动中…';
  final ScrollController _pageScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _probeCodecs();
    _refresh();
    _startServer();
  }

  Future<void> _probeCodecs() async {
    try {
      final s = await _channel.invokeMethod<String>('getCodecs') ?? '';
      if (mounted) setState(() => _codecs = s);
    } catch (e) {
      if (mounted) setState(() => _codecs = '解码器探测失败:$e');
    }
  }

  Future<String> _fetchLogcat() async {
    try {
      return await _channel.invokeMethod<String>('getLogcat') ?? '';
    } on PlatformException catch (e) {
      return '读取 logcat 失败:${e.message}\n(此设备/系统可能限制读取自身日志;仅 Android 支持)';
    } on MissingPluginException {
      return '当前平台不支持 logcat(仅 Android)。';
    }
  }

  Future<void> _refresh() async {
    final s = await _fetchLogcat();
    String app = '';
    try {
      app = await _channel.invokeMethod<String>('getAppLog') ?? '';
    } catch (_) {}
    if (mounted) {
      setState(() {
        _logs = s;
        _appLog = app;
      });
    }
  }

  // 从 logcat 提取本次播放实际使用的视频解码器(ACodec/Codec2 行),并判定硬/软解。
  // 仅匹配视频解码器(含 video 或视频编码名),避开 c2.android.aac.decoder 这类音频。
  static final RegExp _decoderRe = RegExp(
    r'OMX\.[A-Za-z0-9]+\.video\.decoder\.[A-Za-z0-9.]+'
    r'|c2\.[A-Za-z0-9]+\.(?:avc|hevc|h264|h265|mpeg2|mpeg4|vp8|vp9|av01|av1)\.decoder(?:\.[A-Za-z0-9_]+)?',
    caseSensitive: false,
  );

  String _detectedDecoder(String logs) {
    String? name;
    for (final m in _decoderRe.allMatches(logs)) {
      name = m.group(0); // 取最后一个(日志时间正序,最新即当前)
    }
    if (name == null) {
      return '◆ 本次实际解码器: 未从日志提取到(电视等 logcat 不可读;改看下方「系统默认选中」)';
    }
    final lower = name.toLowerCase();
    final isSw =
        lower.startsWith('omx.google') || lower.startsWith('c2.android');
    return '◆ 本次实际解码器: $name  [${isSw ? "SW 软件解码" : "HW 硬件解码"}]';
  }

  // 实际解码器 + 解码器能力 + 日志的完整文本(复制全部 与 HTTP 导出共用)。
  String _composed(String logcat) =>
      '${_detectedDecoder("$_appLog\n$logcat")}\n\n'
      '===== 解码器能力 (MediaCodec) =====\n\n$_codecs\n'
      '===== ExoPlayer 应用内日志 =====\n\n$_appLog\n\n'
      '===== LOGCAT =====\n\n$logcat';

  void _copyAll() {
    Clipboard.setData(ClipboardData(text: _composed(_logs)));
    showToast('已复制全部(含解码器探测 + 日志)');
  }

  Future<void> _startServer() async {
    try {
      _server =
          await HttpServer.bind(InternetAddress.anyIPv4, _port, shared: true);
      _server!.listen((HttpRequest req) async {
        final logcat = await _fetchLogcat();
        final body = _composed(logcat);
        req.response
          ..headers.contentType = ContentType.text
          ..write(body);
        await req.response.close();
      });
      final ip = await _lanIp();
      if (mounted) {
        setState(() => _exportInfo = ip != null
            ? '局域网导出(同一 WiFi 下电脑浏览器/curl 打开):\nhttp://$ip:$_port/'
            : '已启动 $_port 端口,但未取到局域网 IP');
      }
    } catch (e) {
      if (mounted) setState(() => _exportInfo = '启动局域网服务失败:$e');
    }
  }

  Future<String?> _lanIp() async {
    try {
      final ifaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLoopback: false);
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _server?.close(force: true);
    _pageScroll.dispose();
    super.dispose();
  }

  // 遥控器 D-pad:上下滚动整页。到顶时 ↑ 放行(让焦点上移到顶部按钮),
  // 故不会卡在某个控件里;输入框为单行,上下键会冒泡到这里照样能滚。
  KeyEventResult _handlePageKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_pageScroll.hasClients) return KeyEventResult.ignored;
    final max = _pageScroll.position.maxScrollExtent;
    const step = 180.0;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_pageScroll.offset >= max) return KeyEventResult.ignored;
      _pageScroll.animateTo((_pageScroll.offset + step).clamp(0.0, max),
          duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_pageScroll.offset <= 0) return KeyEventResult.ignored;
      _pageScroll.animateTo((_pageScroll.offset - step).clamp(0.0, max),
          duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // 倒序:最新日志在最上面,不用滚到底。
    final lines = _logs
        .split('\n')
        .where((l) =>
            _filter.isEmpty || l.toLowerCase().contains(_filter.toLowerCase()))
        .toList()
        .reversed
        .toList();
    // 屏上各取上限行数,避免超大 SelectableText 卡顿(完整内容仍在复制/HTTP 导出里)。
    final logcatText = lines.take(600).join('\n');
    final appLines = _appLog.isEmpty ? const <String>[] : _appLog.split('\n');
    final appText = appLines.length > 600
        ? appLines.sublist(appLines.length - 600).join('\n')
        : _appLog;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.diagLog,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            tooltip: '复制全部',
            onPressed: _copyAll,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: '刷新',
            onPressed: _refresh,
          ),
        ],
      ),
      // 遥控器友好:整页放一个可滚动视图,顶层 Focus 处理 D-pad 上下滚动,
      // 不再卡在搜索框里(单行输入框的上下键会冒泡到这里滚动;到顶 ↑ 放行回到顶部按钮)。
      body: Focus(
        autofocus: true,
        onKeyEvent: _handlePageKey,
        child: SingleChildScrollView(
          controller: _pageScroll,
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.white10,
                child: SelectableText(
                  _exportInfo,
                  style:
                      const TextStyle(color: Colors.greenAccent, fontSize: 13),
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      _detectedDecoder('$_appLog\n$_logs'),
                      style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace'),
                    ),
                    const Divider(color: Colors.white24, height: 14),
                    SelectableText(
                      _codecs.isEmpty ? '解码器探测中…' : _codecs,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  'ExoPlayer 应用内日志(电视也能看):\n${appText.isEmpty ? "(暂无;播放后刷新)" : appText}',
                  style: const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: 11,
                      fontFamily: 'monospace'),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: '过滤(如 decoder / c2. / error)',
                    hintStyle: TextStyle(color: Colors.white38),
                    isDense: true,
                    prefixIcon:
                        Icon(Icons.search, color: Colors.white38, size: 18),
                  ),
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: SelectableText(
                  '===== logcat${_filter.isEmpty ? "" : "(已过滤)"} =====\n${logcatText.isEmpty ? "(无)" : logcatText}',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
