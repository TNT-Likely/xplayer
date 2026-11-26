import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer_storekit/xplayer_storekit.dart';
import 'guide_studio.dart';

ThemeData guideTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppTokens.brand,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xff101413),
  useMaterial3: true,
);

class ProMembershipScreen extends StatefulWidget {
  const ProMembershipScreen({super.key});
  @override
  State<ProMembershipScreen> createState() => _ProMembershipScreenState();
}

class _ProMembershipScreenState extends State<ProMembershipScreen> {
  ProPlan _selected = ProPlan.lifetime;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = context.read<ProMembership>();
    await Future.wait([store.refresh(), store.loadPrices()]);
    if (mounted) setState(() => _loading = false);
  }

  String _name(ProPlan plan, AppLocalizations l) => switch (plan) {
    ProPlan.lifetime => l.proLifetime,
    ProPlan.yearly => l.proYearly,
    ProPlan.monthly => l.proMonthly,
  };

  String _period(ProPlan plan, AppLocalizations l) => switch (plan) {
    ProPlan.lifetime => l.proOneTime,
    ProPlan.yearly => l.proAnnualRenew,
    ProPlan.monthly => l.proMonthlyRenew,
  };

  void _show(String status) {
    if (!mounted || status == 'cancelled') return;
    final l = AppLocalizations.of(context)!;
    final message = switch (status) {
      'purchased' => l.proPurchased,
      'restored' => l.proRestored,
      'nothing' => l.proRestoreNone,
      'pending' => l.proPending,
      _ => l.proStoreError,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _purchase(ProMembership store) async {
    final l = AppLocalizations.of(context)!;
    final plan = _selected;
    if (plan == ProPlan.lifetime && store.subscribed) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.proLifetime),
          content: Text(l.proCancelNotice),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.proBack),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.proContinue),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    _show(await store.buy(plan));
  }

  Future<void> _link(String url) async {
    try {
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        _show('error');
      }
    } catch (_) {
      _show('error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final store = context.watch<ProMembership>();
    final price = store.prices[_selected.productId];
    final enabled =
        store.ready &&
        !store.stateFailed &&
        !store.busy &&
        price != null &&
        !store.active.contains(_selected.productId);
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    return Theme(
      data: guideTheme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('XPlayer Pro')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.proStudioLead,
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.proStudioDescription,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final row in [
                    (
                      Icons.video_library_outlined,
                      l.proChannelFinder,
                      l.proChannelDetail,
                    ),
                    (
                      Icons.manage_search,
                      l.proProgrammeFinder,
                      l.proProgrammeDetail,
                    ),
                    (
                      Icons.bookmark_border_rounded,
                      l.proTracker,
                      l.proTrackerDetail,
                    ),
                  ])
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(row.$1, color: AppTokens.brand),
                      title: Text(row.$2),
                      subtitle: Text(row.$3),
                    ),
                  const Divider(height: 28),
                  if (store.canUsePro) ...[
                    Text(
                      '${l.proMember} · ${ProPlan.values.where((p) => store.active.contains(p.productId)).map((p) => _name(p, l)).join(' / ')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GuideStudioScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.live_tv),
                      label: Text(l.proOpenStudio),
                    ),
                    if (store.subscribed) ...[
                      if (store.lifetime) Text(l.proCancelNotice),
                      TextButton(
                        onPressed: () => _link(
                          'https://apps.apple.com/account/subscriptions',
                        ),
                        child: Text(l.proManage),
                      ),
                    ],
                  ],
                  if (store.ready && !store.supported)
                    Text(l.proUnsupported)
                  else if (!store.lifetime) ...[
                    Text(
                      l.proPlans,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final plan in ProPlan.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Builder(
                          builder: (context) {
                            final selected = plan == _selected;
                            return Semantics(
                              selected: selected,
                              button: true,
                              child: Material(
                                color: selected
                                    ? const Color(0xff193b2e)
                                    : const Color(0xff1d2321),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: selected
                                        ? AppTokens.brand
                                        : Colors.transparent,
                                    width: 1.4,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  onTap: store.busy
                                      ? null
                                      : () => setState(() => _selected = plan),
                                  leading: Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: selected
                                        ? AppTokens.brand
                                        : Colors.white54,
                                  ),
                                  title: Text(
                                    _name(plan, l),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(_period(plan, l)),
                                  trailing: Text(
                                    store.prices[plan.productId] ?? '—',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    FilledButton(
                      onPressed: enabled ? () => _purchase(store) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          [
                            if (store.active.contains(_selected.productId))
                              l.proActive
                            else if (_selected == ProPlan.lifetime)
                              l.proLifetimeBuy
                            else
                              l.proSubscribe,
                            if (price != null) price,
                          ].join(' · '),
                        ),
                      ),
                    ),
                  ],
                  if (_loading || store.busy)
                    const LinearProgressIndicator()
                  else if (store.supported &&
                      (store.stateFailed ||
                          (!store.lifetime &&
                              store.prices.length !=
                                  ProPlan.values.length))) ...[
                    const SizedBox(height: 8),
                    Text(
                      store.stateFailed ? l.proStateError : l.proUnavailable,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _loading = true);
                        unawaited(_load());
                      },
                      child: Text(l.proRetry),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    l.proSubscriptionNote,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(
                        onPressed: store.busy || !store.supported
                            ? null
                            : () async => _show(await store.restore()),
                        child: Text(l.proRestore),
                      ),
                      TextButton(
                        onPressed: () => _link(
                          'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
                        ),
                        child: Text(l.proTerms),
                      ),
                      TextButton(
                        onPressed: () => _link(
                          'https://xplayer.beejz.com/${zh ? 'zh/' : ''}privacy',
                        ),
                        child: Text(l.proPrivacy),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
