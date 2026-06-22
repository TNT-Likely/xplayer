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

/// 默认预置源：iptv-org 中国（首启自动加载）。
const IptvPreset kDefaultPreset = IptvPreset(
  nameKey: 'presetChina',
  fallbackName: '中国 · iptv-org',
  url: 'https://iptv-org.github.io/iptv/countries/cn.m3u',
);

/// 可在「推荐源」里一键添加的预置列表。
const List<IptvPreset> kIptvPresets = [
  kDefaultPreset,
  IptvPreset(
    nameKey: 'presetSports',
    fallbackName: '体育 · iptv-org',
    url: 'https://iptv-org.github.io/iptv/categories/sports.m3u',
  ),
  IptvPreset(
    nameKey: 'presetNews',
    fallbackName: '新闻 · iptv-org',
    url: 'https://iptv-org.github.io/iptv/categories/news.m3u',
  ),
  IptvPreset(
    nameKey: 'presetAll',
    fallbackName: '全部 · iptv-org',
    url: 'https://iptv-org.github.io/iptv/index.m3u',
  ),
];
