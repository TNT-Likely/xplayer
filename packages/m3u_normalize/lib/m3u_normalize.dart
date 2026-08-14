/// M3U / IPTV 播放列表的字段清洗。
///
/// 解决两个几乎所有 IPTV 客户端都会遇到的问题：
///
/// **一、频道名是机器标识。** 很多播放列表把 `tvg-name` 直接设成 tvg-id，
/// 界面上于是出现 `1KZNTV.ZA@SD`、`2MMONDE.MA@PLUS1`，全大写还会被截断成
/// `1PLUS1INTERNATIONA…`。[normalizeChannel] 按「像不像人话」给候选字段
/// 打分再清洗，并把清晰度与地区码从名字里剥出来。
///
/// **二、分组是分号粘连的。** `group-title` 里的
/// `Entertainment;Family;General` 被当成一个组名，于是分组列表里出现大量
/// 只含一个频道的怪组。[splitGroupTitle] 拆成多标签。
///
/// 纯 Dart，无 Flutter 依赖，可用于任何 IPTV 客户端或播放列表处理工具。
///
/// ```dart
/// final d = normalizeChannel(
///   tvgName: '1PLUS1INTERNATIONAL.UA@SD',
///   title: '1+1 International',
/// );
/// d.name;    // '1+1 International'
/// d.quality; // 'SD'
/// d.region;  // 'UA'
///
/// splitGroupTitle('Entertainment;Family;General');
/// // ['Entertainment', 'Family', 'General']
/// ```
library m3u_normalize;

export 'src/channel_normalize.dart';
