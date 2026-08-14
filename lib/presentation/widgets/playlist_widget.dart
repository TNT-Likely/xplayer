import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/components/empty_state.dart';
import 'package:xplayer/presentation/widgets/playlist_dialog.dart';
import 'package:xplayer/shared/components/x_dialog_shell.dart';
import 'package:xplayer/shared/components/x_icon_button.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer/utils/relative_time.dart';

class PlaylistListWidget extends StatelessWidget {
  final List<Playlist> playlists;
  final Future<void> Function(int id) onDelete;
  final Future<void> Function(Playlist playlist) onUpdate;
  final Future<void> Function() onLoadAll;
  final Future<void> Function(int id, String url) onRefresh;

  /// 空状态下的主操作。为 null 时空状态不显示按钮。
  final VoidCallback? onAdd;

  /// 注入当前时间，便于测试相对时间显示。
  final DateTime Function() clock;

  PlaylistListWidget({
    super.key,
    required this.playlists,
    required this.onDelete,
    required this.onUpdate,
    required this.onLoadAll,
    required this.onRefresh,
    this.onAdd,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  @override
  Widget build(BuildContext context) {
    final now = clock();
    final l = AppLocalizations.of(context)!;
    if (playlists.isEmpty) {
      // 商店包不内置任何源,新用户第一眼看到的就是这里。
      // 文案直说「不内置频道」——与商店定位一致,也免得用户以为加载失败。
      return EmptyState(
        icon: Icons.playlist_add_rounded,
        title: l.playlistEmptyTitle,
        message: l.playlistEmptyMessage,
        actions: [
          XTextButton(
            text: l.addPlaylist,
            type: XTextButtonType.primary,
            onPressed: onAdd,
          ),
        ],
      );
    }
    return ListView.separated(
      itemCount: playlists.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: AppTokens.line),
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final count = _channelCount(playlist);
        final stale = isStale(playlist.updatedAt, now);

        // 沿用 ListTile —— 它自带 hover / 涟漪 / 行高节奏 / 统一最小高度。
        // 曾经换成裸 Row 想自己控高度,结果把这些全丢了,明显变丑,已改回。
        //
        // subtitle 有两行,所以要 isThreeLine 告诉 ListTile 按三行分配高度;
        // 两行之间不插 SizedBox,靠 TextStyle.height 撑行距。
        return ListTile(
          style: ListTileStyle.drawer,
          isThreeLine: true,
          // 此前标题是 `3: 主源` —— 那个 id 是数据库自增主键,
          // 对用户没有任何意义,不该出现在界面上。
          title: Text(
            playlist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppTokens.textPrimary),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                playlist.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTokens.textTertiary,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              // 「多少个频道、多久没更新」是用户真正据以判断的信息。
              // 超过 7 天未更新时转琥珀色 —— 源失效不会有任何通知。
              Text(
                _summary(l, playlist, count, now),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      stale ? AppTokens.sourceSlow : AppTokens.textSecondary,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              XIconButton(
                icon: Icons.edit,
                onPressed: () => _showEditDialog(context, playlist),
              ),
              const SizedBox(width: 8),
              XIconButton(
                onPressed: () => onRefresh(playlist.id!, playlist.url),
                icon: Icons.refresh,
              ),
              const SizedBox(width: 8),
              XIconButton(
                icon: Icons.delete,
                type: XIconButtonType.danger,
                onPressed: () => _confirmRemove(context, playlist, count),
              ),
            ],
          ),
        );
      },
    );
  }

  String _summary(AppLocalizations l, Playlist p, int? count, DateTime now) {
    final parts = <String>[];
    if (count != null) parts.add(l.playlistChannelCount(count));
    final rt = relativeTime(p.updatedAt ?? p.createdAt, now);
    if (rt != null) parts.add(l.playlistUpdatedAt(_formatRelative(l, rt)));
    return parts.isEmpty ? l.playlistNeverUpdated : parts.join(' · ');
  }

  /// 把结构化的相对时间落成本地化文案。
  /// [relativeTime] 只算「几个什么单位」，措辞在这里决定。
  String _formatRelative(AppLocalizations l, RelativeTime rt) {
    switch (rt.unit) {
      case TimeUnit.justNow:
        return l.timeJustNow;
      case TimeUnit.minutes:
        return l.timeMinutesAgo(rt.value);
      case TimeUnit.hours:
        return l.timeHoursAgo(rt.value);
      case TimeUnit.days:
        return l.timeDaysAgo(rt.value);
      case TimeUnit.months:
        return l.timeMonthsAgo(rt.value);
      case TimeUnit.years:
        return l.timeYearsAgo(rt.value);
    }
  }

  /// 频道数。缓存已迁到文件存储后 [Playlist.channels] 通常为空，
  /// 此时返回 null——宁可不显示，也不显示一个 0 误导用户以为源是空的。
  int? _channelCount(Playlist p) {
    final raw = p.channels;
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.length;
      if (decoded is Map && decoded['items'] is List) {
        return (decoded['items'] as List).length;
      }
    } catch (_) {
      // 缓存格式异常时同样不显示,不因为一个计数把页面搞崩。
    }
    return null;
  }

  void _confirmRemove(BuildContext context, Playlist p, int? count) {
    final l = AppLocalizations.of(context)!;
    // 说清具体后果,而不是「确定要删除吗?此操作不可撤销」这种空话。
    // 拿得到频道数就报数,拿不到就退回泛化说法,不编造数字。
    XConfirmDialog.show(
      context,
      XConfirmDialog(
        title: l.playlistRemoveTitle(p.name),
        description: count != null
            ? l.playlistRemoveBodyWithCount(count)
            : l.playlistRemoveBody,
        actionLabel: l.remove,
        onAction: () => onDelete(p.id!),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Playlist playlist) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PlaylistDialog(
          isNew: false,
          initialPlaylist: playlist,
          onSuccess: (Playlist updated) async {
            await onUpdate(updated);
            await onLoadAll();
          },
        );
      },
    );
  }
}
