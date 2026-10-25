import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/screens/lan_sync_screen.dart';
import 'package:xplayer/presentation/screens/lan_sync_open_screen.dart';
import 'package:xplayer/presentation/screens/log_center_screen.dart';
import 'package:xplayer/presentation/widgets/channel_filter_dialog.dart';
import 'package:xplayer/presentation/widgets/theme_color_dialog.dart';
import 'package:xplayer/presentation/widgets/update_proxy_dialog.dart';
import 'package:xplayer/providers/global_provider.dart';
import 'package:xplayer/providers/locale_provider.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/providers/remote_provider.dart';
import 'package:xplayer/services/update_service.dart';
import 'package:xplayer/shared/build_flags.dart';
import 'package:xplayer/utils/player_settings.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform()
        .then((info) {
          if (mounted) {
            setState(() => _version = '${info.version}+${info.buildNumber}');
          }
        })
        .catchError((_) {});
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  Widget _action(String label, XpSymbol icon, VoidCallback action) =>
      XpNavigationItem(label: label, icon: icon, onPressed: action);
  Widget _toggle(
    String title,
    ValueNotifier<bool> notifier,
    Future<void> Function(bool) change, {
    String? description,
  }) => ValueListenableBuilder<bool>(
    valueListenable: notifier,
    builder: (_, value, __) => XpToggleTile(
      title: title,
      description: description,
      value: value,
      onChanged: change,
    ),
  );
  Widget _group(String title, List<Widget> children) => XpSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: XpTheme.of(context).titleSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ...children,
      ],
    ),
  );
  Future<void> _github() async {
    final uri = Uri.parse('https://github.com/TNT-Likely/xplayer');
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => XpConfirmDialog(
        title: 'GitHub',
        confirmLabel: '完成',
        onConfirm: () => Navigator.pop(ctx),
        onCancel: () => Navigator.pop(ctx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: uri.toString(),
              size: 180,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 12),
            SelectableText(uri.toString()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final media = context.watch<MediaProvider>();
    final global = context.watch<GlobalProvider>();
    final remote = context.watch<RemoteProvider>();
    return LayoutBuilder(
      builder: (context, box) {
        final groups = [
          _group('播放与恢复', [
            _toggle(
              l.miniPlayerOnExit,
              miniPlayerOnExit,
              setMiniPlayerOnExit,
              description: l.miniPlayerOnExitHint,
            ),
            if (Platform.isAndroid && !global.isTV)
              _toggle(
                l.pipOnLeave,
                pipOnLeave,
                setPipOnLeave,
                description: l.pipOnLeaveHint,
              ),
            if (Platform.isAndroid) ...[
              _toggle(
                l.playerEngine,
                useNativeEngine,
                setUseNativeEngine,
                description: l.playerEngineNative,
              ),
              _toggle(
                l.renderMode,
                useSurfaceView,
                setUseSurfaceView,
                description: l.renderModeHint,
              ),
            ],
          ]),
          _group('界面与语言', [
            _toggle(l.showRecentOnHome, showRecentModule, setShowRecentModule),
            _toggle(
              l.showFavoritesOnHome,
              showFavoritesRow,
              setShowFavoritesRow,
            ),
            _action(
              l.itemSize,
              XpSymbol.channels,
              () => showDialog(
                context: context,
                builder: (_) => const ChannelSizeDialog(),
              ),
            ),
            _action(
              l.themeColor,
              XpSymbol.settings,
              () => showDialog(
                context: context,
                builder: (_) => const ThemeColorDialog(),
              ),
            ),
            _action(
              '中文 / English',
              XpSymbol.settings,
              () => showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: Text(l.selectLanguage),
                  children: [
                    for (final locale in ['zh', 'en'])
                      SimpleDialogOption(
                        onPressed: () {
                          context.read<LocaleProvider>().setLocale(
                            Locale(locale),
                          );
                          Navigator.pop(ctx);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(locale == 'zh' ? '中文' : 'English'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ]),
          _group('列表与节目单', [
            XpToggleTile(
              title: '启动时更新频道',
              value: media.autoRefreshChannels,
              onChanged: media.setAutoRefreshChannels,
            ),
            XpToggleTile(
              title: '启动时更新节目单',
              value: media.autoRefreshProgrammes,
              onChanged: media.setAutoRefreshProgrammes,
            ),
            _action(
              l.playlist,
              XpSymbol.sources,
              () => Navigator.pushNamed(context, '/playlists'),
            ),
            _action(
              l.refreshProgrammes,
              XpSymbol.sync,
              () => media.refreshProgrammes(),
            ),
          ]),
          _group('设备与同步', [
            if (global.isTV ||
                Platform.isMacOS ||
                Platform.isWindows ||
                Platform.isLinux)
              XpNotice(
                title: '手机遥控连接地址',
                description: remote.serverAddress ?? '正在准备局域网服务…',
              ),
            if (!global.isTV)
              _action(
                l.remoteInput,
                XpSymbol.remote,
                () => Navigator.pushNamed(context, '/remote'),
              ),
            _action(
              l.lanSync,
              XpSymbol.sync,
              () => _open(const LanSyncScreen()),
            ),
            _action(
              l.lanSyncOpen,
              XpSymbol.sync,
              () => _open(const LanSyncOpenScreen()),
            ),
          ]),
          _group('诊断与系统', [
            _action(
              l.diagLog,
              XpSymbol.info,
              () => _open(const LogCenterScreen()),
            ),
            _action(
              l.updateProxy,
              XpSymbol.settings,
              () => showDialog(
                context: context,
                builder: (_) => const UpdateProxyDialog(),
              ),
            ),
            if (!kStoreBuild)
              _action(
                l.checkUpdate,
                XpSymbol.sync,
                () => UpdateService.checkUpdateWithUI(context),
              ),
            _action('GitHub · XPlayer $_version', XpSymbol.info, _github),
          ]),
        ];
        final twoColumns = box.maxWidth >= 1050 && !global.isTV;
        return SingleChildScrollView(
          key: const PageStorageKey('settings-scroll'),
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final group in groups)
                SizedBox(
                  width: twoColumns
                      ? (box.maxWidth - 68) / 2
                      : box.maxWidth - 48,
                  child: group,
                ),
            ],
          ),
        );
      },
    );
  }
}
