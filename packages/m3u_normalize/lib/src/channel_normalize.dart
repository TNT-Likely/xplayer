/// 频道展示信息规范化 —— 把 M3U 原始字段提炼成人类可读的展示名。
///
/// 背景:很多播放列表把 `tvg-name` 直接设成 tvg-id,于是界面上出现
/// `1KZNTV.ZA@SD`、`2MMONDE.MA@PLUS1` 这种东西,全大写还被截断成
/// `1PLUS1INTERNATIONA…`。本模块负责挑出最像人话的那个候选字段并清洗它,
/// 同时把清晰度、地区从名字里剥出来交给角标和副行。
///
/// ⚠️ **只影响展示。** [Channel.id] 是收藏与最近观看的身份键
/// (`favorites_repository` 直接把它存进数据库、`recent_util` 拿它去重),
/// 任何改动都会让存量数据失联,故本模块一律不碰 id。
library;

/// 一个频道的展示信息:名字归名字,清晰度与地区各归其位。
class ChannelDisplay {
  /// 展示名。已剥离 `@HD` 后缀与 `.CN` 地区码。
  final String name;

  /// 规范化后的清晰度标签,用于卡片角标。无法判定时为 null。
  final String? quality;

  /// 两位地区码(大写),用于副行。无法判定时为 null。
  final String? region;

  const ChannelDisplay({required this.name, this.quality, this.region});

  @override
  String toString() => 'ChannelDisplay($name, q=$quality, r=$region)';

  @override
  bool operator ==(Object other) =>
      other is ChannelDisplay &&
      other.name == name &&
      other.quality == quality &&
      other.region == region;

  @override
  int get hashCode => Object.hash(name, quality, region);
}

/// 形如 `1PLUS1INTERNATIONAL.UA@SD` / `CCTV1.CN` 的机器标识,不是人话。
final _idLike = RegExp(r'^[A-Za-z0-9+_-]+\.[A-Za-z]{2}(@[A-Za-z0-9]+)?$');

/// 结尾的 `@XXX` 变体后缀。
final _suffix = RegExp(r'@([A-Za-z0-9]+)$');

/// 结尾的 `.CC` 两位地区码。
final _regionTail = RegExp(r'\.([A-Za-z]{2})$');

final _spaces = RegExp(r'\s+');

/// `@` 后缀里属于清晰度的那些,统一到四档。其余(PLUS1/PLUS2 等时移变体)不算清晰度。
const _qualityAliases = <String, String>{
  'SD': 'SD',
  '480P': 'SD',
  '576P': 'SD',
  'HD': 'HD',
  '720P': 'HD',
  'FHD': 'FHD',
  '1080P': 'FHD',
  'UHD': '4K',
  '4K': '4K',
  '2160P': '4K',
};

/// 全大写时不该被转成首字母大写的词。
const _keepUpper = <String>{
  'CCTV', 'CGTN', 'BBC', 'CNN', 'HBO', 'NHK', 'TV', 'TVB', 'HD', 'SD', 'FHD',
  'UHD', '4K', 'USA', 'UK', 'EU', 'ABC', 'NBC', 'CBS', 'PBS', 'MTV', 'ESPN',
  'BTV', 'HTV', 'STV', 'ITV', 'RT', 'AL', 'II', 'III', 'IV', 'XL',
};

/// 把 `group-title` 拆成多个标签。
///
/// 现状是 `Entertainment;Family;General` 被当成**一个**组名,于是分组列表里
/// 出现大量只有一个频道的怪组。按 `;` 拆开后,组数会从上百收敛到十几个真实分类。
///
/// 返回去重且保序的标签列表。空字符串、纯空白、以及 `Undefined` 一律丢弃
/// —— 「没有分组」由空列表表示,标签文案交给调用方(需要本地化)。
List<String> splitGroupTitle(String? raw) {
  if (raw == null) return const [];
  final out = <String>[];
  final seen = <String>{};
  for (final part in raw.split(';')) {
    final g = part.trim();
    if (g.isEmpty) continue;
    if (g.toLowerCase() == 'undefined') continue;
    if (seen.add(g.toLowerCase())) out.add(g);
  }
  return out;
}

