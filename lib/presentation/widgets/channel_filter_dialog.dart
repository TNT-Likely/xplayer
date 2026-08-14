import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/shared/components/x_dialog_shell.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/shared/components/x_icon_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer/utils/channel_filter.dart';

/// 搜索弹窗(右上角搜索图标打开)。改动即时作用于首页网格。
class ChannelSearchDialog extends StatefulWidget {
  const ChannelSearchDialog({super.key});

  @override
  State<ChannelSearchDialog> createState() => _ChannelSearchDialogState();
}

class _ChannelSearchDialogState extends State<ChannelSearchDialog> {
  late final TextEditingController _controller;
  final FocusNode _searchFocus = FocusNode(debugLabel: 'channelSearchDialog');

  @override
  void initState() {
    super.initState();
    final media = Provider.of<MediaProvider>(context, listen: false);
    _controller = TextEditingController(text: media.searchQuery);
    // TV:单行搜索框吞上/下方向键,这里拦截并移出焦点,避免"进去出不来"
    _searchFocus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          return node.focusInDirection(TraversalDirection.down)
              ? KeyEventResult.handled
              : KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          return node.focusInDirection(TraversalDirection.up)
              ? KeyEventResult.handled
              : KeyEventResult.ignored;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final media = Provider.of<MediaProvider>(context);

    return XDialogShell(
      title: l.search,
      child: TextField(
        controller: _controller,
        focusNode: _searchFocus,
        autofocus: true,
        style: const TextStyle(color: AppTokens.textPrimary),
        cursorColor: AppTokens.brand,
        textInputAction: TextInputAction.search,
        onChanged: media.setSearchQuery,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon:
              const Icon(Icons.search, color: AppTokens.iconSecondary),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear,
                      color: AppTokens.iconSecondary),
                  onPressed: () {
                    _controller.clear();
                    media.setSearchQuery('');
                  },
                ),
          hintText: l.searchChannelsHint,
          hintStyle: const TextStyle(color: AppTokens.textTertiary),
          filled: true,
          fillColor: AppTokens.fillDefault,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// 分组弹窗(右上角分组图标打开)。
class ChannelGroupDialog extends StatelessWidget {
  const ChannelGroupDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final media = Provider.of<MediaProvider>(context);
    final selected = media.selectedGroup;
    final all = media.channels;

    // 计数是选择依据 —— 「新闻 47」比光一个「新闻」有用得多,
    // 用户据此判断值不值得点进去。
    final counts = groupCounts(all);
    final ordered = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final uncategorized = uncategorizedCount(all);

    // 选择类弹窗不给「确定」—— 点一下就是选中,再要求确认是多余一步。
    return XPickerDialog(
      title: l.groups,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.s16),
        child: Wrap(
          spacing: AppDimens.s8,
          runSpacing: AppDimens.s8,
          children: [
            _chip(context, l.allGroups, all.length,
                selected == null || selected.isEmpty,
                () => media.setSelectedGroup(null)),
            for (final e in ordered)
              _chip(context, e.key, e.value, selected == e.key,
                  () => media.setSelectedGroup(e.key)),
            // 未分类排最后 —— 它不是一个真实分类,只是「没归到任何组」。
            if (uncategorized > 0)
              _chip(context, '未分类', uncategorized, false, () {}),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, int count, bool active,
      VoidCallback onTap) {
    return XTextButton(
      text: '$label  $count',
      size: XTextButtonSize.flexible,
      type: active ? XTextButtonType.primary : XTextButtonType.defaultType,
      onPressed: () {
        onTap();
        Navigator.of(context).pop();
      },
    );
  }
}

/// 显示大小弹窗(右上角大小图标打开)。
class ChannelSizeDialog extends StatelessWidget {
  const ChannelSizeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final media = Provider.of<MediaProvider>(context);
    final level = media.gridSizeLevel; // 0 最大 .. 4 最小

    return XDialogShell(
      title: l.itemSize,
      child: Row(
        children: [
          Text(l.itemSize,
              style: const TextStyle(color: AppTokens.textSecondary)),
          const Spacer(),
          XIconButton(
            icon: Icons.zoom_out, // 更小(列更多)
            onPressed:
                level >= 4 ? null : () => media.setGridSizeLevel(level + 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.s8),
            child: Text('${5 - level} / 5',
                style: const TextStyle(color: AppTokens.textPrimary)),
          ),
          XIconButton(
            icon: Icons.zoom_in, // 更大(列更少)
            onPressed:
                level <= 0 ? null : () => media.setGridSizeLevel(level - 1),
          ),
        ],
      ),
    );
  }
}

/// 「启动时自动更新」弹窗:分别开关 刷新频道 / 刷新节目单。沿用统一弹窗外壳与设计 token。
class AutoRefreshDialog extends StatelessWidget {
  const AutoRefreshDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return XDialogShell(
      title: l.autoRefreshOnLaunch,
      child: Consumer<MediaProvider>(
        builder: (context, mp, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row(l.refreshChannels, mp.autoRefreshChannels,
                mp.setAutoRefreshChannels),
            const SizedBox(height: AppDimens.s8),
            _row(l.refreshProgrammes, mp.autoRefreshProgrammes,
                mp.setAutoRefreshProgrammes),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(color: AppTokens.textPrimary)),
        ),
        Switch(
          value: value,
          activeColor: AppTokens.brand,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
