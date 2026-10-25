import 'package:flutter/material.dart';
import 'controls.dart';
import 'icons.dart';
import 'theme.dart';

enum XpTone { neutral, success, warning, error }

class XpBadge extends StatelessWidget {
  const XpBadge(this.label,
      {super.key, this.tone = XpTone.neutral, this.dot = false});
  final String label;
  final XpTone tone;
  final bool dot;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    final ink = switch (tone) {
      XpTone.error => p.error,
      XpTone.warning => p.warning,
      _ => p.accent
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: ink.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: ink.withValues(alpha: .22))),
      child: Text('${dot ? '●  ' : ''}$label',
          style: TextStyle(
              color: ink,
              fontSize: theme.smallSize,
              fontWeight: FontWeight.w500)),
    );
  }
}

class XpProgress extends StatelessWidget {
  const XpProgress({super.key, required this.value, this.label = '进度'});
  final double value;
  final String label;
  @override
  Widget build(BuildContext context) {
    final p = XpTheme.of(context).palette;
    final safe = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    return Semantics(
        label: label,
        value: '${(safe * 100).round()}%',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
              value: safe,
              minHeight: 3,
              color: p.accent,
              backgroundColor: p.border),
        ));
  }
}

class XpEmptyState extends StatelessWidget {
  const XpEmptyState(
      {super.key,
      required this.title,
      required this.description,
      this.icon = XpSymbol.info,
      this.actionLabel,
      this.onAction,
      this.secondaryLabel,
      this.onSecondary,
      this.loading = false,
      this.tone = XpTone.neutral});
  final String title, description;
  final XpSymbol icon;
  final String? actionLabel, secondaryLabel;
  final VoidCallback? onAction, onSecondary;
  final bool loading;
  final XpTone tone;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    final ink = tone == XpTone.error
        ? p.error
        : tone == XpTone.warning
            ? p.warning
            : p.accent;
    return Semantics(
        liveRegion: true,
        container: true,
        child: SingleChildScrollView(
            child: XpSurface(
          padding: EdgeInsets.symmetric(
              vertical: theme.isTv ? 48 : 32, horizontal: 24),
          child: SizedBox(
              width: double.infinity,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: theme.isTv ? 88 : 58,
                    height: theme.isTv ? 88 : 58,
                    decoration: BoxDecoration(
                        color: ink.withValues(alpha: .08),
                        border: Border.all(color: p.border),
                        borderRadius: BorderRadius.circular(17)),
                    alignment: Alignment.center,
                    child: loading
                        ? SizedBox(
                            width: 25,
                            height: 25,
                            child: theme.reduceMotion
                                ? XpIcon(XpSymbol.sync, size: 20, color: ink)
                                : CircularProgressIndicator(
                                    strokeWidth: 2, color: ink))
                        : XpIcon(icon, color: ink, size: theme.isTv ? 38 : 28)),
                const SizedBox(height: 22),
                Text(title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: theme.titleSize,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: p.foreground)),
                const SizedBox(height: 12),
                ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Text(description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: theme.bodySize,
                            color: p.muted,
                            height: 1.8))),
                if (actionLabel != null || secondaryLabel != null) ...[
                  const SizedBox(height: 24),
                  Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        if (actionLabel != null)
                          XpButton(
                              label: actionLabel!,
                              onPressed: loading ? null : onAction),
                        if (secondaryLabel != null)
                          XpButton(
                              label: secondaryLabel!,
                              onPressed: onSecondary,
                              variant: XpButtonVariant.secondary),
                      ]),
                ],
              ])),
        )));
  }
}

class XpNotice extends StatelessWidget {
  const XpNotice(
      {super.key,
      required this.title,
      required this.description,
      this.tone = XpTone.neutral,
      this.actionLabel,
      this.onAction,
      this.loading = false});
  final String title, description;
  final XpTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    final color = tone == XpTone.error
        ? p.error
        : tone == XpTone.warning
            ? p.warning
            : p.accent;
    return Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: color.withValues(alpha: .06),
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(10)),
          child: LayoutBuilder(builder: (context, box) {
            final copy =
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: theme.reduceMotion
                              ? XpIcon(XpSymbol.sync, size: 20, color: color)
                              : CircularProgressIndicator(
                                  strokeWidth: 2, color: color))
                      : XpIcon(XpSymbol.info, color: color)),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: TextStyle(
                            color: p.foreground,
                            fontSize: theme.bodySize,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text(description,
                        style: TextStyle(
                            color: p.muted,
                            fontSize: theme.smallSize,
                            height: 1.8)),
                  ])),
            ]);
            final action = actionLabel == null
                ? null
                : XpButton(
                    label: actionLabel!,
                    onPressed: onAction,
                    loading: loading,
                    variant: XpButtonVariant.secondary);
            if (box.maxWidth < 550 || theme.isTv) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    copy,
                    if (action != null) ...[const SizedBox(height: 14), action]
                  ]);
            }
            return Row(children: [
              Expanded(child: copy),
              if (action != null) ...[const SizedBox(width: 20), action]
            ]);
          }),
        ));
  }
}

class XpConfirmDialog extends StatelessWidget {
  const XpConfirmDialog(
      {super.key,
      required this.title,
      required this.child,
      required this.onConfirm,
      required this.onCancel,
      this.confirmLabel = '确认',
      this.loading = false});
  final String title, confirmLabel;
  final Widget child;
  final VoidCallback? onConfirm;
  final VoidCallback onCancel;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    return Dialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border)),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(title,
                              style: TextStyle(fontSize: theme.titleSize))),
                      XpIconButton(
                          icon: XpSymbol.close,
                          label: '关闭弹窗',
                          onPressed: loading ? null : onCancel)
                    ]),
                    const SizedBox(height: 16),
                    child,
                    const SizedBox(height: 24),
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      XpButton(
                          label: confirmLabel,
                          onPressed: onConfirm,
                          loading: loading),
                      XpButton(
                          label: '取消',
                          onPressed: loading ? null : onCancel,
                          variant: XpButtonVariant.secondary)
                    ]),
                  ]))),
    );
  }
}
