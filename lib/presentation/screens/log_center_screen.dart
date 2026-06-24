import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:xplayer/services/log_store.dart';
import 'package:xplayer/utils/toast.dart';

/// 统一日志中心:
/// - 展示全应用 Dart 日志(Logger.* / 未捕获异常)+ 诊断结果(播放地址 / 探流编码 / 解码器能力 / ExoPlayer)。
/// - 级别 + 关键字过滤,复制 / 清空。
/// - 局域网 HTTP 导出 `http://<本机IP>:8099/`,同 WiFi 电脑可 curl/浏览器取全文(电视等无 adb 设备用)。
/// 跨平台:iPhone 也能看 Dart 日志;Android 额外把原生诊断结果写进来。
class LogCenterScreen extends StatefulWidget {
  const LogCenterScreen({super.key});

  @override
  State<LogCenterScreen> createState() => _LogCenterScreenState();
}

class _LogCenterScreenState extends State<LogCenterScreen> {
  static const MethodChannel _diag = MethodChannel('diag/logcat');
  static const int _port = 8099;

  final ScrollController _scroll = ScrollController();
  // 默认只看错误日志;其余级别按需勾选。
  final Set<LogLevel> _levels = {LogLevel.error};
  String _filter = '';
  HttpServer? _server;
  String _exportInfo = '局域网导出:启动中…';

  @override
  void initState() {
    super.initState();
    _startServer();
    _runDiagnostics();
  }

  @override
  void dispose() {
    _server?.close(force: true);
    _scroll.dispose();
    super.dispose();
  }

  /// 拉取原生诊断结果(解码器能力 + ExoPlayer 应用内日志)写入日志中心。仅 Android 有。
  Future<void> _runDiagnostics() async {
    try {
      final codecs = await _diag.invokeMethod<String>('getCodecs');
      if (codecs != null && codecs.trim().isNotEmpty) {
        LogStore.instance.i('codec', codecs.trim());
      }
    } catch (_) {/* 非 Android 忽略 */}
    try {
      final exo = await _diag.invokeMethod<String>('getAppLog');
      if (exo != null && exo.trim().isNotEmpty && !exo.contains('暂无')) {
        LogStore.instance.i('exo', exo.trim());
      }
    } catch (_) {}
  }

  String _composed() => LogStore.instance
      .exportText(levels: _levels, filter: _filter);

  Future<void> _startServer() async {
    try {
      _server =
          await HttpServer.bind(InternetAddress.anyIPv4, _port, shared: true);
      _server!.listen((HttpRequest req) async {
        req.response
          ..headers.contentType = ContentType.text
          ..write(LogStore.instance.exportText());
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

  // 遥控器 D-pad:上下滚动日志列表;到顶 ↑ 放行(焦点回到顶部按钮),不卡死。
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_scroll.hasClients) return KeyEventResult.ignored;
    final max = _scroll.position.maxScrollExtent;
    const step = 180.0;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_scroll.offset >= max) return KeyEventResult.ignored;
      _scroll.animateTo((_scroll.offset + step).clamp(0.0, max),
          duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_scroll.offset <= 0) return KeyEventResult.ignored;
      _scroll.animateTo((_scroll.offset - step).clamp(0.0, max),
          duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _levelName(AppLocalizations l, LogLevel lv) {
    switch (lv) {
      case LogLevel.debug:
        return l.logLevelDebug;
      case LogLevel.info:
        return l.logLevelInfo;
      case LogLevel.warning:
        return l.logLevelWarning;
      case LogLevel.error:
        return l.logLevelError;
    }
  }

  Color _colorFor(LogLevel l) {
    switch (l) {
      case LogLevel.debug:
        return Colors.white60;
      case LogLevel.info:
        return Colors.white;
      case LogLevel.warning:
        return Colors.orangeAccent;
      case LogLevel.error:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      appBar: AppBar(
        title: Text(l10n.diagLog,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined, color: Colors.white),
            tooltip: '运行诊断',
            onPressed: () async {
              await _runDiagnostics();
              showToast('已运行诊断(解码器能力 / ExoPlayer)');
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            tooltip: '复制全部',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _composed()));
              showToast('已复制日志');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: '清空',
            onPressed: () => LogStore.instance.clear(),
          ),
        ],
      ),
      // 遥控器:左右在级别 chips/搜索/按钮间移动并 OK 切换,上下滚动日志列表。
      // 不 autofocus 容器(改为首个 chip autofocus),上下键冒泡到这里滚动。
      body: Focus(
        onKeyEvent: _handleKey,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.white10,
              child: SelectableText(
                _exportInfo,
                style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
              ),
            ),
            // 级别过滤 chips + 搜索
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  for (final lv in LogLevel.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        autofocus: lv == LogLevel.debug, // 进页面默认焦点落在第一个 chip
                        label: Text(_levelName(l10n, lv),
                            style: const TextStyle(fontSize: 12)),
                        selected: _levels.contains(lv),
                        onSelected: (s) => setState(() =>
                            s ? _levels.add(lv) : _levels.remove(lv)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  Expanded(
                    child: TextField(
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: '过滤关键字',
                        hintStyle: TextStyle(color: Colors.white38),
                        isDense: true,
                        prefixIcon: Icon(Icons.search,
                            color: Colors.white38, size: 18),
                      ),
                      onChanged: (v) => setState(() => _filter = v),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: LogStore.instance,
                builder: (_, __) {
                  final f = _filter.toLowerCase();
                  final list = LogStore.instance.entries
                      .where((e) =>
                          _levels.contains(e.level) &&
                          (f.isEmpty ||
                              e.message.toLowerCase().contains(f) ||
                              e.tag.toLowerCase().contains(f)))
                      .toList()
                      .reversed
                      .toList();
                  if (list.isEmpty) {
                    return const Center(
                      child: Text('暂无日志',
                          style: TextStyle(color: Colors.white38)),
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final e = list[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 1),
                        child: SelectableText(
                          e.format(),
                          style: TextStyle(
                              color: _colorFor(e.level),
                              fontSize: 11,
                              fontFamily: 'monospace'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
