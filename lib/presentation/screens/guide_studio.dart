import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/services/guide_catalog.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer_storekit/xplayer_storekit.dart';
import 'pro_membership.dart';

class GuideStudioScreen extends StatelessWidget {
  const GuideStudioScreen({super.key, this.startWithShows = false});
  final bool startWithShows;

  @override
  Widget build(BuildContext context) {
    final access = context.watch<ProMembership>();
    if (!access.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!access.canUsePro) return const ProMembershipScreen();
    return Theme(
      data: guideTheme(),
      child: _Studio(startWithShows: startWithShows),
    );
  }
}

class _Studio extends StatefulWidget {
  const _Studio({required this.startWithShows});
  final bool startWithShows;
  @override
  State<_Studio> createState() => _StudioState();
}

class _StudioState extends State<_Studio> {
  static const _prefsKey = 'guide_studio_followed_titles';
  final _channels = TextEditingController();
  final _shows = TextEditingController();
  List<String> _followed = [];
  GuideCatalog? _catalog;
  bool _working = false;
  bool _error = false;
  bool _saving = false;
  bool _loadedKeywords = false;
  late int _tab = widget.startWithShows ? 1 : 0;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    unawaited(_loadKeywords());
    unawaited(_load());
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _tab != 0) setState(() {});
    });
  }

  Future<void> _loadKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _followed = prefs.getStringList(_prefsKey) ?? [];
          _loadedKeywords = true;
        });
      }
    } catch (_) {
      if (mounted) _saveError();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (_working) return;
    final media = context.read<MediaProvider>();
    setState(() {
      _working = true;
      _error = false;
    });
    try {
      final catalog = await GuideCatalog.load(
        List.of(media.playlists),
        refresh: refresh,
      );
      if (mounted) setState(() => _catalog = catalog);
      if (refresh ||
          (media.programmes.isEmpty && media.autoRefreshProgrammes)) {
        await media.refreshProgrammes();
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _saveError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.proLocalError)),
    );
  }

  Future<void> _toggleKeyword(String keyword) async {
    final term = keyword.trim();
    if (term.isEmpty || !_loadedKeywords || _saving) return;
    setState(() => _saving = true);
    final next = [..._followed];
    final index = next.indexWhere((k) => k.toLowerCase() == term.toLowerCase());
    if (index < 0) {
      next.add(term);
    } else {
      next.removeAt(index);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setStringList(_prefsKey, next)) {
        throw StateError('write failed');
      }
      if (mounted) setState(() => _followed = next);
    } catch (_) {
      if (mounted) _saveError();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _play(GuideChannel entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          channel: entry.channel,
          favoriteChannels: context.read<MediaProvider>().favoriteChannels,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    _shows.dispose();
    _channels.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final programmes = context.select<MediaProvider, List<Programme>>(
      (m) => m.programmes,
    );
    final controller = _tab == 0 ? _channels : _shows;
    final catalog = _catalog;
    final followed = _followed.any(
      (k) => k.toLowerCase() == _shows.text.trim().toLowerCase(),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l.proStudio),
        actions: [
          IconButton(
            onPressed: _working ? null : () => _load(refresh: true),
            tooltip: l.proRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 0, label: Text(l.proChannelsTab)),
                      ButtonSegment(value: 1, label: Text(l.proShowsTab)),
                      ButtonSegment(value: 2, label: Text(l.proFollowingTab)),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (s) => setState(() => _tab = s.first),
                  ),
                ),
                if (_tab < 2)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: controller,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        labelText: _tab == 0
                            ? l.proChannelQuery
                            : l.proShowQuery,
                        border: const OutlineInputBorder(),
                        suffixIcon: controller.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).deleteButtonTooltip,
                                onPressed: () => setState(controller.clear),
                              ),
                      ),
                    ),
                  ),
                if (_tab == 1 && _shows.text.trim().isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextButton.icon(
                        onPressed: !_loadedKeywords || _saving
                            ? null
                            : () => _toggleKeyword(_shows.text),
                        icon: Icon(
                          followed
                              ? Icons.bookmark_remove_outlined
                              : Icons.bookmark_add_outlined,
                        ),
                        label: Text(followed ? l.proUnfollow : l.proFollow),
                      ),
                    ),
                  ),
                if (_tab == 2 && _followed.isNotEmpty)
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _followed.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) => InputChip(
                        label: Text(_followed[i]),
                        deleteButtonTooltipMessage: l.proUnfollow,
                        onDeleted: _saving
                            ? null
                            : () => _toggleKeyword(_followed[i]),
                      ),
                    ),
                  ),
                if (_working) const LinearProgressIndicator(),
                if (_error || catalog?.partial == true)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(l.proPartial),
                  ),
                Expanded(
                  child: catalog == null
                      ? (_working ? const SizedBox() : _empty(l.proPartial))
                      : _results(catalog, programmes, l),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
      ),
    ),
  );

  Widget _results(
    GuideCatalog catalog,
    List<Programme> programmes,
    AppLocalizations l,
  ) {
    if (_tab == 2 && _followed.isEmpty) return _empty(l.proNoFollowing);
    if (catalog.channels.isEmpty) return _empty(l.proEmptyLibrary);
    if (_tab == 0) {
      final channels = catalog.findChannels(_channels.text);
      if (channels.isEmpty) return _empty(l.proNoMatches);
      return ListView.builder(
        itemCount: channels.length,
        itemBuilder: (_, i) {
          final c = channels[i];
          return ListTile(
            title: Text(c.channel.name),
            subtitle: Text(c.playlistName),
            trailing: const Icon(Icons.play_circle_outline),
            onTap: () => _play(c),
          );
        },
      );
    }
    final now = DateTime.now();
    final shows = catalog.findShows(
      programmes,
      _tab == 2 ? _followed : [_shows.text],
      now,
    );
    if (shows.isEmpty) {
      return _empty(
        programmes.isEmpty
            ? l.proNoGuide
            : _tab == 2
            ? l.proFollowEmpty
            : l.proNoMatches,
      );
    }
    final dates = MaterialLocalizations.of(context);
    String time(DateTime t) => dates.formatTimeOfDay(
      TimeOfDay.fromDateTime(t.toLocal()),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return ListView.builder(
      itemCount: shows.length,
      itemBuilder: (_, i) {
        final p = shows[i];
        final c = catalog.byId[p.channel.toLowerCase()]!;
        final live = !p.start.isAfter(now);
        return ListTile(
          title: Text(p.title),
          subtitle: Text(
            '${c.channel.name} · ${dates.formatShortDate(p.start.toLocal())} ${time(p.start)}–${time(p.stop)}',
          ),
          trailing: live
              ? Text(l.proNow, style: TextStyle(color: AppTokens.brand))
              : const Icon(Icons.live_tv_outlined),
          onTap: () => _play(c),
        );
      },
    );
  }
}
