import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/services/guide_catalog.dart';
import 'package:xplayer_storekit/xplayer_storekit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'programme matches use the imported channel IDs and skip ended shows',
    () {
      final now = DateTime.utc(2026, 11, 27, 12);
      final catalog = GuideCatalog([
        GuideChannel(Channel(id: 'ONE', name: 'Science', source: []), 'Home'),
        GuideChannel(Channel(id: 'TWO', name: 'Music', source: []), 'Travel'),
      ]);
      Programme show(String id, String title, int start, int end) => Programme(
        channel: id,
        title: title,
        start: now.add(Duration(minutes: start)),
        stop: now.add(Duration(minutes: end)),
      );
      final items = [
        show('two', 'Piano Recital', 20, 40),
        show('one', 'Deep Ocean', -5, 5),
        show('one', 'Ocean Yesterday', -10, 0),
        show('missing', 'Ocean', 0, 5),
      ];
      expect(catalog.findChannels('MUS').single.playlistName, 'Travel');
      expect(
        catalog.findShows(items, [' OCEAN ', 'piano'], now).map((s) => s.title),
        ['Deep Ocean', 'Piano Recital'],
      );
      expect(catalog.findShows(items, ['no match'], now), isEmpty);
    },
  );

  test(
    'storefront errors preserve signed access and restored expirations clear it',
    () async {
      const channel = MethodChannel('xplayer/test-store');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final plan = ProPlan.monthly.productId;
      var entitled = true;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'products') throw PlatformException(code: 'offline');
        return {
          'supported': true,
          'active': [if (entitled) plan],
        };
      });
      final store = ProMembership(channel: channel);
      addTearDown(() {
        store.dispose();
        messenger.setMockMethodCallHandler(channel, null);
      });
      await store.refresh();
      expect(store.canUsePro, isTrue);
      await store.loadPrices();
      expect(store.prices, isEmpty);
      expect(store.canUsePro, isTrue);
      entitled = false;
      expect(await store.restore(), 'nothing');
      expect(store.canUsePro, isFalse);
      expect(await store.buy(ProPlan.lifetime), 'unavailable');
    },
  );

  test('community builds open the studio without starting StoreKit', () {
    final store = ProMembership(storeBuild: false)..start();
    addTearDown(store.dispose);
    expect(store.ready, isTrue);
    expect(store.canUsePro, isTrue);
  });
}
