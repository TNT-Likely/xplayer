import 'dart:async';
import 'dart:convert';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

import '../services/remote/remote_protocol.dart';
import '../services/remote/remote_server.dart';
import 'package:xplayer/shared/logger.dart';

class RemoteProvider with ChangeNotifier {
  void _log(String message) {
    AppLogger.log('[Remote] $message');
  }

  // TV-side server
  RemoteServer? _server;
  bool get isServerRunning => _server?.isRunning ?? false;

  Future<void> startServer({String serviceName = 'XPlayer TV'}) async {
    if (_server != null && _server!.isRunning) return;
    _server = RemoteServer(
      serviceName: serviceName,
      onText: (text) async {
        final inserted = _replaceTextInFocused(text);
        _lastReceivedText = text;
        if (!inserted) {
          await Clipboard.setData(ClipboardData(text: text));
        }
        notifyListeners();
      },
      onKey: (key) {
        _handleRemoteKey(key);
      },
    );
    await _server!.start();
    _log('Server started on port ${_server!.port}');
    notifyListeners();
  }

  Future<void> stopServer() async {
    await _server?.stop();
    _server = null;
    notifyListeners();
  }

  String _lastReceivedText = '';
  String get lastReceivedText => _lastReceivedText;

  // Phone-side discovery
  BonsoirDiscovery? _discovery;
  final List<RemoteDeviceInfo> _devices = [];
  List<RemoteDeviceInfo> get devices => List.unmodifiable(_devices);
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySub;

