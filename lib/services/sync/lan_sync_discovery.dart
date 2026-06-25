import 'dart:async';
import 'dart:io' show Platform;
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xplayer/services/sync/lan_sync_server.dart';
import 'package:xplayer/services/sync/sync_device.dart';

class SyncPeer {
  final String name;
  final String host;
  final int port;
  const SyncPeer({required this.name, required this.host, required this.port});
  String get configUrl => 'http://$host:$port/config';
}

/// 接收端:bonsoir 发现 _xplayersync._tcp,解析为 SyncPeer 列表。
class LanSyncDiscovery {
  BonsoirDiscovery? _discovery;
  StreamSubscription? _sub;
  String _ownName = ''; // 本机服务名,用于过滤掉自己
  final ValueNotifier<List<SyncPeer>> peers = ValueNotifier([]);

  Future<void> start() async {
    _ownName = await syncDeviceName();
    // Android NSD/mDNS 发现需要这些权限(否则搜不到设备),与遥控发现一致。
    if (Platform.isAndroid) {
      try {
        await [
          Permission.nearbyWifiDevices,
          Permission.locationWhenInUse,
        ].request();
      } catch (_) {}
    }
    _discovery = BonsoirDiscovery(type: LanSyncServer.serviceType);
    await _discovery!.ready;
    _sub = _discovery!.eventStream!.listen((event) async {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        final f = event.service;
        // 只解析同步服务,且跳过本机自己
        if (f == null ||
            f.type != LanSyncServer.serviceType ||
            f.name == _ownName) {
          return;
        }
        try {
          await f.resolve(_discovery!.serviceResolver);
        } catch (_) {}
      } else if (event.type ==
          BonsoirDiscoveryEventType.discoveryServiceResolved) {
        final s = event.service;
        if (s == null) return;
        // 过滤非同步服务 + 本机自己
        if (s.type != LanSyncServer.serviceType || s.name == _ownName) return;
        final json = s.toJson();
        // bonsoir 不同平台键名不一致:Android 用 'host'/'port',iOS 用 'service.host'/'service.port'。
        String? str(String k) {
          final v = json[k] ?? json['service.$k'];
          return v is String && v.isNotEmpty ? v : null;
        }
        String? host;
        final addrs = (json['addresses'] ?? json['service.addresses']);
        if (addrs is List && addrs.isNotEmpty) {
          final list = addrs.cast<String>();
          host = list.firstWhere((a) => a.contains('.'), orElse: () => list.first);
        } else {
          host = str('address') ??
              str('host') ??
              (s.attributes['host'] is String &&
                      (s.attributes['host'] as String).isNotEmpty
                  ? s.attributes['host'] as String
                  : null);
        }
        final port = (json['port'] as num?)?.toInt() ??
            (json['service.port'] as num?)?.toInt() ??
            s.port;
        if (host == null || host.isEmpty || port <= 0) {
          debugPrint('[lansync] resolved but skipped: host=$host port=$port json=$json');
          return;
        }
        // .local 主机名常带尾点,去掉以便 HttpClient 解析。
        if (host.endsWith('.')) host = host.substring(0, host.length - 1);
        final peer = SyncPeer(name: s.name, host: host, port: port);
        final list = [...peers.value]
          ..removeWhere((p) => p.host == peer.host && p.port == peer.port);
        list.add(peer);
        peers.value = list;
        debugPrint('[lansync] peer listed: ${peer.name} ${peer.host}:${peer.port} (total ${list.length})');
      }
      // 不处理 LOST:同步会话很短,bonsoir 的 TXT 重试会产生 lost→found 抖动,
      // 按名移除会把刚解析到的设备清掉;保留已发现项,失效项用户点了再报错即可。
    });
    await _discovery!.start();
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _discovery?.stop();
    } catch (_) {}
    _discovery = null;
    peers.value = [];
  }
}
