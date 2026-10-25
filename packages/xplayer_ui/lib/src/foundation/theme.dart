import 'package:flutter/material.dart';

enum XpDevice { phone, ipad, desktop, tv }

/// TV 由宿主显式选择，窗口变宽不会自动进入遥控模式。
enum XpInputMode { touch, pointer, directional }

abstract final class XpSpace {
  static const double xxs = 4, xs = 8, sm = 12, md = 16, lg = 24, xl = 32;
}

abstract final class XpMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 200);
}

@immutable
class XpPalette {
  const XpPalette({
    this.background = const Color(0xff0f1915),
    this.surface = const Color(0xff14211b),
    this.raised = const Color(0xff1b2a22),
    this.border = const Color(0xff29382e),
    this.foreground = const Color(0xffedf2e9),
    this.muted = const Color(0xff8d9c8d),
    this.quiet = const Color(0xff627566),
    this.accent = const Color(0xffb5e6bb),
    this.accentInk = const Color(0xff17371e),
    this.accentWash = const Color(0x13b5e6bb),
    this.warning = const Color(0xffdcc28b),
    this.error = const Color(0xffe2a89b),
  });

  final Color background, surface, raised, border, foreground, muted, quiet;
  final Color accent, accentInk, accentWash, warning, error;
}

@immutable
class XpThemeData {
  const XpThemeData({
    this.device = XpDevice.desktop,
    this.palette = const XpPalette(),
    this.reduceMotion = false,
    this.fontFamily,
    this.inputMode,
  });

  final XpDevice device;
  final XpPalette palette;
  final bool reduceMotion;
  final String? fontFamily;
  final XpInputMode? inputMode;
  bool get isTv => device == XpDevice.tv;
  double get controlHeight => isTv ? 56 : 44;
  double get iconSize => isTv ? 26 : 20;
  double get bodySize => isTv ? 20 : 14;
  double get smallSize => isTv ? 16 : 12;
  double get titleSize => isTv ? 32 : 23;
  double get radius => 16;
  XpInputMode get input =>
      inputMode ??
      switch (device) {
        XpDevice.phone || XpDevice.ipad => XpInputMode.touch,
        XpDevice.desktop => XpInputMode.pointer,
        XpDevice.tv => XpInputMode.directional,
      };
  Duration get duration => reduceMotion ? Duration.zero : XpMotion.fast;

  static XpDevice deviceForWidth(double width) => width < 600
      ? XpDevice.phone
      : width < 1200
          ? XpDevice.ipad
          : XpDevice.desktop;

  ThemeData materialTheme() {
    final color = palette;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: color.background,
      colorScheme: ColorScheme.dark(
        primary: color.accent,
        onPrimary: color.accentInk,
        surface: color.surface,
        onSurface: color.foreground,
        error: color.error,
      ),
      fontFamily: fontFamily,
      textTheme: ThemeData.dark().textTheme.apply(
            fontFamily: fontFamily,
            bodyColor: color.foreground,
            displayColor: color.foreground,
          ),
      iconTheme: IconThemeData(color: color.muted, size: iconSize),
      dividerColor: color.border,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
            color: color.raised, borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(color: color.foreground, fontSize: 12),
      ),
    );
  }
}

class XpTheme extends InheritedWidget {
  const XpTheme({super.key, required this.data, required super.child});
  final XpThemeData data;
  static XpThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<XpTheme>()?.data ??
      const XpThemeData();
  @override
  bool updateShouldNotify(XpTheme oldWidget) => oldWidget.data != data;
}

class XpSurface extends StatelessWidget {
  const XpSurface(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20),
      this.raised = false});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool raised;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: raised ? theme.palette.raised : theme.palette.surface,
        border: Border.all(color: theme.palette.border),
        borderRadius: BorderRadius.circular(theme.radius),
      ),
      child: child,
    );
  }
}
