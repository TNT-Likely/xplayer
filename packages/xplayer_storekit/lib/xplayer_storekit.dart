import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum ProPlan {
  lifetime,
  yearly,
  monthly;

  String get productId => 'com.tntlikely.xplayer.pro.$name';
}

bool get isAppleMembershipBuild =>
    const bool.fromEnvironment('APPLE_MEMBERSHIP') &&
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// Apple is the source of truth. Prices and entitlements load independently so
/// a failed storefront request never clears a verified offline entitlement.
class ProMembership extends ChangeNotifier with WidgetsBindingObserver {
  ProMembership({this.storeBuild = true, MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('xplayer/membership');

  final bool storeBuild;
  final MethodChannel _channel;
  Map<String, String> prices = {};
  Set<String> active = {};
  bool supported = true;
  bool ready = false;
  bool busy = false;
  bool stateFailed = false;
  bool _disposed = false;
  Timer? _expiry;
  int _stateRequest = 0;
  int _priceRequest = 0;

  bool get canUsePro => !storeBuild || active.isNotEmpty;
  bool get lifetime => active.contains(ProPlan.lifetime.productId);
  bool get subscribed => active.any((key) => key != ProPlan.lifetime.productId);

  void start() {
    if (!storeBuild) {
      ready = true;
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') await refresh();
    });
    unawaited(refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && storeBuild) {
      unawaited(refresh());
      if (prices.isNotEmpty) unawaited(loadPrices());
    }
  }

  Future<void> refresh() async {
    if (!storeBuild) return;
    final request = ++_stateRequest;
    try {
      final data = await _channel.invokeMapMethod<String, dynamic>('state');
      if (_disposed || request != _stateRequest || data == null) return;
      supported = data['supported'] == true;
      active = Set<String>.from(data['active'] as List);
      stateFailed = false;
      _expiry?.cancel();
      final until = data['expires'] as int?;
      if (until != null) {
        final ms = until - DateTime.now().millisecondsSinceEpoch;
        // A signed billing-grace entitlement can outlive the original period.
        _expiry = Timer(
          ms > 0
              ? Duration(milliseconds: ms + 250)
              : const Duration(minutes: 1),
          refresh,
        );
      }
    } on PlatformException {
      if (request == _stateRequest) stateFailed = true;
    } finally {
      if (!_disposed && request == _stateRequest) {
        ready = true;
        notifyListeners();
      }
    }
  }

  Future<void> loadPrices() async {
    if (!storeBuild) return;
    final request = ++_priceRequest;
    Map<String, String> next;
    try {
      next = await _channel.invokeMapMethod<String, String>('products') ?? {};
    } on PlatformException {
      next = {};
    }
    if (!_disposed && request == _priceRequest) {
      prices = next;
      notifyListeners();
    }
  }

  Future<String> buy(ProPlan plan) async {
    if (busy ||
        !ready ||
        stateFailed ||
        lifetime ||
        active.contains(plan.productId) ||
        !prices.containsKey(plan.productId)) {
      return 'unavailable';
    }
    busy = true;
    notifyListeners();
    try {
      final status = await _channel.invokeMethod<String>('buy', plan.productId);
      if (status == 'purchased') await refresh();
      return status ?? 'unavailable';
    } on PlatformException catch (e) {
      return e.code;
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<String> restore() async {
    if (busy) return 'unavailable';
    busy = true;
    notifyListeners();
    try {
      await _channel.invokeMethod('restore');
      await refresh();
      if (stateFailed) return 'store_error';
      return active.isEmpty ? 'nothing' : 'restored';
    } on PlatformException catch (e) {
      return e.code;
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _expiry?.cancel();
    if (storeBuild) {
      WidgetsBinding.instance.removeObserver(this);
      _channel.setMethodCallHandler(null);
    }
    super.dispose();
  }
}
