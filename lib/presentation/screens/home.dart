import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:xplayer/data/models/playlist_model.dart';
// 导入 FavoritesRepository
import 'package:xplayer/presentation/screens/playlist.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/presentation/widgets/bg_wrapper.dart';
import 'package:xplayer/presentation/widgets/channel_list_widget.dart';
import 'package:xplayer/presentation/widgets/playlist_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/providers/locale_provider.dart';
import 'package:xplayer/shared/components/x_icon_button.dart';
import 'package:xplayer/utils/dialog.dart';
import 'package:xplayer/utils/toast.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // 确保在页面加载时调用 MediaProvider 的 initialize 方法
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    mediaProvider.initialize();
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

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    return BgWrapper(
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(0, 0, 0, 0.5),
        // backgroundColor: Colors.transparent,
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
          title: const Text(''), // 设置为空文本以避免默认标题
          elevation: 0, // 移除阴影
          backgroundColor: Colors.transparent, // 使背景透明
        ),
        drawer: Drawer(
          backgroundColor: const Color.fromRGBO(34, 34, 34, 1),
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
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
                                  'label': playlist.name ?? '',
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
                    } catch (e) {
                      showToast(
                        localizations.channelsUpdateFailed(e.toString()),
                      );
                    }
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
                    } catch (e) {
                      showToast(
                        localizations.programmesUpdateFailed(e.toString()),
                      );
                    }
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
                XBaseButton(
                  child: animeContainer(
                    ListTile(
                      leading: const Icon(FontAwesomeIcons.github,
                          color: Colors.white),
                      title: Text(
                        'Github',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  onPressed: () async {
                    await launch('https://github.com/TNT-Likely/xplayer');
                  },
                ),
                const ListTile(
                  leading: Icon(Icons.info, color: Colors.white),
                  title: Text('1.0.0', style: TextStyle(color: Colors.white)),
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
                    child: XBaseButton(
                      onPressed: () => _showAddDialog(context),
                      child: (isFocused) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add,
                            size: 48.0,
                            color: Colors.white,
                          ), // 增大图标尺寸
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
                      ],
                    ),
                  );
                } else {
                  return ChannelListWidget(
                    channels: mediaProvider.channels,
                    favoriteChannels: mediaProvider.favoriteChannels,
                    onChannelUpdated: () async {
                      try {
                        final mediaProvider = Provider.of<MediaProvider>(
                          context,
                          listen: false,
                        );
                        await mediaProvider.refreshChannels();
                        showToast(localizations.channelsUpdatedSuccessfully);
                      } catch (e) {
                        showToast(
                          localizations.channelsUpdateFailed(e.toString()),
                        );
                      }
                    },
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
