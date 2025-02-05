import 'package:xml/xml.dart';
import 'package:xplayer/utils/playlist_util.dart';

class Programme {
  final String channel;
  final DateTime start;
  final DateTime stop;
  final String title;

  Programme({
    required this.channel,
    required this.start,
    required this.stop,
    required this.title,
  });

  factory Programme.fromXmlElement(XmlElement element) {
    return Programme(
      channel: element.getAttribute('channel') ?? '',
      start: _parseDateTime(element.getAttribute('start')),
      stop: _parseDateTime(element.getAttribute('stop')),
      title: element.findElements('title').map((e) => e.innerText).join('\n'),
    );
  }

  static DateTime _parseDateTime(String? dateTimeString) {
    return PlaylistUtil.parseCustomDateTime(dateTimeString!);
  }

  // 从 Map 转换为对象
  factory Programme.fromMap(Map<String, dynamic> map) {
    return Programme(
      channel: map['channel'] ?? '',
      start: DateTime.parse(map['start']),
      stop: DateTime.parse(map['stop']),
      title: map['title'] ?? '',
    );
  }
}
