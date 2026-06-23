import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 频道筛选条：搜索框 + 横向分组 chips。
///
/// - 搜索框为原生可聚焦 TextField，TV 上可被手机「远程输入」直接打字（沿用既有机制）。
/// - 分组 chips 基于 [XTextButton]（TV 焦点封装），靠默认方向焦点遍历在 D-pad 下移动。
class ChannelFilterBar extends StatefulWidget {
  const ChannelFilterBar({super.key});

  @override
  State<ChannelFilterBar> createState() => _ChannelFilterBarState();
}

class _ChannelFilterBarState extends State<ChannelFilterBar> {
  late final TextEditingController _controller;
  final FocusNode _searchFocus = FocusNode(debugLabel: 'channelSearch');

  @override
  void initState() {
    super.initState();
    final media = Provider.of<MediaProvider>(context, listen: false);
    _controller = TextEditingController(text: media.searchQuery);
    // TV 遥控:单行搜索框会吞掉上/下方向键,导致"焦点进去出不来"。
    // 聚焦搜索框时拦截上/下键,把焦点移出到上方(AppBar)或下方(分组 chips / 频道网格);
    // 左/右键不拦截,仍用于文本光标移动。
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

    // 外部清空(如切换播放列表 _resetFilters)后，让输入框跟随。
    // 用 post-frame 回调，避免在 build 期间修改 controller 触发 markNeedsBuild。
    if (media.searchQuery.isEmpty && _controller.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _controller.text.isNotEmpty &&
            Provider.of<MediaProvider>(context, listen: false)
                .searchQuery
                .isEmpty) {
          _controller.clear();
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.s8, AppDimens.s8, AppDimens.s8, AppDimens.s4),
          child: TextField(
            controller: _controller,
            focusNode: _searchFocus,
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
        ),
        if (groups.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.s8),
              children: [
                _chip(l.allGroups, selected == null || selected.isEmpty,
                    () => media.setSelectedGroup(null)),
                for (final g in groups)
                  _chip(g, selected == g, () => media.setSelectedGroup(g)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimens.s8),
      child: Center(
        child: XTextButton(
          text: label,
          size: XTextButtonSize.flexible,
          type: active ? XTextButtonType.primary : XTextButtonType.defaultType,
          onPressed: onTap,
        ),
      ),
    );
  }
}
