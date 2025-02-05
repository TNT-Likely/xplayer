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
  try {
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<dynamic> channelsJson = data['items'] ?? [];
    return channelsJson.map((json) => Channel.fromJson(json)).toList();
  } catch (err) {
    print('Error parsing JSON: $err');
    return [];
  }
}
