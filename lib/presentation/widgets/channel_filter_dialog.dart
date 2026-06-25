import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/shared/components/x_icon_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 三个独立入口共享的弹窗外壳:统一背景/标题/确定按钮。
class _FilterDialogShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _FilterDialogShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppTokens.surfacePanel,
      title:
          Text(title, style: const TextStyle(color: AppTokens.textPrimary)),
      content: SizedBox(width: 360, child: child),
      actions: [
        XTextButton(
          text: l.ok,
          type: XTextButtonType.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

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

    return _FilterDialogShell(
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
    final groups = media.availableGroups;
    final selected = media.selectedGroup;

    return _FilterDialogShell(
      title: l.groups,
      child: SingleChildScrollView(
        child: Wrap(
          spacing: AppDimens.s8,
          runSpacing: AppDimens.s8,
          children: [
            _chip(l.allGroups, selected == null || selected.isEmpty,
                () => media.setSelectedGroup(null)),
            for (final g in groups)
              _chip(g, selected == g, () => media.setSelectedGroup(g)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return XTextButton(
      text: label,
      size: XTextButtonSize.flexible,
      type: active ? XTextButtonType.primary : XTextButtonType.defaultType,
      onPressed: onTap,
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

    return _FilterDialogShell(
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
