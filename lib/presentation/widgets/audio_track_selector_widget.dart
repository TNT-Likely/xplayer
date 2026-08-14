import 'package:flutter/widgets.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/services/player/x_player_backend.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer/utils/audio_codec_support.dart';

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
            // 解不了的编码不隐藏,而是标出来并说明原因。
            // 「这个台没声音」的报障里,有一批根源就是选中了设备解不了的音轨
            // 却毫无提示 —— ExoPlayer 不带 FFmpeg 时会静默丢音轨。
            final risky = isLikelyUnsupportedAudioCodec(t.codec);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  XTextButton(
                    text: label,
                    size: XTextButtonSize.large,
                    width: 200,
                    autofocus: t.isSelected, // 打开即聚焦当前音轨
                    textStyle: const TextStyle(fontSize: 13),
                    type: t.isSelected
                        ? XTextButtonType.primary
                        : XTextButtonType.defaultType,
                    // 仍然可选:这是启发式判断,部分设备带硬件解码,
                    // 禁用会误伤,提示即可。
                    onPressed: () {
                      if (!t.isSelected) onSelect(t.id);
                    },
                  ),
                  if (risky)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: SizedBox(
                        width: 200,
                        child: Text(
                          AppLocalizations.of(context)!
                              .audioCodecMaybeUnsupported,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.3,
                            color: AppTokens.sourceSlow,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
