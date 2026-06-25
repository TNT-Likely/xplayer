import 'package:flutter/widgets.dart';
import 'package:xplayer/services/player/x_player_backend.dart';
import 'package:xplayer/shared/components/x_text_button.dart';

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
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: tracks.map((t) {
            final extra = [
              if (t.codec != null) t.codec!,
              if (t.channels != null) '${t.channels}ch',
            ].join(' ');
            final label = extra.isEmpty ? t.displayName : '${t.displayName}  ·  $extra';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: XTextButton(
                text: label,
                size: XTextButtonSize.large,
                width: 200,
                textStyle: const TextStyle(fontSize: 13),
                type: t.isSelected
                    ? XTextButtonType.primary
                    : XTextButtonType.defaultType,
                onPressed: () {
                  if (!t.isSelected) onSelect(t.id);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
