import 'package:flutter/material.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/services/sync/lan_sync_server.dart';
import 'package:xplayer/shared/components/x_text_button.dart';

/// 源端「开放同步」:开启后限时广播 + 提供配置;显示状态与倒计时。
class LanSyncOpenScreen extends StatefulWidget {
  const LanSyncOpenScreen({super.key});

  @override
  State<LanSyncOpenScreen> createState() => _LanSyncOpenScreenState();
}

class _LanSyncOpenScreenState extends State<LanSyncOpenScreen> {
  final LanSyncServer _server = LanSyncServer();

  @override
  void initState() {
    super.initState();
    _server.start();
  }

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      appBar: AppBar(
        title: Text(l.lanSyncOpen,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_tethering,
                  color: Colors.greenAccent, size: 64),
              const SizedBox(height: 16),
              Text(l.lanSyncOpenHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 24),
              ValueListenableBuilder<int>(
                valueListenable: _server.remainingSec,
                builder: (_, s, __) => Text(
                  l.lanSyncRemaining(s),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              XTextButton(
                text: l.lanSyncStop,
                type: XTextButtonType.primary,
                onPressed: () {
                  _server.stop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
