import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/app_check/app_check.dart';
import 'package:firebase_dart/src/app_check/impl.dart';
import 'package:test/test.dart';

import '../util.dart';

class _CountingProvider extends WebProvider {
  _CountingProvider({this.ttl = const Duration(hours: 1)}) : super('test-site-key');

  final Duration ttl;
  int fetchCount = 0;

  @override
  Future<AppCheckToken> getToken(FirebaseApp app) async {
    fetchCount++;
    return AppCheckToken(
      'token-$fetchCount',
      clock.now().add(ttl),
    );
  }
}

void main() {
  setUpAll(() {
    FirebaseDart.setup();
  });

  group('FirebaseAppCheckImpl', () {
    late FirebaseApp app;

    setUp(() async {
      app = await Firebase.initializeApp(
        options: getOptions(appId: '1:2:web:abc'),
        name: 'app-check-${DateTime.now().microsecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      await app.delete();
    });

    test('onTokenChange emits current token when listened after activate',
        () async {
      final appCheck = FirebaseAppCheckImpl(app);
      final provider = _CountingProvider();

      await appCheck.activate(webProvider: provider);

      expect(
        await appCheck.onTokenChange.first,
        'token-1',
      );
    });

    test('getToken returns cached token without refetching provider', () async {
      final appCheck = FirebaseAppCheckImpl(app);
      final provider = _CountingProvider();

      await appCheck.activate(webProvider: provider);
      expect(provider.fetchCount, 1);

      expect(await appCheck.getToken(), 'token-1');
      expect(provider.fetchCount, 1);

      expect(await appCheck.getToken(true), 'token-2');
      expect(provider.fetchCount, 2);
    });

    group('auto refresh', () {
      /// For [Duration(hours: 1)] TTL: 50% + 5min = 35min (capped before expiry).
      const proactiveRefreshDelay = Duration(minutes: 35);
      test('proactive refresh after scheduled delay', () {
        fakeAsync((async) {
          withClock(Clock.fixed(DateTime.utc(2025, 6, 1, 12)), () {
            final appCheck = FirebaseAppCheckImpl(app);
            final provider = _CountingProvider(ttl: const Duration(hours: 1));
            final tokens = <String?>[];

            appCheck.onTokenChange.listen(tokens.add);
            appCheck.activate(webProvider: provider);
            async.flushMicrotasks();

            expect(provider.fetchCount, 1);
            expect(tokens, ['token-1']);

            async.elapse(proactiveRefreshDelay);
            async.flushMicrotasks();

            expect(provider.fetchCount, 2);
            expect(tokens, ['token-1', 'token-2']);
          });
        });
      });

      test('setTokenAutoRefreshEnabled false prevents proactive refresh', () {
        fakeAsync((async) {
          withClock(Clock.fixed(DateTime.utc(2025, 6, 1, 12)), () {
            final appCheck = FirebaseAppCheckImpl(app);
            final provider = _CountingProvider(ttl: const Duration(hours: 1));

            appCheck.activate(webProvider: provider);
            async.flushMicrotasks();
            appCheck.setTokenAutoRefreshEnabled(false);
            async.flushMicrotasks();

            async.elapse(proactiveRefreshDelay);
            async.flushMicrotasks();

            expect(provider.fetchCount, 1);
          });
        });
      });

      test('re-enabling auto refresh schedules refresh from cached token', () {
        fakeAsync((async) {
          withClock(Clock.fixed(DateTime.utc(2025, 6, 1, 12)), () {
            final appCheck = FirebaseAppCheckImpl(app);
            final provider = _CountingProvider(ttl: const Duration(hours: 1));

            appCheck.activate(webProvider: provider);
            async.flushMicrotasks();
            appCheck.setTokenAutoRefreshEnabled(false);
            async.flushMicrotasks();
            appCheck.setTokenAutoRefreshEnabled(true);
            async.flushMicrotasks();

            expect(provider.fetchCount, 1);

            async.elapse(proactiveRefreshDelay);
            async.flushMicrotasks();

            expect(provider.fetchCount, 2);
          });
        });
      });
    });
  });
}
