import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/screens/epg_screen.dart';
import 'package:xplayer/presentation/screens/lan_sync_open_screen.dart';
import 'package:xplayer/presentation/screens/lan_sync_screen.dart';
import 'package:xplayer/presentation/screens/log_center_screen.dart';
import 'package:xplayer/presentation/screens/playlist.dart';
import 'package:xplayer/presentation/widgets/channel_filter_dialog.dart';
import 'package:xplayer/presentation/widgets/playlist_dialog.dart';
import 'package:xplayer/presentation/widgets/preset_source_dialog.dart';
import 'package:xplayer/presentation/widgets/theme_color_dialog.dart';
import 'package:xplayer/presentation/widgets/update_proxy_dialog.dart';
import 'package:xplayer/providers/global_provider.dart';
import 'package:xplayer/providers/locale_provider.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/shared/build_flags.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer/shared/theme/theme_settings.dart';
import 'package:xplayer/utils/dialog.dart';
import 'package:xplayer/utils/logger_util.dart';
import 'package:xplayer/utils/toast.dart';
import 'package:xplayer/utils/player_settings.dart';
import 'package:xplayer/services/update_service.dart';

/// 首页抽屉(源与节目单 / 播放 / 界面 / 诊断与系统 / 关于)。
///
/// 从 home.dart 原样抽出:行为、持久化 key 与文案均不变,仅组件化;
/// 新增设置项时加在对应分组即可,home.dart 不再膨胀。
class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
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
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: const Color.fromRGBO(34, 34, 34, 1),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _brandHeader(),
            const Divider(color: Colors.white24, height: 1),
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
            // 返回首页小窗续播开关(全平台)
            ValueListenableBuilder<bool>(
              valueListenable: miniPlayerOnExit,
              builder: (_, on, __) => ListTile(
                leading: const Icon(Icons.picture_in_picture_alt,
                    color: Colors.white),
                title: Text(localizations.miniPlayerOnExit,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  localizations.miniPlayerOnExitHint,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                trailing: Switch(
                  value: on,
                  onChanged: (v) => setMiniPlayerOnExit(v),
                ),
              ),
            ),
            // 回桌面系统画中画开关(仅 Android 手机/平板;TV 无系统 PiP,隐藏)
            if (Platform.isAndroid)
              Consumer<GlobalProvider>(
                builder: (context, g, _) {
                  if (g.isTV) return const SizedBox.shrink();
                  return ValueListenableBuilder<bool>(
                    valueListenable: pipOnLeave,
                    builder: (_, on, __) => ListTile(
                      leading: const Icon(Icons.picture_in_picture,
                          color: Colors.white),
                      title: Text(localizations.pipOnLeave,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        localizations.pipOnLeaveHint,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                      trailing: Switch(
                        value: on,
                        onChanged: (v) => setPipOnLeave(v),
                      ),
                    ),
                  );
                },
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
            // 主题强调色:色块 trailing 实时反映当前色
            ValueListenableBuilder<Color>(
              valueListenable: themeColor,
              builder: (_, color, __) => XBaseButton(
                child: animeContainer(
                  ListTile(
                    leading:
                        const Icon(Icons.palette, color: Colors.white),
                    title: Text(
                      localizations.themeColor,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (_) => const ThemeColorDialog(),
                  );
                },
              ),
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
            // 应用商店包(App Store / Mac App Store / Play)不允许应用自更新,
            // 隐藏「检查更新」入口(Guideline 2.4.5)。侧载包(GitHub)保留。
            if (!kStoreBuild)
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
                      backgroundColor: AppTokens.surfacePanel,
                      title: const Text('Github',
                          style: TextStyle(color: AppTokens.textPrimary)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            localizations.githubTvHint,
                            style: const TextStyle(
                                color: AppTokens.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          // 二维码:手机扫码直达;白底保证暗色弹窗下可识别
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: QrImageView(
                              data: url,
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const SelectableText(
                            url,
                            style: TextStyle(
                                color: AppTokens.textPrimary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      actions: [
                        XTextButton(
                          text: localizations.cancel,
                          onPressed: () => Navigator.of(context).pop(),
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
    );
  }

  /// 顶部品牌头:logo + 名称 + 版本。
  Widget _brandHeader() {
    return Padding(
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
    );
  }
}
