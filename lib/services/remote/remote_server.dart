import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:xplayer/services/remote/remote_protocol.dart';

typedef TextInputHandler = void Function(String text);
typedef KeyInputHandler = void Function(String key);

class RemoteServer {
  final String serviceName;
  final TextInputHandler onText;
  final KeyInputHandler? onKey;

  HttpServer? _server;
  BonsoirBroadcast? _broadcast;
  final String _id = const Uuid().v4();
  int _port = 0;

  RemoteServer({
    required this.serviceName,
    required this.onText,
    this.onKey,
  });

  bool get isRunning => _server != null;
  int get port => _port;

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _port = _server!.port;
    final localIp = await _getLocalIPv4() ?? '0.0.0.0';

    // Advertise via mDNS
    final service = BonsoirService(
      name: serviceName,
      type: '_xplayer._tcp',
      port: _port,
      attributes: {
        'id': _id,
        'platform': Platform.operatingSystem,
        'host': localIp,
      },
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();

    // Accept WebSocket
    unawaited(_handleRequests());
  }

  Future<String?> _getLocalIPv4() async {
    try {
      final ifs = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLoopback: false);
      for (final ni in ifs) {
        for (final addr in ni.addresses) {
          final ip = addr.address;
          // 过滤链路本地与环回（已排除），倾向私有网段
          if (ip.startsWith('10.') ||
              ip.startsWith('192.168.') ||
              (ip.startsWith('172.') && _is172Private(ip))) {
            return ip;
          }
        }
      }
      // 回退：返回第一个非空 IPv4
      for (final ni in ifs) {
        for (final addr in ni.addresses) {
          final ip = addr.address;
          if (ip.isNotEmpty) return ip;
        }
      }
    } catch (_) {}
    return null;
  }

  bool _is172Private(String ip) {
    try {
      final seg = int.parse(ip.split('.')[1]);
      return seg >= 16 && seg <= 31;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleRequests() async {
    if (_server == null) return;
    await for (final req in _server!) {
      if (WebSocketTransformer.isUpgradeRequest(req)) {
        try {
          final socket = await WebSocketTransformer.upgrade(req);
          _handleSocket(socket);
        } catch (e) {
          req.response.statusCode = HttpStatus.internalServerError;
          await req.response.close();
        }
      } else {
        // Simple health endpoint
        req.response.statusCode = HttpStatus.ok;
        req.response.headers.set('content-type', 'application/json');
        req.response.write(jsonEncode({
          'name': serviceName,
          'id': _id,
          'port': _port,
        }));
        await req.response.close();
      }
    }
  }

  void _handleSocket(WebSocket socket) {
    socket.listen((data) {
      try {
        final map = jsonDecode(data as String) as Map<String, dynamic>;
        final msg = RemoteMessage.fromJson(map);
        switch (msg.type) {
          case RemoteMessageType.text:
            final text = (msg.payload['text'] as String?) ?? '';
            onText(text);
            socket.add(jsonEncode(
                RemoteMessage(RemoteMessageType.ack, {'ok': true}).toJson()));
            break;
          case RemoteMessageType.key:
            final key = (msg.payload['key'] as String?) ?? '';
            onKey?.call(key);
            socket.add(jsonEncode(
                RemoteMessage(RemoteMessageType.ack, {'ok': true}).toJson()));
            break;
          default:
            socket.add(jsonEncode(RemoteMessage(
                RemoteMessageType.error, {'message': 'unsupported'}).toJson()));
        }
      } catch (e) {
        if (kDebugMode) {
          print('RemoteServer parse error: $e');
        }
      }
    });
  }

  Future<void> stop() async {
    await _broadcast?.stop();
    _broadcast = null;

    await _server?.close(force: true);
    _server = null;
  }
}
