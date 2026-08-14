/// 音频编码可解性判断（启发式）。
///
/// 背景：ExoPlayer 不内置 FFmpeg 扩展，遇到 AC-3 / E-AC-3 / DTS / MP2 这类
/// 编码时会**静默丢掉音轨**——用户侧的表现就是「这个台没声音」，界面上却
/// 毫无提示，于是变成一类查不出根因的报障。
///
/// 这里做的是把这件事**说出来**：在音轨列表里把这些编码标出来并说明原因，
/// 而不是让用户对着一个选了也没声音的选项反复试。
///
/// ⚠️ 这是启发式，不是确定性判断：
/// - 部分 Android 设备带硬件 AC-3 解码，实际能出声
/// - iOS/macOS 的 AVPlayer 对 AC-3 的支持与 Android 不同
///
/// 因此文案用「可能无法解码」，且**不禁用选项**——只提示，仍允许用户去试。
library;

/// 常见的、ExoPlayer 无 FFmpeg 扩展时解不了的编码族。
///
/// 匹配用「包含」而非相等：不同后端给出的 codec 字符串格式不一，
/// 可能是 `ac3`、`audio/ac3`、`AC-3`、`mp4a.a5` 等。
const _riskyCodecFragments = <String>[
  'ac3', // AC-3 / Dolby Digital，也覆盖 eac3 / ec-3
  'ac-3',
  'ec-3',
  'dts', // DTS 全系
  'mp2', // MPEG-1/2 Audio Layer II，欧洲 DVB 直播源里很常见
  'mpeg2audio',
  'truehd',
];

/// 该编码在当前主流后端上是否**可能**无法解码。
///
/// [codec] 为 null 或空时返回 false —— 不知道就不吓唬用户。
bool isLikelyUnsupportedAudioCodec(String? codec) {
  if (codec == null) return false;
  final c = codec.toLowerCase().replaceAll(' ', '');
  if (c.isEmpty) return false;
  return _riskyCodecFragments.any(c.contains);
}
