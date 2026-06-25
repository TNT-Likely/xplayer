import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import 'package:xplayer/services/sync/config_export_service.dart';

/// 源端「开放同步」:限时 HTTP 服务(/config、/ping)+ bonsoir 广播 _xplayersync._tcp。
class LanSyncServer {
  static const String serviceType = '_xplayersync._tcp';
  HttpServer? _server;
  BonsoirBroadcast? _broadcast;
  Timer? _autoStop;
  final ValueNotifier<bool> running = ValueNotifier(false);
  final ValueNotifier<int> remainingSec = ValueNotifier(0);
  int _port = 0;
  int get port => _port;

  Future<void> start({Duration ttl = const Duration(minutes: 3)}) async {
    if (running.value) return;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _port = _server!.port;
    _server!.listen(_handle);

    final service = BonsoirService(
      name: 'XPlayer-${Platform.localHostname}',
      type: serviceType,
      port: _port,
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();

    running.value = true;
    remainingSec.value = ttl.inSeconds;
    _autoStop?.cancel();
    _autoStop = Timer.periodic(const Duration(seconds: 1), (t) {
      remainingSec.value -= 1;
      if (remainingSec.value <= 0) stop();
    });
  }

  Future<void> _handle(HttpRequest req) async {
    try {
      if (req.uri.path == '/config') {
        final bundle = await ConfigExportService().export();
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode(bundle.toJson()));
      } else if (req.uri.path == '/ping') {
        req.response.write(Platform.localHostname);
      } else {
        req.response.statusCode = HttpStatus.notFound;
      }
    } catch (_) {
      req.response.statusCode = HttpStatus.internalServerError;
    } finally {
      await req.response.close();
    }
  }

  Future<void> stop() async {
    _autoStop?.cancel();
    _autoStop = null;
    try {
      await _broadcast?.stop();
    } catch (_) {}
    _broadcast = null;
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    running.value = false;
    remainingSec.value = 0;
  }
}
