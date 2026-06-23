/// iptv-org 预置直播源（运行时拉取，不打包静态快照）。
///
/// 来源：https://github.com/iptv-org/iptv （Unlicense，仅聚合公开流）。
/// 仅内置上游公开 m3u 的 URL；App 在运行时拉取，便于跟随上游下架，降低合规风险。
class IptvPreset {
  /// AppLocalizations 中的字段名（用于本地化显示）；取不到时用 [fallbackName]。
  final String nameKey;

  /// 兜底名称（未配 i18n 或本地化不可用时使用，也作为新建播放列表的名字）。
  final String fallbackName;

  /// 上游 m3u 地址。
  final String url;

  /// 可选的 EPG 地址（多数 iptv-org 列表会在 m3u 头部带 x-tvg-url，可留空）。
  final String? epgUrl;

  const IptvPreset({
    required this.nameKey,
    required this.fallbackName,
    required this.url,
    this.epgUrl,
  });
}

const String _base = 'https://iptv-org.github.io/iptv';

/// 默认预置源：iptv-org 中国（首启自动加载）。
const IptvPreset kDefaultPreset = IptvPreset(
  nameKey: 'presetChina',
  fallbackName: '中国 China',
  url: '$_base/countries/cn.m3u',
);

/// 「推荐源」里可一键添加的预置（国家 + 全部 + 分类，均已确认上游存在）。
const List<IptvPreset> kIptvPresets = [
  kDefaultPreset,
  IptvPreset(nameKey: 'presetAll', fallbackName: '全部 All', url: '$_base/index.m3u'),
  IptvPreset(nameKey: 'presetHK', fallbackName: '香港 Hong Kong', url: '$_base/countries/hk.m3u'),
  IptvPreset(nameKey: 'presetTW', fallbackName: '台湾 Taiwan', url: '$_base/countries/tw.m3u'),
  IptvPreset(nameKey: 'presetSG', fallbackName: '新加坡 Singapore', url: '$_base/countries/sg.m3u'),
  IptvPreset(nameKey: 'presetUS', fallbackName: '美国 United States', url: '$_base/countries/us.m3u'),
  IptvPreset(nameKey: 'presetUK', fallbackName: '英国 United Kingdom', url: '$_base/countries/uk.m3u'),
  IptvPreset(nameKey: 'presetJP', fallbackName: '日本 Japan', url: '$_base/countries/jp.m3u'),
  IptvPreset(nameKey: 'presetKR', fallbackName: '韩国 Korea', url: '$_base/countries/kr.m3u'),
  IptvPreset(nameKey: 'presetSports', fallbackName: '体育 Sports', url: '$_base/categories/sports.m3u'),
  IptvPreset(nameKey: 'presetNews', fallbackName: '新闻 News', url: '$_base/categories/news.m3u'),
  IptvPreset(nameKey: 'presetMovies', fallbackName: '电影 Movies', url: '$_base/categories/movies.m3u'),
];
