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
              // 卡片高度必须容得下:牌面 16:10(= 0.625W)+ 名称最多两行
              // + 分组/地区副行 + 上下内边距。
              //
              // 原值 16/12(高 0.75W)是配 16:9 牌面 + 单行标题的。牌面改成
              // 16:10 之后标题区只剩 0.125W —— 宽 120 时是 15px,扣掉 8px
              // 内边距只余 7px,而一行名字就要 10.5px,于是真机报
              // 「RenderFlex overflowed by 15 pixels」。
              //
              // 16/15(高 0.9375W)给标题区留 0.3125W,两行名称加副行都装得下。
              childAspectRatio: 16 / 15,
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
