import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/widgets/bg_wrapper.dart';
import 'package:xplayer/presentation/widgets/channel_list_widget.dart';
import 'package:xplayer/presentation/widgets/home/hero_live_card.dart';
import 'package:xplayer/presentation/widgets/home/group_chips_row.dart';
import 'package:xplayer/presentation/widgets/home/group_sheet.dart';
import 'package:xplayer/presentation/widgets/home/home_app_bar.dart';
import 'package:xplayer/presentation/widgets/home/home_drawer.dart';
import 'package:xplayer/presentation/widgets/recent_played_widget.dart';
import 'package:xplayer/presentation/widgets/channel_filter_dialog.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/widgets/playlist_dialog.dart';
import 'package:xplayer/presentation/widgets/preset_source_dialog.dart';
import 'package:xplayer/providers/global_provider.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/providers/mini_player_controller.dart';
import 'package:xplayer/providers/remote_provider.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/shared/build_flags.dart';
import 'package:xplayer/shared/navigation.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer/utils/logger_util.dart';
import 'package:xplayer/utils/toast.dart';

/// 首页(方向 A · ON AIR 演播室)。
///
/// 组件拆分:顶栏 [HomeAppBar] / 抽屉 [HomeDrawer] / 大直播卡 [HeroLiveCard] /
/// 分组行 [GroupChipsRow] / 分组抽屉(group_sheet.dart)各自成文件;
/// 本文件只负责组装与「正在播」的选取(小窗续播 > 最近播放 > 列表首个)。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // 数据已在启动屏加载,这里只需启动远程输入服务
    final globalProvider = Provider.of<GlobalProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!globalProvider.isMobile) {
        try {
          await Provider.of<RemoteProvider>(context, listen: false)
              .startServer(serviceName: 'XPlayer TV');
        } catch (_) {}
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;
    mediaProvider.setLocalizations(localizations);
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ChannelSearchDialog(),
    );
  }

  /// 空态「添加播放列表」:与抽屉内同一弹窗(PlaylistDialog isNew)。
  void _showAddPlaylistDialog(BuildContext context) {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => PlaylistDialog(
        isNew: true,
        onSuccess: (playlist) async {
          final id = playlist.id!;
          if (id != '-1') showToast(l.updatingChannels);
          await mediaProvider.fetchPlaylists();
          await mediaProvider.updateCurrentPlaylist(id);
          hideToast();
        },
      ),
    );
  }

  void _showPresetSources(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const PresetSourceDialog(),
    );
  }

  /// 菜单键:若有小窗续播,回到该频道全屏(复用小窗后端,不重连)。
  /// TV 遥控器够不到悬浮小窗(浮层在路由焦点域之外),用菜单键作为"回到在播"入口;
  /// 返回键则回归本职(退出),不再被拦截。
  void _resumeMini(BuildContext context) {
    final mini = Provider.of<MiniPlayerController>(context, listen: false);
    if (!mini.hasMini) return;
    final ch = mini.channel;
    final favs = mini.favorites;
    if (ch == null) return;
    mini.take();
    AppNav.key.currentState?.push(MaterialPageRoute(
      builder: (_) => PlayerScreen(channel: ch, favoriteChannels: favs),
    ));
  }

  /// 返回键退出二次确认(App 与 TV 共用系统返回键)。
  /// 抽屉打开时优先关抽屉,不弹退出框。
  Future<bool> _confirmExit(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.surfacePanel,
        title: Text(l.exitAppTitle,
            style: const TextStyle(color: AppTokens.textPrimary)),
        content: Text(l.exitAppMessage,
            style: const TextStyle(color: AppTokens.textSecondary)),
        actions: [
          XTextButton(
            text: l.cancel,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          XTextButton(
            text: l.exit,
            type: XTextButtonType.danger,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        // 菜单键 → 回到正在小窗续播的频道(不占用返回键)
        const SingleActivator(LogicalKeyboardKey.contextMenu): () =>
            _resumeMini(context),
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          // 抽屉开着先关抽屉
          final scaffold = _scaffoldKey.currentState;
          if (scaffold != null && scaffold.isDrawerOpen) {
            scaffold.closeDrawer();
            return;
          }
          if (await _confirmExit(context)) {
            await SystemNavigator.pop();
          }
        },
        child: _buildHome(context),
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    return BgWrapper(
      child: Scaffold(
        // 背景由 BgWrapper 统一提供(单层遮罩);此处透明,避免二次叠加导致背景过暗/消失
        backgroundColor: Colors.transparent,
        key: _scaffoldKey,
        appBar: HomeAppBar(
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
          onSearch: () => _showSearchDialog(context),
        ),
        drawer: const HomeDrawer(),
        body: Consumer<MediaProvider>(
          builder: (context, mediaProvider, _) {
            if (mediaProvider.playlists.isEmpty) {
              return _EmptyPlaylists(
                onAdd: () => _showAddPlaylistDialog(context),
                onPreset: () => _showPresetSources(context),
              );
            }
            if (mediaProvider.channels.isEmpty) {
              return _NoChannels(onRefresh: () => _refreshChannels(context));
            }
            final filtered = mediaProvider.filteredChannels;
            if (filtered.isEmpty) {
              // 搜索/分组无结果(原始频道非空)
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off,
                        color: Colors.white, size: 60),
                    Text(
                      AppLocalizations.of(context)!.noChannelsFound,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(builder: (context) {
                  final hero = _heroChannel(mediaProvider);
                  if (hero == null) return const SizedBox.shrink();
                  // TV 端不显示大直播卡:十英尺界面以焦点网格为主(见方向 A 的 TV 稿)。
                  final isTV =
                      Provider.of<GlobalProvider>(context, listen: false).isTV;
                  if (isTV) return const SizedBox.shrink();
                  // 宽屏/横屏(手机横屏/Pad)限高 = 屏高 60%,画面区弹性伸缩,
                  // 避免 16:9 固定比例在横屏下把信息层挤出屏幕(实测曾溢出 174px)。
                  final isWide = MediaQuery.of(context).size.width >= 600;
                  final maxHeight = isWide
                      ? MediaQuery.of(context).size.height * 0.38
                      : double.infinity;
                  return ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: maxHeight),
                    child: HeroLiveCard(
                      channel: hero,
                      favoriteChannels: mediaProvider.favoriteChannels,
                    ),
                  );
                }),
                GroupChipsRow(
                  onOpenSheet: () => showGroupSheet(context),
                ),
                Expanded(
                  child: ChannelListWidget(
                    channels: filtered,
                    favoriteChannels: mediaProvider.favoriteChannels,
                    sizeLevel: mediaProvider.gridSizeLevel,
                    onChannelUpdated: () => _refreshChannels(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 大直播卡展示的频道:锚定当前源(过滤列表首个);
  /// 若有正在续播的小窗且属于当前源,优先展示它。
  Channel? _heroChannel(MediaProvider mp) {
    final filtered = mp.filteredChannels;
    if (filtered.isEmpty) return null;
    final mini = Provider.of<MiniPlayerController>(context, listen: false);
    if (mini.hasMini && mini.channel != null) {
      final inSource =
          filtered.any((c) => c.id == mini.channel!.id);
      if (inSource) return mini.channel;
    }
    return filtered.first;
  }

  Future<void> _refreshChannels(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    try {
      final mp = Provider.of<MediaProvider>(context, listen: false);
      await mp.refreshChannels();
      showToast(l.channelsUpdatedSuccessfully);
    } catch (e, s) {
      Logger.error('刷新频道失败: $e', e, s);
      showToast(l.channelsUpdateFailed(e.toString()));
    }
  }
}

/// 尚无播放列表:引导添加 / 推荐源。
class _EmptyPlaylists extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onPreset;

  const _EmptyPlaylists({required this.onAdd, required this.onPreset});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          XBaseButton(
            onPressed: onAdd,
            child: (isFocused) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add,
                  size: 48.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 8.0),
                Text(
                  l.addPlaylist,
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (!kStoreBuild) ...[
            const SizedBox(height: 16.0),
            SizedBox(
              width: 240,
              child: XTextButton(
                text: l.recommendedSources,
                size: XTextButtonSize.large,
                type: XTextButtonType.primary,
                onPressed: onPreset,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 有播放列表但无频道:引导刷新。
class _NoChannels extends StatelessWidget {
  final VoidCallback onRefresh;

  const _NoChannels({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            color: Colors.white,
            size: 60,
          ),
          Text(
            l.noChannelsFound,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            width: 200,
            child: XTextButton(
              text: l.refreshChannels,
              type: XTextButtonType.primary,
              onPressed: onRefresh,
            ),
          ),
        ],
      ),
    );
  }
}
