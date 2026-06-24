import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  String _filter = '';
  HttpServer? _server;
  String _exportInfo = '局域网导出:启动中…';

  @override
  void initState() {
    super.initState();
    _refresh();
    _startServer();
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
    if (mounted) setState(() => _logs = s);
  }

  Future<void> _startServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port, shared: true);
      _server!.listen((HttpRequest req) async {
        final body = await _fetchLogcat();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = _logs
        .split('\n')
        .where((l) =>
            _filter.isEmpty || l.toLowerCase().contains(_filter.toLowerCase()))
        .toList();
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
            onPressed: () => Clipboard.setData(ClipboardData(text: _logs)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: '刷新',
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: '过滤(如 decoder / c2. / error)',
                hintStyle: TextStyle(color: Colors.white38),
                isDense: true,
                prefixIcon: Icon(Icons.search, color: Colors.white38, size: 18),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: lines.length,
              itemBuilder: (_, i) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                child: SelectableText(
                  lines[i],
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