/// 从若干候选字段里挑出最像人话的一个,清洗后返回展示信息。
///
/// 候选优先级不是固定顺序,而是按「像不像人话」打分 —— 因为不同播放列表
/// 的习惯不一样:有的把好名字放在 `title`,有的放在 `tvg-name`,
/// 还有的两个都填成 id。打分比硬编码顺序稳。
ChannelDisplay normalizeChannel({
  String? tvgName,
  String? title,
  String? tvgId,
}) {
  final candidates = <String>[
    if (title != null && title.trim().isNotEmpty) title.trim(),
    if (tvgName != null && tvgName.trim().isNotEmpty) tvgName.trim(),
    if (tvgId != null && tvgId.trim().isNotEmpty) tvgId.trim(),
  ];
  if (candidates.isEmpty) {
    return const ChannelDisplay(name: '');
  }

  // 分数相同时保持出现顺序(title 优先),故用 > 而非 >=。
  var best = candidates.first;
  var bestScore = _humanness(best);
  for (final c in candidates.skip(1)) {
    final s = _humanness(c);
    if (s > bestScore) {
      best = c;
      bestScore = s;
    }
  }

  return _clean(best);
}

/// 像人话的程度。带空格、带小写说明是给人看的;匹配 id 形态则强烈反向。
int _humanness(String s) {
  var score = 0;
  if (s.contains(' ')) score += 2;
  if (s != s.toUpperCase()) score += 1;
  if (_idLike.hasMatch(s)) score -= 3;
  return score;
}

ChannelDisplay _clean(String raw) {
  var s = raw.trim();
  String? quality;
  String? region;

  // 1. 剥 @ 后缀。是清晰度就收进 quality;不是(PLUS1 等时移变体)则暂存,
  //    等地区码剥完再拼回去 —— 否则 `2MMONDE.MA@PLUS1` 会变成
  //    `2MMONDE.MA PLUS1`,结尾不再是 `.MA`,地区码就剥不掉了。
  String? variant;
  final m = _suffix.firstMatch(s);
  if (m != null) {
    final token = m.group(1)!.toUpperCase();
    final mapped = _qualityAliases[token];
    if (mapped != null) {
      quality = mapped;
    } else {
      variant = token;
    }
    s = s.substring(0, m.start);
  }

  // 2. 剥地区码。只在剥完后仍有内容时才剥,避免把 `CN` 这种整个吃掉。
  final r = _regionTail.firstMatch(s);
  if (r != null && r.start > 0) {
    region = r.group(1)!.toUpperCase();
    s = s.substring(0, r.start);
  }

  // 3. 变体后缀拼回名字末尾。
  if (variant != null) s = '$s $variant';

  // 4. 分隔符归一 + 收敛空白。
  s = s.replaceAll('_', ' ').replaceAll('.', ' ').replaceAll(_spaces, ' ').trim();

  // 5. 全大写且分得开词时做标题式大小写。
  //    单个词不动 —— `1PLUS1INTERNATIONAL` 无法可靠断词,硬拆只会更糟。
  if (s.isNotEmpty && s == s.toUpperCase() && s.contains(' ')) {
    s = s.split(' ').map(_titleCaseWord).join(' ');
  }

  return ChannelDisplay(name: s, quality: quality, region: region);
}

String _titleCaseWord(String w) {
  if (w.isEmpty) return w;
  if (_keepUpper.contains(w)) return w;
  // 含数字的词(CCTV1、24H)保持原样,首字母大写反而读着别扭。
  if (w.contains(RegExp(r'\d'))) return w;
  if (w.length == 1) return w;
  return w[0] + w.substring(1).toLowerCase();
}
