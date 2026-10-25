import 'dart:convert';

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
      duration: int.tryParse('${json['duration']}') ?? -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'link': link,
      'groupTitle': groupTitle,
      'attributes': attributes,
      'duration': duration,
    };
  }
}

class Channel {
  final String id;
  final String name;
  final String? logo;
  final List<Source> source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Channel({
    required this.id,
    required this.name,
    this.logo,
    required this.source,
    this.createdAt,
    this.updatedAt,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    List<Source> sources = [];
    if (json['source'] != null && json['source'] is List) {
      sources = (json['source'] as List)
          .map((item) => Source.fromJson(item))
          .toList();
    }

    return Channel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
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
      'logo': logo,
      'source': source.map((s) => s.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

// 辅助函数来解析属性字符串为 Map<String, String>
Map<String, String> _parseAttributes(Object? attributesString) {
  if (attributesString is Map) {
    return attributesString.map((key, value) => MapEntry('$key', '$value'));
  }
  Map<String, String> attributesMap = {};
  if (attributesString is String && attributesString.isNotEmpty) {
    try {
      final attributePairs = attributesString.split(', ');
      for (var pair in attributePairs) {
        final separator = pair.indexOf(': ');
        if (separator > 0) {
          attributesMap[pair.substring(0, separator)] = pair.substring(separator + 2);
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
