import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/services/sync/config_bundle.dart';
import 'package:xplayer/services/sync/lan_sync_discovery.dart';
import 'package:xplayer/presentation/screens/lan_sync_preview_screen.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/utils/toast.dart';

/// 接收端:发现局域网内「开放同步」的设备 → 选一台 → 拉取配置 → 预览。
class LanSyncScreen extends StatefulWidget {
  const LanSyncScreen({super.key});

  @override
  State<LanSyncScreen> createState() => _LanSyncScreenState();
}

class _LanSyncScreenState extends State<LanSyncScreen> {
  final LanSyncDiscovery _discovery = LanSyncDiscovery();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _discovery.start();
  }

  @override
  void dispose() {
    _discovery.stop();
    super.dispose();
  }

  Future<void> _pull(SyncPeer peer) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8)
        ..badCertificateCallback = (_, __, ___) => true;
      final req = await client
          .getUrl(Uri.parse(peer.configUrl))
          .timeout(const Duration(seconds: 8));
      final resp = await req.close().timeout(const Duration(seconds: 8));
      final body = await resp.transform(utf8.decoder).join();
      final bundle = ConfigBundle.fromJson(
          Map<String, dynamic>.from(jsonDecode(body)));
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => LanSyncPreviewScreen(bundle: bundle)));
    } catch (e) {
      if (mounted) showToast('${l.syncFailed}: $e');
    } finally {
      client?.close(force: true);
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      appBar: AppBar(
        title: Text(l.lanSync, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ValueListenableBuilder<List<SyncPeer>>(
        valueListenable: _discovery.peers,
        builder: (_, peers, __) {
          if (peers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.4)),
                  const SizedBox(height: 16),
                  Text(l.lanSyncSearching,
                      style: const TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }
          return Stack(
            children: [
              ListView.builder(
                itemCount: peers.length,
                itemBuilder: (_, i) {
                  final p = peers[i];
                  return XBaseButton(
                    onPressed: _loading ? null : () => _pull(p),
                    child: (focused) => ListTile(
                      leading:
                          const Icon(Icons.devices, color: Colors.white),
                      title: Text(p.name,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${p.host}:${p.port}',
                          style: const TextStyle(color: Colors.white54)),
                    ),
                  );
                },
              ),
              if (_loading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x88000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
