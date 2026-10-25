import 'dart:async';
import 'dart:convert';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform, WebSocket;
import 'package:xplayer/shared/navigation.dart';
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
  String? get serverAddress => _server?.address;

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
        _notify();
      },
      onKey: (key) {
        _handleRemoteKey(key);
      },
    );
    try {
      await _server!.start();
      _log('Server started on port ${_server!.port}');
    } finally {
      _notify();
    }
  }

  Future<void> stopServer() async {
    await _server?.stop();
    _server = null;
    _notify();
  }

  String _lastReceivedText = '';
  String get lastReceivedText => _lastReceivedText;

  bool _disposed = false;
  bool _discovering = false;
  bool _permissionDenied = false;
  bool _connecting = false;
  String? _connectionError;
  Timer? _discoveryTimer;
  StreamSubscription? _socketSub;
  int _connectionAttempt = 0;
  VoidCallback? playPauseHandler;
  bool get isDiscovering => _discovering;
  bool get permissionDenied => _permissionDenied;
  bool get isConnecting => _connecting;
  String? get connectionError => _connectionError;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> startDiscovery() async {
    if (_discovering) return;
    _discovering = true;
    _permissionDenied = false;
    _connectionError = null;
    _notify();
    try {
      await _startDiscovery();
      if (_permissionDenied) {
        _discovering = false;
        _notify();
        return;
      }
      _discoveryTimer = Timer(const Duration(seconds: 8), () {
        _discovering = false;
        _notify();
      });
    } catch (_) {
      _discovering = false;
      _connectionError = '无法搜索设备，请检查局域网权限与网络。';
      _notify();
    }
  }

  Future<void> stopDiscovery() async {
    _discoveryTimer?.cancel();
    _discovering = false;
    await _stopDiscovery();
  }

  // Phone-side discovery
  BonsoirDiscovery? _discovery;
  final List<RemoteDeviceInfo> _devices = [];
  List<RemoteDeviceInfo> get devices => List.unmodifiable(_devices);
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySub;

  Future<void> _startDiscovery() async {
    // Request required permissions on Android before discovery.
    if (Platform.isAndroid) {
      final req = <Permission>[];
      // Nearby Wi-Fi (Android 13+)
      req.add(Permission.nearbyWifiDevices);
      // Location often needed by NSD on some devices/ROMs
      req.add(Permission.locationWhenInUse);
      final statuses = await req.request();
      if (statuses.values.every((status) => !status.isGranted)) {
        _permissionDenied = true;
        return;
      }
      _log(
        'Android permissions: nearbyWifiDevices=${statuses[Permission.nearbyWifiDevices]?.name}, location=${statuses[Permission.locationWhenInUse]?.name}',
      );
    }
    await _stopDiscovery();
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
          'Service resolved: ${s.name} -> addresses=${json['addresses'] ?? json['address']} port=${s.port}',
        );
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
            'Device added: ${info.name} ${info.host}:${info.port} (total=${_devices.length})',
          );
          _notify();
        }
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        final s = event.service;
        if (s == null) return;
        _devices.removeWhere((d) => d.name == s.name);
        _log('Service lost: ${s.name}');
        _notify();
      }
    });
    await _discovery!.start();
    _log('Discovery started');
  }

  Future<void> _stopDiscovery() async {
    await _discoverySub?.cancel();
    _discoverySub = null;
    if (_discovery != null) {
      await _discovery!.stop();
      _log('Discovery stopped');
    }
    _discovery = null;
  }

  // Phone-side client connection
  WebSocket? _channel;
  bool get isConnected => _channel != null;
  RemoteDeviceInfo? _current;
  RemoteDeviceInfo? get current => _current;

  Future<void> connect(RemoteDeviceInfo device) async {
    await disconnect();
    final attempt = ++_connectionAttempt;
    _connecting = true;
    _connectionError = null;
    _notify();
    final host = device.host.contains(':') && !device.host.startsWith('[')
        ? '[${device.host}]'
        : device.host;
    try {
      final socket = await WebSocket.connect(
        'ws://$host:${device.port}/',
      ).timeout(const Duration(seconds: 8));
      if (_disposed || attempt != _connectionAttempt) {
        await socket.close();
        return;
      }
      _channel = socket;
      _current = device;
      void lost() {
        if (_channel != socket) return;
        _channel = null;
        _current = null;
        _connectionError = '与电视的连接已断开。';
        _notify();
      }

      _socketSub = socket.listen(
        (_) {},
        onDone: lost,
        onError: (_) => lost(),
        cancelOnError: true,
      );
    } catch (_) {
      if (attempt == _connectionAttempt)
        _connectionError = '连接失败，请确认电视仍在同一网络中。';
    } finally {
      if (attempt == _connectionAttempt) {
        _connecting = false;
        _notify();
      }
    }
  }

  Future<void> disconnect() async {
    _connectionAttempt++;
    _connecting = false;
    final socket = _channel;
    _channel = null;
    _current = null;
    await _socketSub?.cancel();
    _socketSub = null;
    try {
      await socket?.close().timeout(const Duration(seconds: 2));
    } catch (_) {}
    _notify();
  }

  // 发送文本（会用于首次发送；之后若启用“实时同步”，则由控制器监听触发）
  Future<bool> sendText(String text) async {
    if (_channel == null) return false;
    final msg = RemoteMessage(RemoteMessageType.text, {'text': text});
    try {
      _channel!.add(jsonEncode(msg.toJson()));
      return true;
    } catch (_) {
      await disconnect();
      _connectionError = '连接已断开，请重新连接。';
      _notify();
      return false;
    }
  }

  Future<bool> sendKey(String key) async {
    if (_channel == null) return false;
    final msg = RemoteMessage(RemoteMessageType.key, {'key': key});
    try {
      _channel!.add(jsonEncode(msg.toJson()));
      return true;
    } catch (_) {
      await disconnect();
      _connectionError = '连接已断开，请重新连接。';
      _notify();
      return false;
    }
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
        updated,
        SelectionChangedCause.keyboard,
      );
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
          ctx,
          const DirectionalFocusIntent(TraversalDirection.up),
        );
        break;
      case 'down':
        Actions.maybeInvoke(
          ctx,
          const DirectionalFocusIntent(TraversalDirection.down),
        );
        break;
      case 'left':
        Actions.maybeInvoke(
          ctx,
          const DirectionalFocusIntent(TraversalDirection.left),
        );
        break;
      case 'right':
        Actions.maybeInvoke(
          ctx,
          const DirectionalFocusIntent(TraversalDirection.right),
        );
        break;
      case 'enter':
      case 'ok':
        Actions.maybeInvoke(ctx, const ActivateIntent());
        break;
      case 'back':
        AppNav.key.currentState?.maybePop();
        break;
      case 'home':
        AppNav.key.currentState?.popUntil((route) => route.isFirst);
        break;
      case 'playpause':
        playPauseHandler?.call();
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
      updated,
      SelectionChangedCause.keyboard,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _discoveryTimer?.cancel();
    _discoverySub?.cancel();
    _discovery?.stop();
    _socketSub?.cancel();
    _channel?.close();
    _server?.stop();
    super.dispose();
  }
}
