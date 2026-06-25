import 'dart:async';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import 'package:xplayer/services/sync/lan_sync_server.dart';

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
  final ValueNotifier<List<SyncPeer>> peers = ValueNotifier([]);

  Future<void> start() async {
    _discovery = BonsoirDiscovery(type: LanSyncServer.serviceType);
    await _discovery!.ready;
    _sub = _discovery!.eventStream!.listen((event) async {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        try {
          await event.service?.resolve(_discovery!.serviceResolver);
        } catch (_) {}
      } else if (event.type ==
          BonsoirDiscoveryEventType.discoveryServiceResolved) {
        final s = event.service;
        if (s == null) return;
        final json = s.toJson();
        String? host;
        if (json['addresses'] is List &&
            (json['addresses'] as List).isNotEmpty) {
          final addrs = (json['addresses'] as List).cast<String>();
          host = addrs.firstWhere((a) => a.contains('.'),
              orElse: () => addrs.first);
        } else if (json['address'] is String) {
          host = json['address'] as String?;
        }
        if (host == null) return;
        final peer = SyncPeer(name: s.name, host: host, port: s.port);
        final list = [...peers.value]
          ..removeWhere((p) => p.host == peer.host && p.port == peer.port);
        list.add(peer);
        peers.value = list;
      } else if (event.type ==
          BonsoirDiscoveryEventType.discoveryServiceLost) {
        final s = event.service;
        if (s == null) return;
        peers.value = peers.value.where((p) => p.name != s.name).toList();
      }
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
