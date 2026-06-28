import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/providers/mini_player_controller.dart';
import 'package:xplayer/providers/global_provider.dart';
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
        final card = miniCardRect(media.size, media.padding);
        final isTv = Provider.of<GlobalProvider>(context, listen: false).isTV;
        void expand() {
          final ch = c.channel;
          if (ch == null) return;
          // 先在点击回调里(非 build 阶段)切回全屏 → 浮层立即干净隐藏;
          // 若放到新路由 initState 里 take(),notifyListeners 落在 build 期会被吞掉,小窗不消失。
          c.take();
          AppNav.key.currentState?.push(MaterialPageRoute(
            builder: (_) =>
                PlayerScreen(channel: ch, favoriteChannels: c.favorites),
          ));
        }

        return Positioned(
          left: card.left,
          top: card.top,
          width: card.width,
          height: card.height,
          child: Material(
            elevation: 8,
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // 顶部操作条:画在视频之上(原生小窗 SurfaceView 置顶,只盖住下方视频区)。
                SizedBox(
                  height: kMiniHeader,
                  child: Row(
                    children: [
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: expand,
                          child: isTv
                              // TV 遥控器够不到浮层,提示用返回键回到在播频道
                              ? const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('按 返回键 继续观看',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                )
                              : const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Icon(Icons.open_in_full,
                                      color: Colors.white70, size: 14),
                                ),
                        ),
                      ),
                      // TV 上 X 同样够不到(用返回键展开、换台自动关),手机保留点击关闭
                      if (!isTv)
                        InkWell(
                          onTap: () => c.close(),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
                // 视频区:video_player 后端显示 Flutter 视图;原生后端为透明占位,
                // 由置顶的 SurfaceView 在此矩形渲染。点击放大回全屏。
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: expand,
                    child: c.backend!.buildView(),
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
