@Tags(['benchmark'])
library;

import 'dart:async';
import 'dart:math';

import 'package:benchmark_test/benchmark_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/manager.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/synctree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:test/test.dart';

const _dayMillis = 24 * 60 * 60 * 1000;
const _queryDays = 20;
const _dataDays = 60;

final _eventsPath = Name.parsePath('events');

/// Calendar-shaped SyncTree benchmark.
///
/// Events are stored as children under `/events`; each event has a `start` and
/// `end` value. For every visible day we install the three query shapes used by
/// a calendar UI:
///
/// * last event starting before the day
/// * all events starting during the day
/// * first event starting after the day
///
/// Run:
/// ```bash
/// dart test --run-skipped -t benchmark test/benchmark/calendar_benchmark_test.dart
/// ```
void main() {
  group('calendar queries', () {
    group('density: 5 events/day', () {
      const useCase = _CalendarDensity(5);
      final tester = _UseCaseTester(useCase);

      tester.setUp();

      test('planned listeners are attached to complete views', () {
        tester.checkPlannedListenersComplete();
      });

      benchmark('listen acks + first server snapshots', () {
        tester.processPendingRegistrationsUntilStable();
      });
    });

    group('density: 1 event/day', () {
      const useCase = _CalendarDensity(1);
      final tester = _UseCaseTester(useCase);

      tester.setUp();

      test('planned listeners are attached to complete views', () {
        tester.checkPlannedListenersComplete();
      });

      benchmark('listen acks + first server snapshots', () {
        tester.processPendingRegistrationsUntilStable();
      });
    });

    group('density: 1 event / 10 days', () {
      const useCase = _CalendarDensity(0.1);
      final tester = _UseCaseTester(useCase);

      tester.setUp();

      test('planned listeners are attached to complete views', () {
        tester.checkPlannedListenersComplete();
      });

      benchmark('listen acks + first server snapshots', () {
        tester.processPendingRegistrationsUntilStable();
      });
    });
  });
}

class _UseCaseTester {
  final _SyncTreeBenchmarkUseCase useCase;
  final _SyncTreeBenchmarkPlan plan;

  _UseCaseTester(this.useCase) : plan = useCase.toPlan();

  late FakeAsync fake;
  late _SyncTreeBenchmarkHarness harness;

  void setUp() {
    setUpEach(() {
      final state = _createBenchmarkHarness(useCase);
      fake = state.fake;
      harness = state.harness;
    });

    tearDownEach(() => _disposeBenchmarkHarness(fake, harness));
  }

  void checkPlannedListenersComplete() {
    _expectPlannedListenersComplete(useCase);
  }

  void processPendingRegistrationsUntilStable() {
    fake.run((async) {
      harness.processPendingRegistrationsUntilStable(async);
    });
  }

  ({FakeAsync fake, _SyncTreeBenchmarkHarness harness}) _createBenchmarkHarness(
    _SyncTreeBenchmarkUseCase useCase,
  ) {
    final fake = FakeAsync();
    late _SyncTreeBenchmarkHarness harness;
    fake.run((async) {
      harness = _SyncTreeBenchmarkHarness(plan);
      harness.addObservers();
      harness.pump(async);
    });
    return (fake: fake, harness: harness);
  }

  void _disposeBenchmarkHarness(
    FakeAsync fake,
    _SyncTreeBenchmarkHarness harness,
  ) {
    fake.run((_) => harness.dispose());
  }

  void _expectPlannedListenersComplete(_SyncTreeBenchmarkUseCase useCase) {
    final testFake = FakeAsync();
    late _SyncTreeBenchmarkHarness testHarness;
    testFake.run((async) {
      final plan = useCase.toPlan();
      testHarness = _SyncTreeBenchmarkHarness(plan);
      testHarness.addObservers();
      testHarness.pump(async);
      testHarness.processPendingRegistrationsUntilStable(async);
    });

    for (final query in testHarness.plan.observerQueries) {
      final view = testHarness.completeViewForQuery(query);
      expect(
        view,
        isNotNull,
        reason: 'No complete view found for $query',
      );
      expect(
        view!.observers[query.params],
        isNotNull,
        reason: 'No observer target found for $query',
      );
    }

    testFake.run((_) => testHarness.dispose());
  }
}

abstract class _SyncTreeBenchmarkUseCase {
  _SyncTreeBenchmarkPlan toPlan();
}

class _CalendarDensity implements _SyncTreeBenchmarkUseCase {
  final double eventsPerDay;

  const _CalendarDensity(this.eventsPerDay);

  @override
  _SyncTreeBenchmarkPlan toPlan() {
    final observerQueries = [
      for (final filter in _calendarObserverFilters())
        QuerySpec(_eventsPath, filter),
    ];
    final allEvents = _eventSnapshot();
    final serverOverwrites = {
      for (final query in observerQueries)
        query: TreeOperation.overwrite(
          query.path,
          allEvents.withFilter(query.params),
        ),
    };
    return _SyncTreeBenchmarkPlan(
      observerQueries: observerQueries,
      serverOverwrites: serverOverwrites,
    );
  }

