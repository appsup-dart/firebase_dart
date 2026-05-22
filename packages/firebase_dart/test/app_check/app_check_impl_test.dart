import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/app_check/app_check.dart';
import 'package:firebase_dart/src/app_check/impl.dart';
import 'package:test/test.dart';

import '../util.dart';

class _CountingProvider implements AppCheckProvider {
  _CountingProvider(
      {this.ttl = const Duration(hours: 1), this.prefix = 'token'});

  final Duration ttl;
  final String prefix;
  int attestCount = 0;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    attestCount++;
    return AppCheckAttestation.minted(
      '$prefix-$attestCount',
      clock.now().add(ttl),
    );
  }
}

class _FailingProvider implements AppCheckProvider {
  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    throw StateError('attestation failed');
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

      await appCheck.activate(providers: AppCheckProviders.single(provider));

      expect(
        await appCheck.onTokenChange.first,
        'token-1',
      );
    });

    test('tries next provider when earlier one fails', () async {
      final appCheck = FirebaseAppCheckImpl(app);
      final failing = _FailingProvider();
      final working = _CountingProvider(prefix: 'ok');

      await appCheck.activate(
        providers: AppCheckProviders([failing, working]),
      );

      expect(await appCheck.getToken(), 'ok-1');
      expect(working.attestCount, 1);
    });

    test('prefers provider instance that succeeded previously', () async {
      final appCheck = FirebaseAppCheckImpl(app);
      final first = _CountingProvider(prefix: 'first');
      final second = _CountingProvider(prefix: 'second');

      await appCheck.activate(
        providers: AppCheckProviders([first, second]),
      );

      expect(await appCheck.getToken(), 'first-1');
      expect(first.attestCount, 1);
      expect(second.attestCount, 0);

      expect(await appCheck.getToken(true), 'first-2');
      expect(first.attestCount, 2);
      expect(second.attestCount, 0);
    });

    test('getToken returns cached token without refetching provider', () async {
      final appCheck = FirebaseAppCheckImpl(app);
      final provider = _CountingProvider();

      await appCheck.activate(providers: AppCheckProviders.single(provider));

      expect(await appCheck.getToken(), 'token-1');
      expect(provider.attestCount, 1);

      expect(await appCheck.getToken(true), 'token-2');
      expect(provider.attestCount, 2);
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
            appCheck.activate(providers: AppCheckProviders.single(provider));
            async.flushMicrotasks();

            expect(provider.attestCount, 1);
            expect(tokens, ['token-1']);

            async.elapse(proactiveRefreshDelay);
            async.flushMicrotasks();

            expect(provider.attestCount, 2);
            expect(tokens, ['token-1', 'token-2']);
          });
        });
      });

      test('setTokenAutoRefreshEnabled false prevents proactive refresh', () {
        fakeAsync((async) {
          withClock(Clock.fixed(DateTime.utc(2025, 6, 1, 12)), () {
            final appCheck = FirebaseAppCheckImpl(app);
            final provider = _CountingProvider(ttl: const Duration(hours: 1));

            appCheck.activate(providers: AppCheckProviders.single(provider));
            async.flushMicrotasks();
            appCheck.setTokenAutoRefreshEnabled(false);
            async.flushMicrotasks();

            async.elapse(proactiveRefreshDelay);
            async.flushMicrotasks();

            expect(provider.attestCount, 1);
          });
        });
      });

      test('getLimitedUseToken does not cache or increment attest on getToken',
          () async {
        final appCheck = FirebaseAppCheckImpl(app);
        final provider = _CountingProvider();

        await appCheck.activate(providers: AppCheckProviders.single(provider));
        expect(provider.attestCount, 1);

        expect(await appCheck.getLimitedUseToken(), 'token-2');
        expect(provider.attestCount, 2);
        expect(await appCheck.getToken(), 'token-1');
        expect(provider.attestCount, 2);
      });

      test('re-enabling auto refresh schedules refresh from cached token', () {
        fakeAsync((async) {
          withClock(Clock.fixed(DateTime.utc(2025, 6, 1, 12)), () {
            final appCheck = FirebaseAppCheckImpl(app);
            final provider = _CountingProvider(ttl: const Duration(hours: 1));

            appCheck.activate(providers: AppCheckProviders.single(provider));
            async.flushMicrotasks();
            appCheck.setTokenAutoRefreshEnabled(false);
            async.flushMicrotasks();
            appCheck.setTokenAutoRefreshEnabled(true);
            async.flushMicrotasks();

            expect(provider.attestCount, 1);

            async.elapse(proactiveRefreshDelay);
            async.flushMicrotasks();

            expect(provider.attestCount, 2);
          });
        });
      });
    });
  });
}
