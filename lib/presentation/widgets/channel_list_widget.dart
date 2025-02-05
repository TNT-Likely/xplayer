import 'package:flutter/material.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/widgets/channel_item_widget.dart';

class ChannelListWidget extends StatelessWidget {
  final List<Channel> channels;
  final List<Channel> favoriteChannels;
  final VoidCallback? onChannelUpdated;

  const ChannelListWidget({
    super.key,
    required this.channels,
    required this.favoriteChannels,
    this.onChannelUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

        double itemSpacing = 8;
        double sidePadding = itemSpacing;
        double totalSpacing =
            (crossAxisCount - 1) * itemSpacing + 2 * sidePadding;
        double usableWidth = constraints.maxWidth - totalSpacing;
        double itemWidth = usableWidth / crossAxisCount;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: itemSpacing,
              crossAxisSpacing: itemSpacing,
              childAspectRatio: 16 / 12,
            ),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              return ChannelItemWidget(
                channel: channels[index],
                favoriteChannels: favoriteChannels,
                width: itemWidth,
                onChannelUpdated: onChannelUpdated,
              );
            },
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(double maxWidth) {
    if (maxWidth < 380) return 2;
    if (maxWidth < 570) return 3;
    if (maxWidth < 800) return 4;
    return 6;
  }
}
