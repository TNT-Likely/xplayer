import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:xplayer/data/models/playlist_model.dart';
// 导入 FavoritesRepository
import 'package:xplayer/presentation/screens/playlist.dart';
import 'package:xplayer/presentation/screens/epg_screen.dart';
import 'package:xplayer/presentation/screens/lan_sync_open_screen.dart';
import 'package:xplayer/presentation/screens/lan_sync_screen.dart';
import 'package:xplayer/presentation/widgets/recent_played_widget.dart';
import 'package:xplayer/presentation/screens/log_center_screen.dart';
import 'package:xplayer/utils/logger_util.dart';
import 'package:xplayer/utils/player_settings.dart';
import 'package:xplayer/services/update_service.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/presentation/widgets/bg_wrapper.dart';
import 'package:xplayer/presentation/widgets/channel_list_widget.dart';
import 'package:xplayer/presentation/widgets/channel_filter_dialog.dart';
import 'package:xplayer/presentation/widgets/playlist_dialog.dart';
import 'package:xplayer/presentation/widgets/preset_source_dialog.dart';
import 'package:xplayer/presentation/widgets/update_proxy_dialog.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/providers/locale_provider.dart';
import 'package:flutter/services.dart';
import 'package:xplayer/shared/components/x_icon_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer/shared/build_flags.dart';
import 'package:xplayer/utils/dialog.dart';
import 'package:xplayer/utils/toast.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xplayer/providers/remote_provider.dart';
import 'package:xplayer/providers/global_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();

    // 数据已在启动屏加载，这里只需启动远程输入服务
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

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      setState(() {
        _version = 'Unknown';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;
    mediaProvider.setLocalizations(localizations);
  }

  // 添加播放列表弹窗
  void _showAddDialog(BuildContext context) {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context2) {
        return PlaylistDialog(
          isNew: true,
          onSuccess: (Playlist playlist) async {
            final id = playlist.id!;

            if (id != '-1') {
              showToast(localizations.updatingChannels);
            }

            final prefs = await SharedPreferences.getInstance();
            prefs.setString('lastSelectedPlaylistId', id.toString());

            await mediaProvider.fetchPlaylists();
            await mediaProvider.updateCurrentPlaylist(id);
            hideToast();
          },
        );
      },
    );
  }

  void _showPresetSources(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const PresetSourceDialog(),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ChannelSearchDialog(),
    );
  }

  void _showGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ChannelGroupDialog(),
    );
  }

  /// 「启动时自动更新」弹窗:分别开关 刷新频道 / 刷新节目单。
  void _showAutoRefreshDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AutoRefreshDialog(),
    );
  }

  void _showSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ChannelSizeDialog(),
    );
  }

  /// 右上角筛选入口图标;[active] 为 true 时右上角叠加一个选中红点。
  Widget _filterIcon(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required bool active,
    required VoidCallback onPressed,
  }) {
    final button = XIconButton(
      icon: icon,
      hoverBgOnly: true,
      tooltipMessage: tooltip,
      onPressed: onPressed,
    );
    if (!active) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          right: 6,
          top: 6,
          child: IgnorePointer(
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppTokens.brand,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.black.withOpacity(0.45), width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguageSwitcher(
    BuildContext context,
    LocaleProvider localeProvider,
  ) {
    List<Map<String, dynamic>> languageItems = [
      {'label': '中文', 'value': 'zh'},
      {'label': 'English', 'value': 'en'},
    ];

    DialogUtils.showOptionsDialog(
      context,
      options: languageItems,
      onOptionSelected: (Map<String, dynamic> selectedOption) {
        final newValue = selectedOption['value'] as String;
        if (newValue == 'zh') {
          localeProvider.setLocale(const Locale('zh', ''));
        } else {
          localeProvider.setLocale(const Locale('en', ''));
        }
      },
      currentId: localeProvider.locale.languageCode,
      title: AppLocalizations.of(context)!.selectLanguage,
      cancelButtonText: AppLocalizations.of(context)!.cancel,
    );
  }

  ChildCallback animeContainer(Widget child) {
    final theme = Theme.of(context);

    return (isFocused) {
      return isFocused
          ? Container(color: theme.primaryColor, child: child)
          : child;
    };
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

  /// 抽屉分组标题。
  Widget _drawerSectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
    );
  }

  Widget _buildHome(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    return BgWrapper(
      child: Scaffold(
        // 背景由 BgWrapper 统一提供(单层遮罩);此处透明,避免二次叠加导致背景过暗/消失
        backgroundColor: Colors.transparent,
        key: _scaffoldKey,
        appBar: AppBar(
          leading: XIconButton(
            icon: Icons.menu,
            hoverBgOnly: true,
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          automaticallyImplyLeading: false, // 确保不会添加默认的返回按钮
          title: Consumer<MediaProvider>(
            builder: (context, mediaProvider, _) {
              if (mediaProvider.isTesting) {
                return Text(
                  '${localizations.testing}: ${mediaProvider.testProgressText}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                );
              }
              return const Text('');
            },
          ),
          elevation: 0, // 移除阴影
          backgroundColor: Colors.transparent, // 使背景透明
          actions: [
            // 搜索 / 分组:独立入口(有频道时才显示;显示大小已移到侧边栏)
            Consumer<MediaProvider>(
              builder: (context, mp, _) {
                if (mp.channels.isEmpty) return const SizedBox.shrink();
                final hasGroups = mp.availableGroups.isNotEmpty;
                final groupActive = mp.selectedGroup != null &&
                    mp.selectedGroup!.isNotEmpty;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _filterIcon(
                      context,
                      icon: Icons.search,
                      tooltip: localizations.search,
                      active: mp.searchQuery.isNotEmpty,
                      onPressed: () => _showSearchDialog(context),
                    ),
                    if (hasGroups)
                      _filterIcon(
                        context,
                        icon: Icons.filter_list,
                        tooltip: localizations.groups,
                        active: groupActive,
                        onPressed: () => _showGroupDialog(context),
                      ),
                    // 测速后才出现:隐藏无法播放的频道(可恢复)
                    if (mp.hasTestResults)
                      _filterIcon(
                        context,
                        icon: Icons.playlist_remove,
                        tooltip: localizations.hideUnplayable,
                        active: mp.hideUnplayable,
                        onPressed: () =>
                            mp.setHideUnplayable(!mp.hideUnplayable),
                      ),
                  ],
                );
              },
            ),
            Consumer<MediaProvider>(
              builder: (context, mediaProvider, _) {
                if (mediaProvider.isTesting) {
                  // 测试中显示取消按钮
                  return XIconButton(
                    icon: Icons.cancel,
                    hoverBgOnly: true,
                    tooltipMessage: localizations.cancel,
                    onPressed: () {
                      mediaProvider.cancelTest();
                      showToast(localizations.testCancelled);
                    },
                  );
                } else {
                  // 未测试显示测试按钮
                  return XIconButton(
                    icon: Icons.speed,
                    hoverBgOnly: true,
                    tooltipMessage: localizations.testChannels,
                    onPressed: () async {
                      try {
                        showToast(localizations.testingChannels);
                        await mediaProvider.testAllChannels();
                        showToast(localizations.testCompleted);
                      } catch (e) {
                        showToast(localizations.testFailed(e.toString()));
                      }
                    },
                  );
                }
              },
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: const Color.fromRGBO(34, 34, 34, 1),
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                // 顶部品牌头:logo + 名称 + 版本
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/mini-logo.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'XPlayer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _version,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                _drawerSectionHeader('播放'),
                // 渲染模式开关:SurfaceView(platformView)/ 纹理。仅非 Android 显示 ——
                // Android 的清晰度走「播放引擎=原生」(见下),且全局透明下 platformView 会卡;
                // iOS/macOS(avfoundation 支持 platformView)保留此选项。
                if (!Platform.isAndroid)
                  ValueListenableBuilder<bool>(
                    valueListenable: useSurfaceView,
                    builder: (_, surface, __) => ListTile(
                      leading: const Icon(Icons.hd, color: Colors.white),
                      title: Text(
                        '${localizations.renderMode}: ${surface ? "SurfaceView" : "Texture"}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        localizations.renderModeHint,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                      trailing: Switch(
                        value: surface,
                        onChanged: (v) => setUseSurfaceView(v),
                      ),
                    ),
                  ),
                // 播放引擎开关:原生(SurfaceView,硬件 VPP)/ video_player。仅 Android。
                if (Platform.isAndroid)
                  ValueListenableBuilder<bool>(
                    valueListenable: useNativeEngine,
                    builder: (_, on, __) => ListTile(
                      leading: const Icon(Icons.memory, color: Colors.white),
                      title: Text(
                        localizations.playerEngine,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        on
                            ? localizations.playerEngineNative
                            : localizations.playerEngineVideoPlayer,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                      trailing: Switch(
                        value: on,
                        onChanged: (v) => setUseNativeEngine(v),
                      ),
                    ),
                  ),
                _drawerSectionHeader('界面'),
                XBaseButton(
                  child: animeContainer(
                    ListTile(
                      leading: const Icon(Icons.photo_size_select_large,
                          color: Colors.white),
                      title: Text(
                        localizations.itemSize,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showSizeDialog(context);
                  },
                ),
                // 首页「最近播放」模块显示开关
                ValueListenableBuilder<bool>(
                  valueListenable: showRecentModule,
                  builder: (_, on, __) => ListTile(
                    leading: const Icon(Icons.history, color: Colors.white),
                    title: Text(localizations.showRecentOnHome,
                        style: const TextStyle(color: Colors.white)),
                    trailing: Switch(
                      value: on,
                      onChanged: (v) => setShowRecentModule(v),
                    ),
                  ),
                ),
                // 首页「收藏」行显示开关
                ValueListenableBuilder<bool>(
                  valueListenable: showFavoritesRow,
                  builder: (_, on, __) => ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.white),
                    title: Text(localizations.showFavoritesOnHome,
                        style: const TextStyle(color: Colors.white)),
                    trailing: Switch(
                      value: on,
                      onChanged: (v) => setShowFavoritesRow(v),
                    ),
                  ),
                ),
                XBaseButton(
                  child: animeContainer(
                    ListTile(
                      leading: const Icon(Icons.language, color: Colors.white),
                      title: Text(
                        localeProvider.locale.languageCode == 'zh'
                            ? '中文'
                            : 'English',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showLanguageSwitcher(context, localeProvider);
                  },
                ),
                _drawerSectionHeader('源与节目单'),
                Consumer<MediaProvider>(
                  builder: (BuildContext context2, mediaProvider, _) {
                    final playlist = [
                      Playlist(name: localizations.favorites, url: '', id: -1),
                      ...mediaProvider.playlists,
                    ];

                    return XBaseButton(
                      child: animeContainer(
                        ListTile(
                          leading: const Icon(
                            Icons.playlist_play,
                            color: Colors.white,
                          ),
                          title: Text(
                            mediaProvider.currentPlaylistId == -1
                                ? localizations.favorites
                                : mediaProvider.currentPlaylist.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        DialogUtils.showOptionsDialog(
                          context,
                          options: playlist
                              .map(
                                (playlist) => {
                                  'label': playlist.name,
                                  'value': playlist.id.toString(),
                                },
                              )
                              .toList(),
                          onOptionSelected: (
                            Map<String, dynamic> selectedOption,
                          ) async {
                            final id = selectedOption['value'];
                            if (id != '-1') {
                              showToast(localizations.updatingChannels);
                            }

                            final prefs = await SharedPreferences.getInstance();
                            prefs.setString('lastSelectedPlaylistId', id);

                            await mediaProvider.updateCurrentPlaylist(
                              int.parse(id),
                            );
                          },
                          currentId: mediaProvider.currentPlaylistId.toString(),
                          title: localizations.selectPlaylist,
                          cancelButtonText: localizations.cancel,
                        );
                      },
                    );
                  },
                ),
                XBaseButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlaylistListScreen(),
                      ),
                    );
                  },
                  child: animeContainer(
                    ListTile(
                      leading: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                      ),
                      title: Text(
                        localizations.playlist,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                XBaseButton(
                  child: animeContainer(
                    ListTile(
                      leading: const Icon(Icons.refresh, color: Colors.white),
                      title: Text(
                        localizations.refreshChannels,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      showToast(localizations.updatingChannels);
                      final mediaProvider = Provider.of<MediaProvider>(
                        context,
                        listen: false,
                      );
                      await mediaProvider.refreshChannels();
                      showToast(localizations.channelsUpdatedSuccessfully);
                    } catch (e, s) {
                      Logger.error('刷新频道失败: $e', e, s);
                      showToast(
                        localizations.channelsUpdateFailed(e.toString()),
                      );
                    }
                  },
                ),
                XBaseButton(
                  child: animeContainer(
                    ListTile(
                      leading: const Icon(Icons.calendar_view_day,
                          color: Colors.white),
                      title: Text(
                        localizations.epg,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EpgScreen()),
                    );
                  },
                ),
                XBaseButton(
                  child: animeContainer(
                    ListTile(
                      leading: const Icon(
                        Icons.event_note,
                        color: Colors.white,
                      ),
                      title: Text(
                        localizations.refreshProgrammes,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      final mediaProvider = Provider.of<MediaProvider>(
                        context,
                        listen: false,
                      );
                      await mediaProvider.refreshProgrammes();
                      showToast(localizations.programmesUpdatedSuccessfully);
                    } catch (e, s) {
                      Logger.error('刷新节目单失败: $e', e, s);
                      showToast(
                        localizations.programmesUpdateFailed(e.toString()),
                      );
                    }
                  },
                ),
                if (!kStoreBuild)
                XBaseButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showPresetSources(context);
                  },
                  child: animeContainer(
                    ListTile(
                      leading:
                          const Icon(Icons.recommend, color: Colors.white),
                      title: Text(
                        localizations.recommendedSources,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                XBaseButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAutoRefreshDialog(context);
                  },
                  child: animeContainer(
                    ListTile(
                      leading:
                          const Icon(Icons.autorenew, color: Colors.white),
                      title: Text(
                        localizations.autoRefreshOnLaunch,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                _drawerSectionHeader('诊断与系统'),
                XBaseButton(
                  child: animeContainer(
                    ListTile(
                      leading:
                          const Icon(Icons.bug_report, color: Colors.white),
                      title: Text(AppLocalizations.of(context)!.diagLog,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LogCenterScreen()),
                    );
                  },
                ),
                // 局域网同步:接收端(发现并拉取对端配置)
                XBaseButton(
                  child: animeContainer(
                    ListTile(
                      leading: const Icon(Icons.devices, color: Colors.white),
                      title: Text(AppLocalizations.of(context)!.lanSync,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LanSyncScreen()),
                    );
                  },
                ),
                // 局域网同步:源端(开放本机供拉取)
                XBaseButton(
                  child: animeContainer(
                    ListTile(
                      leading: const Icon(Icons.wifi_tethering,
                          color: Colors.white),
                      title: Text(AppLocalizations.of(context)!.lanSyncOpen,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const LanSyncOpenScreen()),
                    );
                  },
                ),
                // iOS/iPadOS:App Store 不允许应用自更新,隐藏检查更新入口
                if (!Platform.isIOS)
                  XBaseButton(
                    child: animeContainer(
                      ListTile(
                        leading: const Icon(Icons.system_update,
                            color: Colors.white),
                        title: Text(
                          localizations.checkUpdate,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await UpdateService.checkUpdateWithUI(context);
                    },
                  ),
                XBaseButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (_) => const UpdateProxyDialog(),
                    );
                  },
                  child: animeContainer(
                    ListTile(
                      leading: const Icon(Icons.settings_ethernet,
                          color: Colors.white),
                      title: Text(
                        localizations.updateProxy,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                Consumer<GlobalProvider>(builder: (context, g, _) {
                  if (g.isTV) return const SizedBox.shrink();
                  return XBaseButton(
                    child: animeContainer(
                      ListTile(
                        leading:
                            const Icon(Icons.phonelink, color: Colors.white),
                        title: Text(
                          AppLocalizations.of(context)!.remoteInput,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/remote');
                    },
                  );
                }),
                _drawerSectionHeader('关于'),
                XBaseButton(
                  child: animeContainer(
                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.github,
                          color: Colors.white),
                      title: Text(
                        'Github',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  onPressed: () async {
                    const url = 'https://github.com/TNT-Likely/xplayer';
                    // TV 无浏览器,launch 无效 → 弹窗显示地址供手机/电脑访问;其余打开浏览器。
                    final isTV =
                        Provider.of<GlobalProvider>(context, listen: false).isTV;
                    if (isTV) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Github'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(localizations.githubTvHint),
                              const SizedBox(height: 8),
                              const SelectableText(
                                url,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(localizations.cancel),
                            ),
                          ],
                        ),
                      );
                    } else {
                      await launch(url);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            Consumer<MediaProvider>(
              builder: (context, mediaProvider, _) {
                if (mediaProvider.playlists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        XBaseButton(
                          onPressed: () => _showAddDialog(context),
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
                                localizations.addPlaylist,
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
                              text: localizations.recommendedSources,
                              size: XTextButtonSize.large,
                              type: XTextButtonType.primary,
                              onPressed: () => _showPresetSources(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                } else if (mediaProvider.channels.isEmpty) {
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
                          localizations.noChannelsFound,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16.0),
                        SizedBox(
                          width: 200,
                          child: XTextButton(
                            text: localizations.refreshChannels,
                            type: XTextButtonType.primary,
                            onPressed: () async {
                              try {
                                showToast(localizations.updatingChannels);
                                await mediaProvider.refreshChannels();
                                showToast(
                                    localizations.channelsUpdatedSuccessfully);
                              } catch (e, s) {
                                Logger.error('刷新频道失败: $e', e, s);
                                showToast(localizations
                                    .channelsUpdateFailed(e.toString()));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
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
                            localizations.noChannelsFound,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RecentPlayedWidget(),
                      const FavoritesRowWidget(),
                      const AllChannelsHeader(),
                      Expanded(
                        child: ChannelListWidget(
                          channels: filtered,
                          favoriteChannels: mediaProvider.favoriteChannels,
                          sizeLevel: mediaProvider.gridSizeLevel,
                          onChannelUpdated: () async {
                            try {
                              final mp = Provider.of<MediaProvider>(
                                context,
                                listen: false,
                              );
                              await mp.refreshChannels();
                              showToast(
                                  localizations.channelsUpdatedSuccessfully);
                            } catch (e, s) {
                              Logger.error('刷新频道失败: $e', e, s);
                              showToast(localizations
                                  .channelsUpdateFailed(e.toString()));
                            }
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
