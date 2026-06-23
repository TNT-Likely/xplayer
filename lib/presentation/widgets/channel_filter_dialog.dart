import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/shared/components/x_icon_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 搜索 / 分组 / 显示大小 弹窗（由首页右上角图标打开）。
/// 所有改动即时作用于首页网格;关闭即完成。
class ChannelFilterDialog extends StatefulWidget {
  const ChannelFilterDialog({super.key});

  @override
  State<ChannelFilterDialog> createState() => _ChannelFilterDialogState();
}

class _ChannelFilterDialogState extends State<ChannelFilterDialog> {
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
    final groups = media.availableGroups;
    final selected = media.selectedGroup;
    final level = media.gridSizeLevel; // 0 最大 .. 4 最小

    return AlertDialog(
      backgroundColor: AppTokens.surfacePanel,
      title: Text(l.filterTitle,
          style: const TextStyle(color: AppTokens.textPrimary)),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 搜索
              TextField(
                controller: _controller,
                focusNode: _searchFocus,
                style: const TextStyle(color: AppTokens.textPrimary),
                cursorColor: AppTokens.brand,
                textInputAction: TextInputAction.search,
                onChanged: media.setSearchQuery,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search,
                      color: AppTokens.iconSecondary),
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
              // 分组
              if (groups.isNotEmpty) ...[
                const SizedBox(height: AppDimens.s12),
                Wrap(
                  spacing: AppDimens.s8,
                  runSpacing: AppDimens.s8,
                  children: [
                    _chip(l.allGroups, selected == null || selected.isEmpty,
                        () => media.setSelectedGroup(null)),
                    for (final g in groups)
                      _chip(g, selected == g, () => media.setSelectedGroup(g)),
                  ],
                ),
              ],
              // 显示大小
              const SizedBox(height: AppDimens.s16),
              Row(
                children: [
                  Text(l.itemSize,
                      style: const TextStyle(color: AppTokens.textSecondary)),
                  const Spacer(),
                  XIconButton(
                    icon: Icons.zoom_out, // 更小(列更多)
                    onPressed: level >= 4
                        ? null
                        : () => media.setGridSizeLevel(level + 1),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppDimens.s8),
                    child: Text('${5 - level} / 5',
                        style: const TextStyle(color: AppTokens.textPrimary)),
                  ),
                  XIconButton(
                    icon: Icons.zoom_in, // 更大(列更少)
                    onPressed: level <= 0
                        ? null
                        : () => media.setGridSizeLevel(level - 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        XTextButton(
          text: l.ok,
          type: XTextButtonType.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
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
