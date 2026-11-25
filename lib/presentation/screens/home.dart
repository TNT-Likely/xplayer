import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/adaptive/app_layout.dart';
import 'package:xplayer/presentation/adapters/app_actions.dart';
import 'package:xplayer/presentation/adapters/media_presentation.dart';
import 'package:xplayer/presentation/screens/epg_screen.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/presentation/screens/settings_screen.dart';
import 'package:xplayer/presentation/widgets/channel_filter_dialog.dart';
import 'package:xplayer/presentation/widgets/preset_source_dialog.dart';
import 'package:xplayer/providers/global_provider.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/providers/mini_player_controller.dart';
import 'package:xplayer/providers/remote_provider.dart';
import 'package:xplayer/shared/build_flags.dart';
import 'package:xplayer/utils/channel_filter.dart';
import 'package:xplayer/utils/player_settings.dart';
import 'package:xplayer/utils/toast.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

enum AppSection { home, channels, guide, favorites, settings }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.startRemoteServer = true});
  final bool startRemoteServer;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppSection _section = AppSection.home;
  final _search = TextEditingController();
  final _favoritesSearch = TextEditingController();
  final _storage = PageStorageBucket();
  Timer? _timer;
  DateTime _now = DateTime.now();
  Channel? _selected;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.startRemoteServer) return;
      final g = context.read<GlobalProvider>();
      final platform = Theme.of(context).platform;
      if (g.isTV ||
          ![TargetPlatform.android, TargetPlatform.iOS].contains(platform)) {
        context
            .read<RemoteProvider>()
            .startServer(serviceName: 'XPlayer')
            .catchError((_) {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<MediaProvider>().setLocalizations(
      AppLocalizations.of(context)!,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    _favoritesSearch.dispose();
    super.dispose();
  }

  String _label(AppSection section) {
    final l = AppLocalizations.of(context)!;
    return switch (section) {
      AppSection.home => l.home,
      AppSection.channels => l.allChannels,
      AppSection.guide => l.epg,
      AppSection.favorites => l.favorites,
      AppSection.settings => l.settings,
    };
  }

  XpSymbol _icon(AppSection section) => switch (section) {
    AppSection.home => XpSymbol.home,
    AppSection.channels => XpSymbol.channels,
    AppSection.guide => XpSymbol.guide,
    AppSection.favorites => XpSymbol.heart,
    AppSection.settings => XpSymbol.settings,
  };
  void _select(AppSection section) => setState(() {
    _section = section;
    _selected = null;
  });
  Future<void> _back() async {
    final focus = FocusManager.instance.primaryFocus;
    if (context.read<GlobalProvider>().isTV &&
        focus?.context?.findAncestorStateOfType<EditableTextState>() != null) {
      focus!.unfocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      return;
    }
    if (_selected != null) {
      setState(() => _selected = null);
      return;
    }
    if (_section != AppSection.home) {
      _select(AppSection.home);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => XpConfirmDialog(
        title: AppLocalizations.of(context)!.exitAppTitle,
        confirmLabel: AppLocalizations.of(context)!.exit,
        child: Text(AppLocalizations.of(context)!.exitAppMessage),
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
    if (confirmed == true) await SystemNavigator.pop();
  }

  void _resumeMini() {
    final mini = context.read<MiniPlayerController>();
    if (!mini.hasMini || mini.channel == null) return;
    final channel = mini.channel!, favorites = mini.favorites;
    mini.take();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PlayerScreen(channel: channel, favoriteChannels: favorites),
      ),
    );
  }

  Future<void> _chooseSource() async {
    final l = AppLocalizations.of(context)!;
    final media = context.read<MediaProvider>();
    final id = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.selectPlaylist),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, -1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l.favoritesChannelCount(media.favoriteChannels.length),
              ),
            ),
          ),
          for (final list in media.playlists)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, list.id),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(list.name),
              ),
            ),
        ],
      ),
    );
    if (id != null) {
      await media.updateCurrentPlaylist(id);
      if (mounted) {
        _search.text = media.searchQuery;
        setState(() => _selected = null);
      }
    }
  }

  Future<void> _configureEpg() async {
    final media = context.read<MediaProvider>();
    if (media.currentPlaylistId == -1) {
      await Navigator.pushNamed(context, '/playlists');
    } else {
      await AppActions.editPlaylist(context, playlist: media.currentPlaylist);
    }
  }

  Future<void> _detail(Channel channel, bool inline) async {
    if (inline) {
      setState(() => _selected = channel);
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * .8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _channelDetail(channel),
          ),
        ),
      ),
    );
  }

  Widget _channelDetail(Channel channel) {
    final l = AppLocalizations.of(context)!;
    final media = context.watch<MediaProvider>();
    final presentation = MediaPresentation(media, now: _now, allSources: true);
    final programmes = presentation.index
        .forChannel(channel.id)
        .where((p) => p.stop.isAfter(_now))
        .take(6)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        XpChannelIdentity(channel: presentation.channel(channel)),
        const SizedBox(height: 22),
        XpButton(
          label: l.watchChannelLive,
          icon: XpSymbol.play,
          onPressed: () => AppActions.play(context, channel),
        ),
        const SizedBox(height: 18),
        Text(
          l.playbackSourceCount(channel.source.length),
          style: TextStyle(color: XpTheme.of(context).palette.muted),
        ),
        const SizedBox(height: 22),
        if (programmes.isEmpty)
          XpNotice(
            title: l.noCurrentProgramme,
            description: l.channelStillAvailable,
          )
        else
          ...programmes.map(
            (programme) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                height: 110,
                child: XpProgrammeBlock(
                  programme: presentProgramme(programme),
                  now: _now,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final media = context.watch<MediaProvider>();
    final isTv = context.watch<GlobalProvider>().isTV;
    final p = XpTheme.of(context).palette;
    return LayoutBuilder(
      builder: (context, box) {
        final layout = AppLayout(
          width: box.maxWidth,
          isTv: isTv,
          platform: Theme.of(context).platform,
        );
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.contextMenu): _resumeMini,
            const SingleActivator(LogicalKeyboardKey.escape): _back,
          },
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _back();
            },
            child: Scaffold(
              backgroundColor: p.background,
              bottomNavigationBar: layout.useBottomNavigation
                  ? SafeArea(
                      top: false,
                      child: Container(
                        decoration: BoxDecoration(
                          color: p.background,
                          border: Border(top: BorderSide(color: p.border)),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            for (final section in AppSection.values)
                              Expanded(
                                child: XpNavigationItem(
                                  key: ValueKey('nav-${section.name}'),
                                  label: section == AppSection.channels
                                      ? l.channelsShort
                                      : _label(section),
                                  icon: _icon(section),
                                  selected: _section == section,
                                  collapsed: true,
                                  onPressed: () => _select(section),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : null,
              body: SafeArea(
                bottom: !layout.useBottomNavigation,
                child: Row(
                  children: [
                    if (!layout.useBottomNavigation)
                      SizedBox(
                        width: layout.navigationWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(right: BorderSide(color: p.border)),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: layout.expandedNavigation ? 18 : 6,
                            vertical: 28,
                          ),
                          child: FocusTraversalGroup(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 34),
                                    child: Text(
                                      layout.expandedNavigation
                                          ? 'XPlayer'
                                          : 'XP',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isTv ? 34 : 28,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ),
                                  for (final section in AppSection.values)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: XpNavigationItem(
                                        key: ValueKey('nav-${section.name}'),
                                        autofocus:
                                            isTv && section == AppSection.home,
                                        label:
                                            !layout.expandedNavigation &&
                                                section == AppSection.channels
                                            ? l.channelsShort
                                            : _label(section),
                                        icon: _icon(section),
                                        selected: _section == section,
                                        collapsed: !layout.expandedNavigation,
                                        onPressed: () => _select(section),
                                      ),
                                    ),
                                  const SizedBox(height: 28),
                                  XpNavigationItem(
                                    label: l.playlist,
                                    icon: XpSymbol.sources,
                                    collapsed: !layout.expandedNavigation,
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/playlists',
                                    ),
                                  ),
                                  if (layout.expandedNavigation)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 24,
                                        left: 14,
                                      ),
                                      child: Text(
                                        '${l.playlistChannelCount(media.channels.length)} · ${isTv ? l.remoteModeLabel : l.homeDiscoveryLabel}',
                                        style: TextStyle(
                                          color: p.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: layout.padding,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!layout.compact)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 5,
                                          ),
                                          child: Text(
                                            'XPLAYER / ${_label(_section)}',
                                            style: TextStyle(
                                              color: p.quiet,
                                              fontSize: 10,
                                              letterSpacing: 1.8,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        _label(_section),
                                        style: TextStyle(
                                          fontSize: isTv ? 32 : 24,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                XpIconButton(
                                  icon: XpSymbol.sources,
                                  label: l.managePlaylists,
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    '/playlists',
                                  ),
                                ),
                                XpIconButton(
                                  icon: XpSymbol.plus,
                                  label: l.addPlaylist,
                                  onPressed: () =>
                                      AppActions.editPlaylist(context),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: p.border),
                          Expanded(
                            child: PageStorage(
                              bucket: _storage,
                              child: IndexedStack(
                                index: _section.index,
                                children: [
                                  _overview(media, layout),
                                  _channels(media, layout),
                                  EpgScreen(
                                    embedded: true,
                                    onWatchChannels: () =>
                                        _select(AppSection.channels),
                                    onConfigure: _configureEpg,
                                  ),
                                  _channels(media, layout, favorites: true),
                                  const SettingsScreen(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _empty(MediaProvider media, {bool favorites = false}) {
    final l = AppLocalizations.of(context)!;
    if (media.isRefreshingChannels && media.channels.isEmpty && !favorites) {
      return XpEmptyState(
        title: l.loadingChannels,
        description: l.loadingPlaylistHint,
        icon: XpSymbol.channels,
        loading: true,
        secondaryLabel: l.managePlaylists,
        onSecondary: () => Navigator.pushNamed(context, '/playlists'),
      );
    }
    if (favorites) {
      return XpEmptyState(
        title: l.noFavoritesTitle,
        description: l.noFavoritesHint,
        icon: XpSymbol.heart,
        actionLabel: l.browseChannels,
        onAction: () => _select(AppSection.channels),
      );
    }
    final error = media.playlistError(media.currentPlaylistId);
    return XpEmptyState(
      title: error != null ? l.openPlaylistFailed : l.addChannelSource,
      description: error != null
          ? l.openPlaylistFailedHint
          : l.addChannelSourceHint,
      icon: XpSymbol.sources,
      actionLabel: error != null ? l.retryLoading : l.addPlaylist,
      onAction: error != null
          ? media.refreshChannels
          : () => AppActions.editPlaylist(context),
      secondaryLabel: !kStoreBuild
          ? l.homeRecommendedSources
          : l.managePlaylists,
      onSecondary: !kStoreBuild
          ? () => showDialog(
              context: context,
              builder: (_) => const PresetSourceDialog(),
            )
          : () => Navigator.pushNamed(context, '/playlists'),
    );
  }

  Widget _card(
    Channel channel,
    MediaPresentation presentation, {
    bool inline = false,
  }) => XpChannelCard(
    key: ValueKey('channel-${channel.id}'),
    channel: presentation.channel(channel),
    now: _now,
    epgStatus: presentation.channelStatus(channel),
    favourite: presentation.media.favoriteChannels.any(
      (c) => c.id == channel.id,
    ),
    onFavouriteChanged: (_) => AppActions.favorite(context, channel),
    onPlay: () => AppActions.play(context, channel),
    onDetails: () => _detail(channel, inline),
  );
  Widget _overview(MediaProvider media, AppLayout layout) {
    final l = AppLocalizations.of(context)!;
    if (media.channels.isEmpty) return _empty(media);
    final presentation = MediaPresentation(media, now: _now);
    final ids = media.channels.map((c) => c.id).toSet();
    final recent = media.recentChannels
        .where((c) => ids.contains(c.id))
        .toList();
    final featured =
        recent.firstOrNull ??
        media.channels.firstWhere(
          (c) => presentation.index.current(c.id, _now) != null,
          orElse: () => media.channels.firstWhere(
            (c) => c.logo?.isNotEmpty ?? false,
            orElse: () => media.channels.first,
          ),
        );
    final favourites = media.favoriteChannels
        .where((c) => ids.contains(c.id))
        .toList();
    return CustomScrollView(
      key: const PageStorageKey('home-scroll'),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(layout.padding),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      media.currentPlaylist.name,
                      style: TextStyle(
                        color: XpTheme.of(context).palette.muted,
                      ),
                    ),
                  ),
                  XpButton(
                    label: l.switchPlaylist,
                    onPressed: _chooseSource,
                    variant: XpButtonVariant.ghost,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              XpFeaturedChannel(
                compact: layout.isTv && MediaQuery.sizeOf(context).height < 700,
                channel: presentation.channel(featured),
                now: _now,
                epgStatus: presentation.channelStatus(featured),
                favourite: media.favoriteChannels.any(
                  (c) => c.id == featured.id,
                ),
                onFavouriteChanged: (_) =>
                    AppActions.favorite(context, featured),
                onPlay: () => AppActions.play(context, featured),
                onDetails: () => _detail(featured, false),
              ),
              const SizedBox(height: 28),
              ValueListenableBuilder<bool>(
                valueListenable: showRecentModule,
                builder: (_, show, __) => !show || recent.isEmpty
                    ? const SizedBox.shrink()
                    : _channelRow(recent, presentation, layout, isRecent: true),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: showFavoritesRow,
                builder: (_, show, __) => !show || favourites.isEmpty
                    ? const SizedBox.shrink()
                    : _channelRow(
                        favourites,
                        presentation,
                        layout,
                        isRecent: false,
                      ),
              ),
              XpSectionHeading(
                title: l.liveChannels,
                actionLabel: l.allChannels,
                onAction: () => _select(AppSection.channels),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        _grid(
          media.channels.take(layout.device == XpDevice.phone ? 4 : 8).toList(),
          presentation,
          layout,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  Widget _channelRow(
    List<Channel> channels,
    MediaPresentation presentation,
    AppLayout layout, {
    required bool isRecent,
  }) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        XpSectionHeading(
          title: isRecent ? l.recentlyPlayed : l.favoriteChannels,
          actionLabel: isRecent ? l.clearHistory : l.allFavorites,
          onAction: () async {
            if (!isRecent) {
              _select(AppSection.favorites);
              return;
            }
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => XpConfirmDialog(
                title: l.clearPlayHistoryTitle,
                confirmLabel: l.confirmClearHistory,
                child: Text(l.clearHistoryHint),
                onConfirm: () => Navigator.pop(ctx, true),
                onCancel: () => Navigator.pop(ctx, false),
              ),
            );
            if (confirmed == true) await presentation.media.clearRecent();
          },
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          key: PageStorageKey(
            isRecent ? 'channel-row-recent' : 'channel-row-favorites',
          ),
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final channel in channels.take(12))
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: layout.isTv ? 360 : 270,
                    child: _card(channel, presentation),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _channels(
    MediaProvider media,
    AppLayout layout, {
    bool favorites = false,
  }) {
    final l = AppLocalizations.of(context)!;
    final presentation = MediaPresentation(
      media,
      now: _now,
      allSources: favorites,
    );
    final filtered = favorites
        ? filterChannels(media.favoriteChannels, query: _favoritesSearch.text)
        : media.filteredChannels;
    final source = favorites ? media.favoriteChannels : media.channels;
    if (source.isEmpty) return _empty(media, favorites: favorites);
    return LayoutBuilder(
      builder: (context, box) {
        final inline = !layout.isTv && box.maxWidth >= 1100;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CustomScrollView(
                key: PageStorageKey(
                  favorites ? 'favorites-scroll' : 'channels-scroll',
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.all(layout.padding),
                    sliver: SliverList.list(
                      children: [
                        if (!favorites)
                          Row(
                            children: [
                              Expanded(child: Text(media.currentPlaylist.name)),
                              XpButton(
                                label: l.switchPlaylist,
                                onPressed: _chooseSource,
                                variant: XpButtonVariant.ghost,
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        XpSearchField(
                          controller: favorites ? _favoritesSearch : _search,
                          hint: favorites
                              ? l.searchFavorites
                              : l.searchChannelDetails,
                          onChanged: (value) {
                            if (favorites) {
                              setState(() {});
                            } else {
                              media.setSearchQuery(value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        if (!favorites)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: XpChip(
                                    label: l.allGroups,
                                    count: media.channels.length,
                                    selected: media.selectedGroup == null,
                                    onPressed: () =>
                                        media.setSelectedGroup(null),
                                  ),
                                ),
                                for (final group in media.availableGroups)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: XpChip(
                                      label: group,
                                      selected: media.selectedGroup == group,
                                      onPressed: () =>
                                          media.setSelectedGroup(group),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(l.playlistChannelCount(filtered.length)),
                            if (!favorites) ...[
                              XpIconButton(
                                icon: XpSymbol.sync,
                                label: l.refreshChannels,
                                onPressed: media.isRefreshingChannels
                                    ? null
                                    : media.refreshChannels,
                              ),
                              XpButton(
                                label: media.isTesting
                                    ? l.cancelChannelTest(
                                        media.testProgressText,
                                      )
                                    : l.channelTest,
                                onPressed: media.isTesting
                                    ? media.cancelTest
                                    : () async {
                                        try {
                                          await media.testAllChannels();
                                        } catch (_) {
                                          showToast(l.channelTestFailed);
                                        }
                                      },
                                variant: XpButtonVariant.ghost,
                              ),
                              if (media.hasTestResults)
                                XpChip(
                                  label: l.hideUnavailableChannels,
                                  selected: media.hideUnplayable,
                                  onPressed: () => media.setHideUnplayable(
                                    !media.hideUnplayable,
                                  ),
                                ),
                              XpIconButton(
                                icon: XpSymbol.settings,
                                label: l.channelDisplaySize,
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => const ChannelSizeDialog(),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (media.isRefreshingChannels && !favorites)
                          XpNotice(
                            title: l.refreshingChannels,
                            description: l.refreshingChannelsHint,
                            loading: true,
                          ),
                        if (media.playlistError(media.currentPlaylistId) !=
                                null &&
                            !favorites)
                          XpNotice(
                            title: l.playlistUpdateFailed,
                            description: l.playlistUpdateFailedHint,
                            tone: XpTone.warning,
                            actionLabel: l.retryPlaylistUpdate,
                            onAction: media.refreshChannels,
                          ),
                      ],
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: XpEmptyState(
                        title: l.noMatchingChannels,
                        description: l.noMatchingChannelsHint,
                        icon: XpSymbol.search,
                        actionLabel: l.clearFilters,
                        onAction: () {
                          if (favorites) {
                            setState(_favoritesSearch.clear);
                          } else {
                            _search.clear();
                            media.setSearchQuery('');
                            media.setSelectedGroup(null);
                          }
                        },
                      ),
                    )
                  else
                    _grid(filtered, presentation, layout, inline: inline),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            ),
            if (inline && _selected != null)
              SizedBox(
                width: 310,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: XpTheme.of(context).palette.border,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: XpIconButton(
                            icon: XpSymbol.close,
                            label: l.closeProgrammeDetails,
                            onPressed: () => setState(() => _selected = null),
                          ),
                        ),
                        _channelDetail(_selected!),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _grid(
    List<Channel> channels,
    MediaPresentation presentation,
    AppLayout layout, {
    bool inline = false,
  }) => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: layout.padding),
    sliver: SliverLayoutBuilder(
      builder: (context, box) {
        final columns = layout.channelColumns(
          box.crossAxisExtent,
          sizeLevel: presentation.media.gridSizeLevel,
        );
        // 一行按实际内容确定高度；无 EPG 不再预留时间、进度条的固定空间。
        return SliverList.builder(
          itemCount: (channels.length / columns).ceil(),
          itemBuilder: (_, row) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var column = 0; column < columns; column++) ...[
                  if (column > 0) const SizedBox(width: 16),
                  Expanded(
                    child: row * columns + column < channels.length
                        ? _card(
                            channels[row * columns + column],
                            presentation,
                            inline: inline,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}
