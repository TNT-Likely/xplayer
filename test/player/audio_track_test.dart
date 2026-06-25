import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/services/player/x_player_backend.dart';

void main() {
  test('AudioTrack holds fields', () {
    const t = AudioTrack(
        id: '0:1',
        label: '国语',
        language: 'zh',
        codec: 'ac3',
        channels: 2,
        isSelected: true);
    expect(t.id, '0:1');
    expect(t.isSelected, true);
    expect(t.language, 'zh');
  });

  test('displayName falls back label>language>codec>id', () {
    expect(const AudioTrack(id: 'a', label: '粤语', isSelected: false).displayName,
        '粤语');
    expect(
        const AudioTrack(id: 'a', language: 'en', isSelected: false).displayName,
        'en');
    expect(const AudioTrack(id: 'a', codec: 'aac', isSelected: false).displayName,
        'aac');
    expect(const AudioTrack(id: 'track-7', isSelected: false).displayName,
        'track-7');
  });
}
