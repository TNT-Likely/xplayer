import 'package:flutter/widgets.dart';
import 'package:xplayer/services/player/x_player_backend.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

/// 音轨选择列表(侧边浮层),仿画质选择。
class AudioTrackSelectorWidget extends StatelessWidget {
  final List<AudioTrack> tracks;
  final Future<void> Function(String id) onSelect;

  const AudioTrackSelectorWidget({
    super.key,
    required this.tracks,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: tracks.map((t) {
          final extra = [
            if (t.codec != null) t.codec!,
            if (t.channels != null) '${t.channels}ch',
          ].join(' ');
          final label = extra.isEmpty
              ? t.displayName
              : '${t.displayName}  ·  $extra';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: XpButton(
                label: label,
                autofocus: t.isSelected, // 打开即聚焦当前音轨
                variant: t.isSelected
                    ? XpButtonVariant.primary
                    : XpButtonVariant.secondary,
                onPressed: () {
                  if (!t.isSelected) onSelect(t.id);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
