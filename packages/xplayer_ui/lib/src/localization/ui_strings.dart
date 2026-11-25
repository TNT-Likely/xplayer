import 'package:flutter/widgets.dart';

import 'xp_ui_localizations.dart';
import 'xp_ui_localizations_zh.dart';

// Existing hosts can opt into localization by registering the delegate.
final _defaultStrings = XpUiLocalizationsZh();

extension XpUiStrings on BuildContext {
  XpUiLocalizations get xpStrings =>
      XpUiLocalizations.of(this) ?? _defaultStrings;
}
