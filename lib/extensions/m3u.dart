// lib/extensions/m3u_extensions.dart

import 'package:m3u_parser_nullsafe/m3u_parser_nullsafe.dart';

import 'package:xplayer/data/models/channel_model.dart';

extension M3uItemExtension on M3uItem {
  Channel toChannel() {
    return Channel(
        id: (attributes['tvg-id'] ?? attributes['tvg-name'] ?? title)
            .toUpperCase(),
        name: (attributes['tvg-name'] ?? title).toUpperCase(),
        logo: attributes['tvg-logo'],
        source: [
          Source(
              attributes: attributes,
              title: title,
              link: link,
              groupTitle: groupTitle,
              duration: duration)
        ]);
  }
}

extension M3uListExtension on M3uList {
  List<Channel> toChannels() {
    return items.map((element) => element.toChannel()).toList();
  }
}
