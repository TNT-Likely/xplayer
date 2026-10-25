import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'icons.dart';
import 'theme.dart';

enum XpButtonVariant { primary, secondary, ghost, danger }

class XpButton extends StatelessWidget {
  const XpButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon,
      this.variant = XpButtonVariant.primary,
      this.loading = false,
      this.focusNode,
      this.autofocus = false});
  final String label;
  final VoidCallback? onPressed;
  final XpSymbol? icon;
  final XpButtonVariant variant;
  final bool loading, autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    final primary = variant == XpButtonVariant.primary;
    final danger = variant == XpButtonVariant.danger;
    final ink = primary
        ? p.accentInk
        : danger
            ? p.error
            : p.foreground;
    return Semantics(
      liveRegion: loading,
      label: loading ? '$label，处理中' : null,
      child: TextButton(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: loading ? null : onPressed,
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
              Size(theme.controlHeight, theme.controlHeight)),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(
              horizontal: theme.isTv ? 26 : 18, vertical: 10)),
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          animationDuration: theme.duration,
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.disabled) ? p.muted : ink),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return p.raised;
            if (primary) return p.accent;
            return variant == XpButtonVariant.ghost
                ? Colors.transparent
                : p.surface;
          }),
          overlayColor: WidgetStatePropertyAll(p.accent.withValues(alpha: .12)),
          side: WidgetStateProperty.resolveWith((states) => BorderSide(
                color: states.contains(WidgetState.focused)
                    ? (primary ? p.accentInk : p.accent)
                    : primary || variant == XpButtonVariant.ghost
                        ? Colors.transparent
                        : p.border,
                width: states.contains(WidgetState.focused)
                    ? (theme.isTv ? 4 : 2)
                    : 1,
              )),
          textStyle: WidgetStatePropertyAll(
              TextStyle(fontSize: theme.bodySize, fontWeight: FontWeight.w600)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (loading) ...[
            SizedBox(
                width: 17,
                height: 17,
                child: theme.reduceMotion
                    ? XpIcon(XpSymbol.sync, size: 17, color: p.muted)
                    : CircularProgressIndicator(
                        strokeWidth: 2, color: p.muted)),
            const SizedBox(width: 10),
          ] else if (icon != null) ...[
            XpIcon(icon!, color: onPressed == null ? p.muted : ink),
            const SizedBox(width: 10),
          ],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ]),
      ),
    );
  }
}

class XpIconButton extends StatelessWidget {
  const XpIconButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.onPressed,
      this.selected,
      this.focusNode});
  final XpSymbol icon;
  final String label;
  final VoidCallback? onPressed;
  final bool? selected;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    return Semantics(
      selected: selected,
      child: IconButton(
        tooltip: label,
        focusNode: focusNode,
        onPressed: onPressed,
        constraints: BoxConstraints(
            minWidth: theme.controlHeight, minHeight: theme.controlHeight),
        style: ButtonStyle(
          foregroundColor:
              WidgetStatePropertyAll(selected == true ? p.accent : p.muted),
          backgroundColor: WidgetStatePropertyAll(
              selected == true ? p.accentWash : Colors.transparent),
          side: WidgetStateProperty.resolveWith((s) => BorderSide(
                color: s.contains(WidgetState.focused)
                    ? p.accent
                    : Colors.transparent,
                width: theme.isTv ? 4 : 2,
              )),
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
        icon: XpIcon(icon,
            color: onPressed == null
                ? p.quiet
                : selected == true
                    ? p.accent
                    : p.foreground),
      ),
    );
  }
}

class XpChip extends StatelessWidget {
  const XpChip(
      {super.key,
      required this.label,
      required this.onPressed,
      this.selected = false,
      this.count});
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        child: XpButton(
          label: count == null ? label : '$label  $count',
          onPressed: onPressed,
          variant:
              selected ? XpButtonVariant.primary : XpButtonVariant.secondary,
        ),
      );
}