  TreeStructuredData _eventSnapshot() {
    final eventCount = max(1, (_dataDays * eventsPerDay).round());
    final random = Random(eventsPerDay.hashCode);

    return TreeStructuredData.fromJson({
      for (var i = 0; i < eventCount; i++)
        ...() {
          final start = random.nextInt(_dataDays) * _dayMillis +
              random.nextInt(_dayMillis);
          final duration = Duration(minutes: 15 + random.nextInt(4 * 60));
          return {
            'event-${i.toString().padLeft(4, '0')}': {
              'start': start,
              'end': start + duration.inMilliseconds,
              'title': 'Event $i',
            },
          };
        }(),
    });
  }

  QueryFilter _lastBeforeDay(int dayStart) {
    return const QueryFilter().copyWith(
      orderBy: 'start',
      endAtValue: TreeStructuredData.fromJson(dayStart - 1),
      endAtKey: Name.max,
      limit: 1,
      reverse: true,
    );
  }

  QueryFilter _duringDay(int dayStart, int dayEnd) {
    return const QueryFilter().copyWith(
      orderBy: 'start',
      startAtValue: TreeStructuredData.fromJson(dayStart),
      startAtKey: Name.min,
      endAtValue: TreeStructuredData.fromJson(dayEnd),
      endAtKey: Name.max,
    );
  }

  QueryFilter _firstAfterDay(int dayEnd) {
    return const QueryFilter().copyWith(
      orderBy: 'start',
      startAtValue: TreeStructuredData.fromJson(dayEnd + 1),
      startAtKey: Name.min,
      limit: 1,
    );
  }

  List<QueryFilter> _calendarObserverFilters() {
    return [
      for (var day = 0; day < _queryDays; day++) ...[
        _lastBeforeDay(day * _dayMillis),
        _duringDay(day * _dayMillis, (day + 1) * _dayMillis - 1),
        _firstAfterDay((day + 1) * _dayMillis - 1),
      ],
    ];
  }
}

class _SyncTreeBenchmarkPlan {
  final List<QuerySpec> observerQueries;
  final Map<QuerySpec, TreeOperation> serverOverwrites;

  _SyncTreeBenchmarkPlan({
    required this.observerQueries,
    required this.serverOverwrites,
  });
}

class _SyncTreeBenchmarkHarness {
  final _SyncTreeBenchmarkPlan plan;
  final _TrackingQueryRegistrar registrar = _TrackingQueryRegistrar();
  late final SyncTree syncTree = SyncTree(
    'benchmark://synctree',
    queryRegistrar: registrar,
    persistenceManager: NoopPersistenceManager(),
  );

  _SyncTreeBenchmarkHarness(this.plan);

  void addObservers() {
    for (final query in plan.observerQueries) {
      _listen(query);
    }
  }

  int processPendingRegistrationsUntilStable(FakeAsync async) {
    var rounds = 0;
    while (registrar.pendingQueries.isNotEmpty) {
      rounds++;
      final queries = registrar.pendingQueries.toList();
      for (final entry in plan.serverOverwrites.entries) {
        syncTree.applyServerOperation(entry.value, entry.key);
      }
      registrar.completeListenAcks(queries);
      pump(async);
    }
    return rounds;
  }

  void pump(FakeAsync async) {
    async.flushMicrotasks();
    async.flushTimers();
    async.flushMicrotasks();
  }

  void dispose() {
    syncTree.destroy();
  }

  MasterView? completeViewForQuery(QuerySpec query) {
    final point = syncTree.root.subtreeNullable(query.path)?.value;
    if (point == null) return null;
    for (final view in point.views.values) {
      if (view.observers.containsKey(query.params) &&
          view.data.valueForFilter(query.params).isComplete) {
        return view;
      }
    }
    return null;
  }

  void _listen(QuerySpec query) {
    void listener(event) {}

    syncTree.addEventListener('value', query.path, query.params, listener);
  }
}

class _TrackingQueryRegistrar extends QueryRegistrar {
  final Set<QuerySpec> activeQueries = {};
  final List<QuerySpec> registrations = [];
  final Map<QuerySpec, Completer<bool>> pendingRegistrations = {};

  Iterable<QuerySpec> get pendingQueries => pendingRegistrations.keys;

  @override
  Future<bool> register(
    QuerySpec query, {
    required String hash,
    required int priority,
  }) {
    activeQueries.add(query);
    registrations.add(query);
    return (pendingRegistrations[query] ??= Completer<bool>()).future;
  }

  @override
  Future<void> unregister(QuerySpec query) async {
    throw UnimplementedError();
  }

  @override
  void revoke(QuerySpec query) {
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {}

  /// Completes the listen registration futures.
  ///
  /// The SyncTree registration callback turns these completions into
  /// `onRegistrationStateChanged(... registered)`, which calls
  /// `SyncTree.applyAckListen`. Keep this after the server value is applied.
  void completeListenAcks(Iterable<QuerySpec> queries) {
    for (final query in queries.toList()) {
      final completer = pendingRegistrations.remove(query);
      if (completer != null && !completer.isCompleted) {
        completer.complete(true);
      }
    }
  }
}
