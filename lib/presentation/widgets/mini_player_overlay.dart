import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/providers/mini_player_controller.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/shared/navigation.dart';
import 'package:xplayer/presentation/adapters/media_presentation.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

/// 全局右下角小窗。mode==mini 时显示;点击展开回全屏,X 关闭。
class MiniPlayerOverlay extends StatelessWidget {
  const MiniPlayerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MiniPlayerController>(
      builder: (context, c, _) {
        if (!c.hasMini) return const SizedBox.shrink();
        final media = MediaQuery.of(context);
        final theme = XpTheme.of(context);
        final headerHeight = miniHeaderHeight(
          media.textScaler,
          bodySize: theme.bodySize,
          smallSize: theme.smallSize,
        );
        final card = miniCardRect(
          media.size,
          media.padding,
          headerHeight: headerHeight,
        );
        final backend = c.backend!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (c.hasMini && identical(c.backend, backend)) {
            backend
                .setSurfaceBounds(
                  miniVideoRect(
                    media.size,
                    media.padding,
                    headerHeight: headerHeight,
                  ),
                  media.devicePixelRatio,
                )
                .catchError((_) {});
          }
        });
        final mediaProvider = context.watch<MediaProvider>();
        final presentation = MediaPresentation(mediaProvider);
        void expand() {
          final ch = c.channel;
          if (ch == null) return;
          // 先在点击回调里(非 build 阶段)切回全屏 → 浮层立即干净隐藏;
          // 若放到新路由 initState 里 take(),notifyListeners 落在 build 期会被吞掉,小窗不消失。
          c.take();
          AppNav.key.currentState?.push(
            MaterialPageRoute(
              builder: (_) =>
                  PlayerScreen(channel: ch, favoriteChannels: c.favorites),
            ),
          );
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
                  height: headerHeight,
                  child: ValueListenableBuilder(
                    valueListenable: c.backend!.notifier,
                    builder: (_, value, __) => XpMiniPlayer(
                      channel: presentation.channel(c.channel!),
                      epgStatus: presentation.channelStatus(c.channel!),
                      paused: !value.isPlaying,
                      onRestore: expand,
                      onTogglePause: () {
                        if (value.isPlaying) {
                          c.backend!.pause();
                        } else {
                          c.backend!.play();
                        }
                      },
                      onClose: c.close,
                    ),
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

/// 小窗属于 Navigator 的 Overlay，保证 Tooltip、焦点和路由遮罩都有正确的祖先。
class MiniPlayerNavigatorObserver extends NavigatorObserver {
  final _routes = <Route<dynamic>>[];
  OverlayEntry? _entry;
  bool _scheduled = false;
  void _update() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final overlay = navigator?.overlay;
      if (overlay == null) return;
      _entry ??= OverlayEntry(
        builder: (_) => _routes.lastOrNull is PopupRoute
            ? const SizedBox.shrink()
            : const MiniPlayerOverlay(),
      );
      if (_entry!.mounted) _entry!.remove();
      overlay.insert(_entry!);
      _entry!.markNeedsBuild();
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _update();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _update();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _update();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    }
    _update();
  }
}
