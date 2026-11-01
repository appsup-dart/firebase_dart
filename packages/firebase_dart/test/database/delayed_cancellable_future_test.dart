import 'dart:async';

import 'package:firebase_dart/src/database/impl/utils.dart';
import 'package:test/test.dart';

void main() {
  test('cancelling a delayed registration completes waiters', () async {
    var future = DelayedCancellableFuture<void>(
        const Duration(seconds: 30), () {});
    future.cancel();
    await future.timeout(const Duration(seconds: 1));
  });

  test('cancelling during computation swallows its error', () async {
    var started = Completer<void>();
    var release = Completer<void>();
    var errors = <Object>[];
    late DelayedCancellableFuture<void> future;
    runZonedGuarded(() {
      future = DelayedCancellableFuture<void>(Duration.zero, () async {
        started.complete();
        await release.future;
        throw StateError('late');
      });
    }, (error, _) => errors.add(error));

    await started.future.timeout(const Duration(seconds: 1));
    future.cancel();
    release.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(errors, isEmpty);
    await future.timeout(const Duration(seconds: 1));
  });
}
