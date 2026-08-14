import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/utils/audio_codec_support.dart';

void main() {
  group('isLikelyUnsupportedAudioCodec', () {
    test('AC-3 家族被识别 —— 这是「这个台没声音」报障的头号来源', () {
      for (final c in ['ac3', 'AC-3', 'audio/ac3', 'eac3', 'EC-3', 'ac-3']) {
        expect(isLikelyUnsupportedAudioCodec(c), isTrue, reason: c);
      }
    });

    test('DTS 与 TrueHD 被识别', () {
      for (final c in ['dts', 'DTS-HD', 'audio/vnd.dts', 'truehd']) {
        expect(isLikelyUnsupportedAudioCodec(c), isTrue, reason: c);
      }
    });

    test('MP2 被识别 —— 欧洲 DVB 直播源里很常见', () {
      for (final c in ['mp2', 'MP2', 'audio/mpeg2audio']) {
        expect(isLikelyUnsupportedAudioCodec(c), isTrue, reason: c);
      }
    });

    test('常规编码不误报', () {
      for (final c in ['aac', 'AAC-LC', 'audio/mp4a-latm', 'opus', 'mp3',
        'audio/mpeg', 'flac', 'vorbis']) {
        expect(isLikelyUnsupportedAudioCodec(c), isFalse, reason: c);
      }
    });

    test('未知编码不吓唬用户:null 与空串一律返回 false', () {
      expect(isLikelyUnsupportedAudioCodec(null), isFalse);
      expect(isLikelyUnsupportedAudioCodec(''), isFalse);
      expect(isLikelyUnsupportedAudioCodec('   '), isFalse);
    });

    test('大小写与空格不影响判断', () {
      expect(isLikelyUnsupportedAudioCodec('  A C 3  '), isTrue);
      expect(isLikelyUnsupportedAudioCodec('Audio / AC3'), isTrue);
    });
  });
}
