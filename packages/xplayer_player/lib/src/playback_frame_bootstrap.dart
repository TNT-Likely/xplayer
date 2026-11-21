import 'dart:async';

import 'package:flutter/widgets.dart';

/// media_kit_video starts its platform controller in a post-frame callback.
/// An occluded desktop view may have no vsync frame; one warm-up frame lets
/// initialization and cancellation finish without waiting for visibility.
Timer requestPlaybackFrame(bool Function() isPending) {
  final binding = WidgetsBinding.instance;
  binding.ensureVisualUpdate();
  return Timer(const Duration(milliseconds: 100), () {
    if (isPending()) binding.scheduleWarmUpFrame();
  });
}
