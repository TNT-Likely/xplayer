import 'package:flutter/material.dart';
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
        builder: (context, value, _) => XpTextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          onChanged: onChanged,
          hint: hint,
          prefix: const Padding(
              padding: EdgeInsets.all(13), child: XpIcon(XpSymbol.search)),
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
        ),
      );
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