class XpNavigationItem extends StatelessWidget {
  const XpNavigationItem(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed,
      this.selected = false,
      this.collapsed = false,
      this.count,
      this.autofocus = false});
  final String label;
  final XpSymbol icon;
  final VoidCallback? onPressed;
  final bool selected, collapsed, autofocus;
  final int? count;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    return Semantics(
      selected: selected,
      child: TextButton(
        onPressed: onPressed,
        autofocus: autofocus,
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, theme.isTv ? 62 : 52)),
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          backgroundColor: WidgetStatePropertyAll(
              selected ? p.accentWash : Colors.transparent),
          foregroundColor:
              WidgetStatePropertyAll(selected ? p.accent : p.muted),
          side: WidgetStateProperty.resolveWith((s) => BorderSide(
              color: s.contains(WidgetState.focused)
                  ? p.accent
                  : Colors.transparent,
              width: theme.isTv ? 4 : 2)),
        ),
        child: collapsed
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                XpIcon(icon, color: selected ? p.accent : p.muted),
                const SizedBox(height: 6),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: theme.smallSize))
              ])
            : Row(children: [
                XpIcon(icon, color: selected ? p.accent : p.muted),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(label,
                        style: TextStyle(fontSize: theme.bodySize))),
                if (count != null)
                  Text('$count',
                      style:
                          TextStyle(fontSize: theme.smallSize, color: p.quiet))
              ]),
      ),
    );
  }
}

class XpTextField extends StatelessWidget {
  const XpTextField(
      {super.key,
      required this.controller,
      this.onChanged,
      this.onSubmitted,
      this.label,
      this.hint,
      this.helper,
      this.error,
      this.enabled = true,
      this.autofocus = false,
      this.focusNode,
      this.prefix,
      this.suffix,
      this.keyboardType = TextInputType.text});
  final TextEditingController controller;
  final ValueChanged<String>? onChanged, onSubmitted;
  final String? label, hint, helper, error;
  final bool enabled, autofocus;
  final FocusNode? focusNode;
  final Widget? prefix, suffix;
  final TextInputType keyboardType;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: color, width: width));
    return TextField(
      controller: controller,
      autofocus: autofocus,
      focusNode: focusNode,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      autocorrect: keyboardType != TextInputType.url,
      enableSuggestions: keyboardType != TextInputType.url,
      style: TextStyle(fontSize: theme.bodySize, color: p.foreground),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        errorText: error,
        helperMaxLines: 3,
        errorMaxLines: 3,
        hintStyle: TextStyle(color: p.muted, fontSize: theme.bodySize),
        labelStyle: TextStyle(color: p.muted, fontSize: theme.bodySize),
        helperStyle: TextStyle(color: p.muted, fontSize: theme.smallSize),
        errorStyle: TextStyle(color: p.error, fontSize: theme.smallSize),
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: p.surface,
        contentPadding: EdgeInsets.symmetric(
            horizontal: 16, vertical: theme.isTv ? 20 : 14),
        border: border(p.border),
        enabledBorder: border(p.border),
        focusedBorder: border(p.accent, 2),
        errorBorder: border(p.error),
        focusedErrorBorder: border(p.error, 2),
      ),
    );
  }
}

class XpSearchField extends StatelessWidget {
  const XpSearchField(
      {super.key,
      required this.controller,
      required this.onChanged,
      this.hint = '搜索频道、节目…',
      this.enabled = true,
      this.focusNode});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final bool enabled;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          Widget input(FocusNode? node, [ValueChanged<String>? submit]) =>
              XpTextField(
                controller: controller,
                focusNode: node,
                onSubmitted: submit,
                enabled: enabled,
                onChanged: onChanged,
                hint: hint,
                prefix: const Padding(
                    padding: EdgeInsets.all(13),
                    child: XpIcon(XpSymbol.search)),
                suffix: value.text.isEmpty
                    ? null
                    : XpIconButton(
                        icon: XpSymbol.close,
                        label: '清除搜索',
                        onPressed: enabled
                            ? () {
                                controller.clear();
                                onChanged('');
                              }
                            : null),
              );
          if (XpTheme.of(context).input == XpInputMode.directional) {
            return _DirectionalSearchField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              hint: hint,
              input: (node, submit) => input(node, submit),
            );
          }
          return input(focusNode);
        },
      );
}

