import 'package:intl/intl.dart';
import 'package:xplayer/data/models/programme_model.dart';

class PlaylistUtil {
  // 查找指定频道和时间点的单个节目
  static List<Programme> findProgramme(
      List<Programme> programmes, String channel) {
    return programmes
        .where((programme) =>
            programme.channel.toLowerCase() == channel.toLowerCase())
        .toList();
  }

  // 查找当前时间点的节目和下一个节目
  static (
    int currentIndex,
    Programme? currentProgramme,
    Programme? nextProgramme
  ) findCurrentAndNextProgramme(List<Programme> programmes, String? channel,
      [DateTime? now]) {
// 使用当前时间或指定的时间点
    if (channel == null) return (-1, null, null);

    final currentTime = now ?? DateTime.now();

    // 筛选出特定频道的节目并按开始时间排序
    final channelProgrammes = programmes
        .where((programme) =>
            programme.channel.toLowerCase() == channel.toLowerCase())
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    int currentIndex = -1;
    Programme? currentProgramme;
    Programme? nextProgramme;

    for (int i = 0; i < channelProgrammes.length; i++) {
      final programme = channelProgrammes[i];
      if (programme.start.isBefore(currentTime) &&
          programme.stop.isAfter(currentTime)) {
        currentProgramme = programme;
        currentIndex = i;
      } else if (programme.start.isAfter(currentTime)) {
        nextProgramme = programme;
        break; // 找到下一个节目后可以停止循环
      }
    }

    // Logger.debug(
    //     '当前时间:${currentTime.toString()},当前节目:${currentProgramme?.title},下个节目:${nextProgramme?.title}');

    return (currentIndex, currentProgramme, nextProgramme);
  }

  static DateTime parseCustomDateTime(String dateString) {
    // 正则表达式匹配 yyyyMMddHHmmss[±HHmm] 格式的日期时间字符串
    final regex = RegExp(
        r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\s*([+-]\d{4})?\s*$');
    final match = regex.firstMatch(dateString);

    if (match != null) {
      // 提取年、月、日、时、分、秒及时区偏移量
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final second = int.parse(match.group(6)!);
      final timeZoneOffsetStr = match.group(7);

      // 如果有时区偏移量，则解析并应用
      int? timeZoneOffset;
      if (timeZoneOffsetStr != null) {
        final sign = timeZoneOffsetStr.startsWith('+') ? 1 : -1;
        final hours = int.parse(timeZoneOffsetStr.substring(1, 3));
        final minutes = int.parse(timeZoneOffsetStr.substring(3, 5));
        timeZoneOffset =
            Duration(hours: sign * hours, minutes: sign * minutes).inMinutes;
      }

      // 创建 DateTime 对象，如果有偏移量则调整为 UTC 时间
      DateTime dateTime = DateTime.utc(year, month, day, hour, minute, second);
      if (timeZoneOffset != null) {
        dateTime = dateTime.subtract(Duration(minutes: timeZoneOffset));
      }

      // Logger.debug('$dateString=== ${dateTime.toLocal()}');

      return dateTime;
    } else {
      // 预定义多个常见的日期时间格式
      final formats = [
        DateFormat("yyyyMMddHHmmss"),
        DateFormat("yyyy-MM-dd HH:mm:ss"),
        DateFormat("yyyy/MM/dd HH:mm:ss"),
        DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ"), // ISO 8601 with timezone
        DateFormat("yyyy-MM-dd'T'HH:mm:ssZ"), // ISO 8601 UTC
        DateFormat("yyyy-MM-dd'T'HH:mm:ss"), // ISO 8601 local time
        // 添加更多格式...
      ];

      // 尝试使用预定义的格式进行解析
      for (final format in formats) {
        try {
          return format.parse(dateString, true); // 设置 isLenient 为 true 可以更宽松地解析
        } catch (_) {}
      }

      // 如果所有预定义格式都失败，尝试使用 DateTime.parse 进行解析
      try {
        return DateTime.parse(dateString);
      } catch (_) {}

      // 如果所有方法都失败，返回一个非常远的日期时间
      return DateTime.utc(1970, 1, 1);
    }
  }
}
