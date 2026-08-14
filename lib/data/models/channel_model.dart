import 'dart:convert';

import 'package:xplayer/utils/channel_normalize.dart';

class Source {
  final String title;
  final String link;
  final String groupTitle;
  final Map<String, String> attributes;
  final int duration;

  Source({
    required this.title,
    required this.link,
    required this.groupTitle,
    required this.attributes,
    required this.duration,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      title: json['title'],
      link: json['link'],
      groupTitle: json['groupTitle'],
      attributes: _parseAttributes(json['attributes']),
      duration: json['duration'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    // 将 attributes Map 转换回字符串形式
    String attributesString = '';
    attributes.forEach((key, value) {
      if (attributesString.isNotEmpty) attributesString += ', ';
      attributesString += '$key: $value';
    });

    return {
      'title': title,
      'link': link,
      'groupTitle': groupTitle,
      'attributes': attributesString,
      'duration': duration,
    };
  }
}

class Channel {
  /// 身份键。**不要改动它的生成规则** —— `favorites_repository` 把它直接存进
  /// 数据库、`recent_util` 拿它去重,变了会让存量收藏与最近观看全部失联。
  final String id;

  /// 展示名。已由 [normalizeChannel] 规范化:剥掉 `@HD` 后缀与 `.CN` 地区码,
  /// 全大写且能断词时转标题式。搜索仍可回落到 [id] 匹配原始串。
  final String name;

  /// 清晰度角标(HD / SD / FHD / 4K)。无法判定时为 null,卡片上不显示角标。
  final String? quality;

  /// 两位地区码(大写),用于卡片副行。无法判定时为 null。
  final String? region;

  final String? logo;
  final List<Source> source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Channel({
    required this.id,
    required this.name,
    this.quality,
    this.region,
    this.logo,
    required this.source,
    this.createdAt,
    this.updatedAt,
  });

  /// 该频道所属的全部分组标签(跨 source 合并去重,保序)。
  /// 空列表表示未分类 —— 文案交给 UI 层,数据层不持有本地化字符串。
  List<String> get groups {
    final out = <String>[];
    final seen = <String>{};
    for (final s in source) {
      for (final g in splitGroupTitle(s.groupTitle)) {
        if (seen.add(g.toLowerCase())) out.add(g);
      }
    }
    return out;
  }

  factory Channel.fromJson(Map<String, dynamic> json) {
    List<Source> sources = [];
    if (json['source'] != null && json['source'] is List) {
      sources = (json['source'] as List)
          .map((item) => Source.fromJson(item))
          .toList();
    }

    final rawName = json['name'] as String? ?? '';
    // 老缓存没有 quality/region 字段,此时就地补算一次 —— 这样升级后不必等
    // 用户手动刷新播放列表,界面立刻就是干净的。
    final hasDisplayFields = json.containsKey('quality') ||
        json.containsKey('region');
    final display =
        hasDisplayFields ? null : normalizeChannel(tvgName: rawName);

    return Channel(
      id: json['id'] ?? '',
      name: display?.name ?? rawName,
      quality: json['quality'] as String? ?? display?.quality,
      region: json['region'] as String? ?? display?.region,
      logo: json['logo'],
      source: sources,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quality': quality,
      'region': region,
      'logo': logo,
      'source': source.map((s) => s.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

// 辅助函数来解析属性字符串为 Map<String, String>
Map<String, String> _parseAttributes(String? attributesString) {
  Map<String, String> attributesMap = {};
  if (attributesString != null && attributesString.isNotEmpty) {
    try {
      final attributePairs = attributesString.split(', ');
      for (var pair in attributePairs) {
        final keyValue = pair.split(': ');
        if (keyValue.length == 2) {
          attributesMap[keyValue[0]] = keyValue[1];
        }
      }
    } catch (e) {
      print('Failed to parse attributes: $e');
    }
  }
  return attributesMap;
}

List<Channel> parseChannels(String jsonString) {
  if (jsonString.trim().isEmpty) return [];
  try {
    final decoded = json.decode(jsonString);
    // 缓存实际格式是 jsonEncode(toChannels()) —— 一个数组;
    // 同时兼容 {items:[...]} / {channels:[...]} 的对象格式。
    final List<dynamic> channelsJson;
    if (decoded is List) {
      channelsJson = decoded;
    } else if (decoded is Map<String, dynamic>) {
      channelsJson = (decoded['items'] ?? decoded['channels'] ?? []) as List;
    } else {
      channelsJson = [];
    }
    return channelsJson
        .map((json) => Channel.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (err) {
    print('Error parsing JSON: $err');
    return [];
  }
}
