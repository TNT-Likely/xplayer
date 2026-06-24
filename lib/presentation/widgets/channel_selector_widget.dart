import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/utils/channel_filter.dart';
import 'package:xplayer/utils/epg_metrics.dart';
import 'package:xplayer/utils/playlist_util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

const String kAllGroups = '全部';
const double _kRowH = 64.0;

/// 响应式频道选择器:宽屏=分组|频道(行内正在)|焦点台节目单 三栏;
/// 窄屏=分组chips + 频道列表(行内正在)+ 行尾 ▸ 弹该台节目单。
/// 打开时把 D-pad 焦点落到当前播放频道(修电视上焦点错位的 bug)。
class ChannelSelectorWidget extends StatefulWidget {
  final Channel currentChannel;
  final ValueChanged<Channel> onSelected; // 切台(关闭由外层负责)

  const ChannelSelectorWidget({
    super.key,
    required this.currentChannel,
    required this.onSelected,
  });

  @override
  State<ChannelSelectorWidget> createState() => _ChannelSelectorWidgetState();
}

class _ChannelSelectorWidgetState extends State<ChannelSelectorWidget> {
  String _group = kAllGroups;
  late Channel _focused; // 宽屏右栏跟随的台
  final ScrollController _scroll = ScrollController();
  final Map<String, FocusNode> _nodes = {}; // 按频道 id 稳定持有,避免重建时 dispose 焦点中的 node

  FocusNode _nodeFor(String id) => _nodes.putIfAbsent(id, () => FocusNode());

  @override
  void initState() {
    super.initState();
    _focused = widget.currentChannel;
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCurrent());
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  List<Channel> _channelsFor(MediaProvider mp) => _group == kAllGroups
      ? mp.channels
      : filterChannels(mp.channels, group: _group);

  /// 滚到当前台(使其 build,FocusNode 才能附着),下一帧再请求焦点。
  void _focusCurrent() {
    if (!mounted) return;
    final mp = Provider.of<MediaProvider>(context, listen: false);
    final list = _channelsFor(mp);
    final idx = list.indexWhere((c) => c.id == widget.currentChannel.id);
    if (idx < 0) return;
    if (_scroll.hasClients) {
      final target = (idx * _kRowH - 120)
          .clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.jumpTo(target);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodeFor(widget.currentChannel.id).requestFocus();
    });
  }

  void _onGroup(String g) {
    setState(() => _group = g);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCurrent());
  }

  void _showSheet(Channel c, MediaProvider mp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 24, 24, 24),
      builder: (_) => SizedBox(
        height: 340,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                c.name.isNotEmpty ? c.name : c.id,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: _NowNextList(channel: c, programmes: mp.programmes)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mp = Provider.of<MediaProvider>(context);
    final groups = [kAllGroups, ...distinctGroups(mp.channels)];
    final channels = _channelsFor(mp);
    final wide = MediaQuery.of(context).size.width >= 720;

    final channelList = ListView.builder(
      controller: _scroll,
      itemExtent: _kRowH,
      itemCount: channels.length,
      itemBuilder: (_, i) {
        final c = channels[i];
        return _ChannelRow(
          channel: c,
          selected: c.id == widget.currentChannel.id,
          focused: c.id == _focused.id,
          focusNode: _nodeFor(c.id),
          programmes: mp.programmes,
          onFocusChange: (has) {
            if (has && _focused.id != c.id) setState(() => _focused = c);
          },
          onInfoTap: wide ? null : () => _showSheet(c, mp),
          onTap: () => widget.onSelected(c),
        );
      },
    );

    final Widget body = wide
        ? Row(
            children: [
              SizedBox(
                width: 140,
                child: _GroupList(
                    groups: groups, selected: _group, onSelect: _onGroup),
              ),
              const VerticalDivider(width: 1, color: Colors.white24),
              Expanded(flex: 3, child: channelList),
              const VerticalDivider(width: 1, color: Colors.white24),
              Expanded(
                flex: 2,
                child:
                    _NowNextList(channel: _focused, programmes: mp.programmes),
              ),
            ],
          )
        : Column(
            children: [
              _GroupChips(groups: groups, selected: _group, onSelect: _onGroup),
              const Divider(height: 1, color: Colors.white24),
              Expanded(child: channelList),
            ],
          );
    // InkWell 需要 Material 祖先;showGeneralDialog 内容没有,故包一层透明 Material。
    // SafeArea:窄屏避免顶部 chips 被状态栏遮挡(宽屏/电视无状态栏时无副作用)。
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(child: body),
    );
  }
}

