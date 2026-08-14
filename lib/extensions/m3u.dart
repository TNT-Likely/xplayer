// lib/extensions/m3u.dart

import 'package:m3u_parser_nullsafe/m3u_parser_nullsafe.dart';

import 'package:xplayer/data/models/channel_model.dart';
import 'package:m3u_normalize/m3u_normalize.dart';

extension M3uItemExtension on M3uItem {
  Channel toChannel() {
    final display = normalizeChannel(
      tvgName: attributes['tvg-name'],
      title: title,
      tvgId: attributes['tvg-id'],
    );

    return Channel(
      // id 保持原样(含大写化)—— 它是收藏与最近观看的身份键,
      // 改了会让存量数据失联。展示交给 name/quality/region。
      id: (attributes['tvg-id'] ?? attributes['tvg-name'] ?? title)
          .toUpperCase(),
      name: display.name,
      quality: display.quality,
      region: display.region,
      logo: attributes['tvg-logo'],
      source: [
        Source(
          attributes: attributes,
          title: title,
          link: link,
          groupTitle: groupTitle,
          duration: duration,
        )
      ],
    );
  }
}

extension M3uListExtension on M3uList {
  List<Channel> toChannels() {
    return items.map((element) => element.toChannel()).toList();
  }
}