/// 遥控浏览时是一个普通焦点目标；确认后才把输入交给 EditableText。
class _DirectionalSearchField extends StatefulWidget {
  const _DirectionalSearchField(
      {required this.input,
      required this.controller,
      required this.enabled,
      required this.hint,
      this.focusNode});
  final Widget Function(FocusNode, ValueChanged<String>) input;
  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final FocusNode? focusNode;
  @override
  State<_DirectionalSearchField> createState() =>
      _DirectionalSearchFieldState();
}

class _DirectionalSearchFieldState extends State<_DirectionalSearchField>
    with WidgetsBindingObserver {
  final _navigation = FocusNode(debugLabel: 'search-navigation');
  final _editor = FocusNode(debugLabel: 'search-editing');
  bool _editing = false;
  bool _keyboardVisible = false;
  FocusNode get _navigationNode => widget.focusNode ?? _navigation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navigation.dispose();
    _editor.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final visible = View.of(context).viewInsets.bottom > 0;
    if (_keyboardVisible && !visible && _editing) _finish();
    _keyboardVisible = visible;
  }

  void _begin() {
    if (_editing || !widget.enabled) return;
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_editing) return;
      _editor.requestFocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  }

  void _finish([TraversalDirection? direction]) {
    setState(() => _editing = false);
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _navigationNode.requestFocus();
      if (direction != null) _navigationNode.focusInDirection(direction);
    });
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.select) {
      if (event is KeyRepeatEvent) return KeyEventResult.handled;
      _editing ? _finish(TraversalDirection.down) : _begin();
      return KeyEventResult.handled;
    }
    if (_editing) {
      final selection = widget.controller.selection;
      if (key == LogicalKeyboardKey.arrowLeft &&
          (widget.controller.text.isEmpty ||
              (selection.isCollapsed && selection.baseOffset == 0))) {
        _finish(TraversalDirection.left);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown) {
        _finish(key == LogicalKeyboardKey.arrowUp
            ? TraversalDirection.up
            : TraversalDirection.down);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.goBack) {
        _finish();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context);
    return Focus(
      focusNode: _navigationNode,
      canRequestFocus: widget.enabled && !_editing,
      skipTraversal: _editing,
      onKeyEvent: _onKey,
      onFocusChange: (focused) {
        if (!mounted) return;
        setState(() {
          if (!focused && _editing) {
            _editing = false;
            SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  FocusManager.instance.primaryFocus is FocusScopeNode) {
                _navigationNode.requestFocus();
              }
            });
          }
        });
      },
      child: Semantics(
        button: !_editing,
        label: !_editing ? '${widget.hint}，按确认输入' : null,
        excludeSemantics: !_editing,
        child: GestureDetector(
          onTap: !_editing ? _begin : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: !_editing && _navigationNode.hasFocus
                  ? Border.all(color: theme.palette.accent, width: 2)
                  : null,
            ),
            child: ExcludeFocus(
              excluding: !_editing,
              child: IgnorePointer(
                ignoring: !_editing,
                child: widget.input(
                    _editor, (_) => _finish(TraversalDirection.down)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class XpToggleTile extends StatelessWidget {
  const XpToggleTile(
      {super.key,
      required this.title,
      required this.value,
      required this.onChanged,
      this.description});
  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    return MergeSemantics(
        child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(fontSize: theme.bodySize, color: p.foreground)),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(description!,
                style: TextStyle(
                    fontSize: theme.smallSize, color: p.muted, height: 1.7))
          ],
        ])),
        const SizedBox(width: 16),
        Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: p.accent,
            thumbColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected) ? p.accentInk : p.muted))
      ]),
    ));
  }
}
