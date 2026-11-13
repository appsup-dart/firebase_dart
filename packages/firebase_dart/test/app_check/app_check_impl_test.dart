import 'dart:async';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/app_check/app_check.dart';
import 'package:firebase_dart/src/app_check/firebase_app_check_exception.dart';
import 'package:firebase_dart/src/app_check/impl.dart';
import 'package:firebase_dart/src/app_check/token_store.dart';
import 'package:test/test.dart';

import '../util.dart';

class _CountingProvider extends AttestingAppCheckProvider {
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

class _FailingProvider extends AttestingAppCheckProvider {
  int attestCount = 0;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    attestCount++;
    throw StateError('attestation failed');
  }
}

class _FlakyProvider extends AttestingAppCheckProvider {
  _FlakyProvider({this.failures = 1});

  int failures;
  int attestCount = 0;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    attestCount++;
    if (attestCount <= failures) {
      throw StateError('attestation failed');
    }
    return AppCheckAttestation.minted(
      'token-$attestCount',
      clock.now().add(const Duration(hours: 1)),
    );
  }
}

class _TransientThenOkProvider extends AttestingAppCheckProvider {
  int attestCount = 0;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    attestCount++;
    if (attestCount == 1) {
      throw TimeoutException('app check exchange timed out');
    }
    return AppCheckAttestation.minted(
      'token-$attestCount',
      clock.now().add(const Duration(hours: 1)),
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
      await deleteAppCheckToken(app.options.appId);
    });

    tearDown(() async {
      await app.delete();
    });

    test('activate without providers leaves App Check inactive', () async {
      final appCheck = FirebaseAppCheckImpl(app);

      await appCheck.activate();

      expect(await appCheck.getToken(), isNull);
    });

    test('onTokenChange emits current token when listened after activate',
        () async {
      final appCheck = FirebaseAppCheckImpl(app);
      final provider = _CountingProvider();

      await appCheck.activate(provider: provider);

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
        provider: AppCheckProvider.fallback([failing, working]),
      );

      expect(await appCheck.getToken(), 'ok-1');
      expect(working.attestCount, 1);
    });

    test('prefers provider instance that succeeded previously', () async {
      final appCheck = FirebaseAppCheckImpl(app);
      final first = _CountingProvider(prefix: 'first');
      final second = _CountingProvider(prefix: 'second');

      await appCheck.activate(
        provider: AppCheckProvider.fallback([first, second]),
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

      await appCheck.activate(provider: provider);

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
            appCheck.activate(provider: provider);
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

            appCheck.activate(provider: provider);
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

        await appCheck.activate(provider: provider);
        expect(provider.attestCount, 1);

        expect(await appCheck.getLimitedUseToken(), 'token-2');
        expect(provider.attestCount, 2);
        expect(await appCheck.getToken(), 'token-1');
        expect(provider.attestCount, 2);
      });

      test('retries a transient failure even when no token is cached', () {
        fakeAsync((async) {
          withClock(Clock.fixed(DateTime.utc(2025, 6, 1, 12)), () {
            final appCheck = FirebaseAppCheckImpl(app);
            final provider = _TransientThenOkProvider();
            final tokens = <String?>[];

            appCheck.onTokenChange.listen(tokens.add);
            appCheck.activate(provider: provider);
            async.flushMicrotasks();

            expect(provider.attestCount, 1);
            expect(tokens, isEmpty);

            async.elapse(const Duration(seconds: 30));
            async.flushMicrotasks();

            expect(provider.attestCount, 2);
            expect(tokens, ['token-2']);
          });
        });
      });

      test('a provider failure during background refresh stays in the caller',
          () {
        fakeAsync((async) {
          withClock(Clock.fixed(DateTime.utc(2025, 6, 1, 12)), () {
            final appCheck = FirebaseAppCheckImpl(app);
            final provider = _FailingProvider();

            appCheck.activate(provider: provider);
            async.flushMicrotasks();
            async.elapse(const Duration(seconds: 30));
            async.flushMicrotasks();

            expect(provider.attestCount, 1);
          });
        });
      });

      test('re-enabling auto refresh schedules refresh from cached token', () {
        fakeAsync((async) {
          withClock(Clock.fixed(DateTime.utc(2025, 6, 1, 12)), () {
            final appCheck = FirebaseAppCheckImpl(app);
            final provider = _CountingProvider(ttl: const Duration(hours: 1));

            appCheck.activate(provider: provider);
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

    test('getToken can try again after every provider fails', () async {
      final appCheck = FirebaseAppCheckImpl(app);
      final provider = _FlakyProvider();

      await appCheck.setTokenAutoRefreshEnabled(false);
      await appCheck.activate(
        provider: AppCheckProvider.fallback([provider]),
      );

      await expectLater(
        appCheck.getToken(),
        throwsA(isA<FirebaseAppCheckException>().having(
          (error) => error.code,
          'code',
          'attestation-failed',
        )),
      );
      expect(await appCheck.getToken(), 'token-2');
      expect(provider.attestCount, 2);
    });

    test('reuses a persisted token in a new instance', () async {
      final firstProvider = _CountingProvider();
      final first = FirebaseAppCheckImpl(app);
      await first.activate(provider: firstProvider);
      expect(await first.getToken(), 'token-1');
      await first.delete();

      final secondProvider = _CountingProvider(prefix: 'second');
      final second = FirebaseAppCheckImpl(app);
      await second.activate(provider: secondProvider);

      expect(await second.getToken(), 'token-1');
      expect(secondProvider.attestCount, 0);
    });

    test('ignores an expired persisted token', () async {
      final start = DateTime.utc(2025, 6, 1, 12);
      await withClock(Clock.fixed(start), () async {
        final first = FirebaseAppCheckImpl(app);
        await first.activate(
          provider: _CountingProvider(
            ttl: const Duration(minutes: 1),
            prefix: 'old',
          ),
        );
        expect(await first.getToken(), 'old-1');
        await first.delete();
      });

      final fresh = _CountingProvider(prefix: 'new');
      await withClock(Clock.fixed(start.add(const Duration(minutes: 2))),
          () async {
        final second = FirebaseAppCheckImpl(app);
        await second.activate(provider: fresh);
        expect(await second.getToken(), 'new-1');
      });
      expect(fresh.attestCount, 1);
    });
  });
}