/// 单个频道行:台标 + 名 + 行内「正在」。用 InkWell(focusNode) 以便遥控器 SELECT 触发 onTap。
class _ChannelRow extends StatelessWidget {
  final Channel channel;
  final bool selected; // 当前播放台
  final bool focused; // D-pad 焦点(由父 _focused 决定高亮)
  final FocusNode focusNode;
  final List<Programme> programmes;
  final VoidCallback onTap;
  final VoidCallback? onInfoTap; // 窄屏 ▸;宽屏传 null
  final ValueChanged<bool> onFocusChange;

  const _ChannelRow({
    required this.channel,
    required this.selected,
    required this.focused,
    required this.focusNode,
    required this.programmes,
    required this.onTap,
    required this.onFocusChange,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).primaryColor;
    final cur = PlaylistUtil.findCurrentAndNextProgramme(
            programmes, channel.id, DateTime.now())
        .$2;
    final bg = selected
        ? theme.withOpacity(0.85)
        : (focused ? theme.withOpacity(0.30) : Colors.transparent);
    return InkWell(
      focusNode: focusNode,
      onTap: onTap,
      onFocusChange: onFocusChange,
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: (channel.logo != null && channel.logo!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: channel.logo!,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(Icons.live_tv,
                          color: Colors.white54, size: 18),
                    )
                  : const Icon(Icons.live_tv, color: Colors.white54, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name.isNotEmpty ? channel.name : channel.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (cur != null)
                    Text(
                      AppLocalizations.of(context)!.nowPlaying(cur.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (onInfoTap != null)
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white54),
                onPressed: onInfoTap,
              ),
          ],
        ),
      ),
    );
  }
}

/// 宽屏左侧分组栏。
class _GroupList extends StatelessWidget {
  final List<String> groups;
  final String selected;
  final ValueChanged<String> onSelect;
  const _GroupList(
      {required this.groups, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).primaryColor;
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (_, i) {
        final g = groups[i];
        final sel = g == selected;
        return InkWell(
          onTap: () => onSelect(g),
          child: Container(
            color: sel ? theme.withOpacity(0.6) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text(
              g == kAllGroups ? AppLocalizations.of(context)!.allGroups : g,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        );
      },
    );
  }
}

/// 窄屏顶部分组 chips(横滑)。
class _GroupChips extends StatelessWidget {
  final List<String> groups;
  final String selected;
  final ValueChanged<String> onSelect;
  const _GroupChips(
      {required this.groups, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).primaryColor;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final g = groups[i];
          final sel = g == selected;
          return InkWell(
            onTap: () => onSelect(g),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel
                    ? theme.withOpacity(0.85)
                    : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                  g == kAllGroups
                      ? AppLocalizations.of(context)!.allGroups
                      : g,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          );
        },
      ),
    );
  }
}

/// 某频道「正在 + 接下来」列表(宽屏右栏 与 窄屏 bottom sheet 共用)。
class _NowNextList extends StatelessWidget {
  final Channel channel;
  final List<Programme> programmes;
  const _NowNextList({required this.channel, required this.programmes});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final items = upcomingProgrammes(programmes, channel.id, now);
    if (items.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noProgramme,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final p = items[i];
        final live = isLive(p, now);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (live)
                const Padding(
                  padding: EdgeInsets.only(right: 6, top: 2),
                  child: Icon(Icons.play_arrow,
                      color: Colors.redAccent, size: 16),
                ),
              Expanded(
                child: Text(
                  '${DateFormat('HH:mm').format(p.start.toLocal())}  ${p.title}',
                  style: TextStyle(
                      color: live ? Colors.white : Colors.white70,
                      fontWeight: live ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
