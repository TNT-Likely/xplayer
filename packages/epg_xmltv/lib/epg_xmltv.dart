/// XMLTV 电子节目单（EPG）解析与查找。
///
/// **纯 Dart，无 Flutter 依赖。**
///
/// 覆盖 IPTV 客户端需要 EPG 做的全部事情：
/// - 解析 XMLTV 文档为 [Programme] 列表
/// - 按频道检索节目
/// - 求「当前正在播」与「下一个」
/// - 解析 XMLTV 那套带时区偏移的时间格式（`20260814190000 +0800`）
///
/// ```dart
/// final programmes = parseProgrammes(xmlString);
/// final (index, current, next) =
///     PlaylistUtil.findCurrentAndNext(programmes, 'CCTV1');
/// ```
///
/// ⚠️ [PlaylistUtil] 这个类名是历史遗留 —— 它做的全是 EPG 节目查找，
/// 与播放列表无关。抽包时保留原名以免一次性改动过大，
/// 后续可安全重命名为 `EpgLookup`。
library epg_xmltv;

export 'src/playlist_util.dart';
export 'src/programme_model.dart';