  Future<void> startDiscovery() async {
    // Request required permissions on Android before discovery.
    if (Platform.isAndroid) {
      final req = <Permission>[];
      // Nearby Wi-Fi (Android 13+)
      req.add(Permission.nearbyWifiDevices);
      // Location often needed by NSD on some devices/ROMs
      req.add(Permission.locationWhenInUse);
      final statuses = await req.request();
      _log(
          'Android permissions: nearbyWifiDevices=${statuses[Permission.nearbyWifiDevices]?.name}, location=${statuses[Permission.locationWhenInUse]?.name}');
    }
    await stopDiscovery();
    _devices.clear();
    _discovery = BonsoirDiscovery(type: '_xplayer._tcp');
    _log('Discovery created for _xplayer._tcp');
    await _discovery!.ready;
    _log('Discovery ready, starting listen');
    _discoverySub = _discovery!.eventStream!.listen((event) async {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        // Explicitly resolve to get IP addresses on all platforms
        final svc = event.service;
        if (svc != null) {
          _log('Service found: ${svc.name}:${svc.port}');
          try {
            await svc.resolve(_discovery!.serviceResolver);
            _log('Resolve requested for ${svc.name}');
          } catch (_) {}
        }
      } else if (event.type ==
          BonsoirDiscoveryEventType.discoveryServiceResolved) {
        final s = event.service;
        if (s == null) return;
        final json = s.toJson();
        _log(
            'Service resolved: ${s.name} -> addresses=${json['addresses'] ?? json['address']} port=${s.port}');
        String? host;
        if (json['addresses'] is List &&
            (json['addresses'] as List).isNotEmpty) {
          // Prefer IPv4 if available
          final addrs = (json['addresses'] as List).cast<String>();
          host = addrs.firstWhere(
            (a) => a.contains('.'),
            orElse: () => addrs.first,
          );
        } else if (json['address'] is String) {
          host = json['address'] as String?;
        } else if (s.attributes['host'] is String &&
            (s.attributes['host'] as String).isNotEmpty) {
          host = s.attributes['host'] as String;
        }
        if (host == null) return;
        final info = RemoteDeviceInfo(
          id: s.attributes.containsKey('id')
              ? s.attributes['id']!.toString()
              : '${s.name}@$host:${s.port}',
          name: s.name,
          host: host,
          port: s.port,
        );
        final exists = _devices.any((d) => d.id == info.id);
        if (!exists) {
          _devices.add(info);
          _log(
              'Device added: ${info.name} ${info.host}:${info.port} (total=${_devices.length})');
          notifyListeners();
        }
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        final s = event.service;
        if (s == null) return;
        _devices.removeWhere((d) => d.name == s.name);
        _log('Service lost: ${s.name}');
        notifyListeners();
      }
    });
    await _discovery!.start();
    _log('Discovery started');
  }

  Future<void> stopDiscovery() async {
    await _discoverySub?.cancel();
    _discoverySub = null;
    if (_discovery != null) {
      await _discovery!.stop();
      _log('Discovery stopped');
    }
    _discovery = null;
  }

  // Phone-side client connection
  WebSocketChannel? _channel;
  bool get isConnected => _channel != null;
  RemoteDeviceInfo? _current;
  RemoteDeviceInfo? get current => _current;

  Future<void> connect(RemoteDeviceInfo device) async {
    await disconnect();
    final h = device.host;
    final needsBracket = h.contains(':') && !h.startsWith('[');
    final hostPart = needsBracket ? '[$h]' : h;
    final uri = Uri.parse('ws://$hostPart:${device.port}/');
    _channel = WebSocketChannel.connect(uri);
    _current = device;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    _current = null;
    notifyListeners();
  }

  // 发送文本（会用于首次发送；之后若启用“实时同步”，则由控制器监听触发）
  Future<bool> sendText(String text) async {
    if (_channel == null) return false;
    final msg = RemoteMessage(RemoteMessageType.text, {'text': text});
    _channel!.sink.add(jsonEncode(msg.toJson()));
    return true;
  }

  Future<bool> sendKey(String key) async {
    if (_channel == null) return false;
    final msg = RemoteMessage(RemoteMessageType.key, {'key': key});
    _channel!.sink.add(jsonEncode(msg.toJson()));
    return true;
  }

  // ===== TV side helpers =====
  bool _replaceTextInFocused(String text) {
    try {
      final focus = FocusManager.instance.primaryFocus;
      final ctx = focus?.context;
      if (ctx == null) return false;
      final editable = ctx.findAncestorStateOfType<EditableTextState>();
      if (editable == null) return false;
      final value = editable.textEditingValue;
      // 全量替换为最新文本
      final newText = text;
      final updated = value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
        composing: TextRange.empty,
      );
      editable.userUpdateTextEditingValue(
          updated, SelectionChangedCause.keyboard);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _handleRemoteKey(String key) {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context;
    if (ctx == null) return;
    switch (key.toLowerCase()) {
      case 'up':
        Actions.maybeInvoke(
            ctx, const DirectionalFocusIntent(TraversalDirection.up));
        break;
      case 'down':
        Actions.maybeInvoke(
            ctx, const DirectionalFocusIntent(TraversalDirection.down));
        break;
      case 'left':
        Actions.maybeInvoke(
            ctx, const DirectionalFocusIntent(TraversalDirection.left));
        break;
      case 'right':
        Actions.maybeInvoke(
            ctx, const DirectionalFocusIntent(TraversalDirection.right));
        break;
      case 'enter':
      case 'ok':
        Actions.maybeInvoke(ctx, const ActivateIntent());
        break;
      case 'backspace':
      case 'delete':
        _deleteInFocused();
        break;
    }
  }

  void _deleteInFocused() {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context;
    if (ctx == null) return;
    final editable = ctx.findAncestorStateOfType<EditableTextState>();
    if (editable == null) return;
    final value = editable.textEditingValue;
    TextSelection sel = value.selection;
    if (!sel.isValid) {
      sel = TextSelection.collapsed(offset: value.text.length);
    }
    int start = sel.start;
    int end = sel.end;
    if (start == end && start > 0) {
      start = start - 1;
    }
    if (start < 0 ||
        end < 0 ||
        start > value.text.length ||
        end > value.text.length) {
      return;
    }
    final newText = value.text.replaceRange(start, end, '');
    final updated = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start),
      composing: TextRange.empty,
    );
    editable.userUpdateTextEditingValue(
        updated, SelectionChangedCause.keyboard);
  }
}
