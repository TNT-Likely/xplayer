import 'package:flutter/material.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/widgets/channel_item_widget.dart';

class ChannelListWidget extends StatelessWidget {
  final List<Channel> channels;
  final List<Channel> favoriteChannels;
  final VoidCallback? onChannelUpdated;

  /// 显示大小档位(0 最大 .. 4 最小,2=默认)。
  final int sizeLevel;

  const ChannelListWidget({
    super.key,
    required this.channels,
    required this.favoriteChannels,
    this.onChannelUpdated,
    this.sizeLevel = 2,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int crossAxisCount = _getCrossAxisCount(constraints.maxWidth, sizeLevel);

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

  int _getCrossAxisCount(double maxWidth, int sizeLevel) {
    int base;
    if (maxWidth < 380) {
      base = 2;
    } else if (maxWidth < 570) {
      base = 3;
    } else if (maxWidth < 800) {
      base = 4;
    } else {
      base = 6;
    }
    // sizeLevel: 2=默认; <2 列数减少(项更大); >2 列数增多(项更小)
    final count = base + (sizeLevel - 2);
    return count.clamp(2, 12);
  }
}
