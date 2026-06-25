import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/providers/mini_player_controller.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/shared/navigation.dart';

/// 全局右下角小窗。mode==mini 时显示;点击展开回全屏,X 关闭。
class MiniPlayerOverlay extends StatelessWidget {
  const MiniPlayerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MiniPlayerController>(
      builder: (context, c, _) {
        if (!c.hasMini) return const SizedBox.shrink();
        final media = MediaQuery.of(context);
        final w = (media.size.width * 0.4).clamp(160.0, 240.0);
        final h = w * 9 / 16;
        return Positioned(
          right: 12 + media.padding.right,
          bottom: 12 + media.padding.bottom,
          width: w,
          height: h,
          child: Material(
            elevation: 8,
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () {
                    final ch = c.channel;
                    if (ch == null) return;
                    AppNav.key.currentState?.push(MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                          channel: ch, favoriteChannels: c.favorites),
                    ));
                  },
                  child: c.backend!.buildView(),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () => c.close(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.black54,
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
