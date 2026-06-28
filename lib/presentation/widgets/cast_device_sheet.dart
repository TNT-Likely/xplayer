import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:xplayer/providers/cast_provider.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer/localization/app_localizations.dart';

/// 投屏设备选择面板(DLNA)。打开即扫描;选中设备把 [url] 投出去。
/// 已在投屏中则显示当前设备与控制(暂停/播放/停止)。
class CastDeviceSheet extends StatefulWidget {
  final String url;
  final String title;
  final VoidCallback? onCasted; // 投出成功(供调用方暂停本地播放)

  const CastDeviceSheet({
    super.key,
    required this.url,
    required this.title,
    this.onCasted,
  });

  static Future<void> show(BuildContext context,
      {required String url,
      required String title,
      VoidCallback? onCasted}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTokens.surfacePanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) =>
          CastDeviceSheet(url: url, title: title, onCasted: onCasted),
    );
  }

  @override
  State<CastDeviceSheet> createState() => _CastDeviceSheetState();
}

class _CastDeviceSheetState extends State<CastDeviceSheet> {
  @override
  void initState() {
    super.initState();
    // 打开即扫描一次
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CastProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Consumer<CastProvider>(
      builder: (context, cast, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.live_tv, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l.castToTv,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                    if (cast.state == CastState.discovering)
                      const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        onPressed: () => cast.refresh(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (cast.isCasting) _castingView(cast) else _deviceList(cast),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _castingView(CastProvider cast) {
    final l = AppLocalizations.of(context)!;
    final playing = cast.transport == 'PLAYING';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.castingTo(cast.current?.friendlyName ?? ''),
            style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        Row(
          children: [
            XActionChip(
              icon: playing ? Icons.pause : Icons.play_arrow,
              label: playing ? l.pause : l.play,
              onTap: () => playing ? cast.pause() : cast.play(),
            ),
            const SizedBox(width: 12),
            XActionChip(
              icon: Icons.stop,
              label: l.stopCast,
              onTap: () async {
                await cast.stopCast();
                if (mounted) Navigator.of(context).maybePop();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _deviceList(CastProvider cast) {
    final l = AppLocalizations.of(context)!;
    if (cast.state == CastState.discovering && cast.devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
            child: Text(l.castSearching,
                style: const TextStyle(color: Colors.white54))),
      );
    }
    if (cast.devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(l.castNoDevice,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(l.castNoDeviceHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: cast.devices.length,
        itemBuilder: (_, i) {
          final d = cast.devices[i];
          return ListTile(
            leading: const Icon(Icons.tv, color: Colors.white70),
            title: Text(d.friendlyName,
                style: const TextStyle(color: Colors.white)),
            subtitle: const Text('DLNA',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            onTap: () async {
              final ok = await cast.castTo(d,
                  url: widget.url, title: widget.title);
              if (!mounted) return;
              if (ok) {
                widget.onCasted?.call();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l.castStarted(d.friendlyName))));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.castFailed)));
              }
            },
          );
        },
      ),
    );
  }
}

/// 简易动作按钮(图标 + 文字)。
class XActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const XActionChip(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
