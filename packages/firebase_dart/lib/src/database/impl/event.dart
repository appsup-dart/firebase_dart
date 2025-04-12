// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:clock/clock.dart';
import 'package:firebase_dart/src/database/impl/data_observer.dart';

import 'operations/tree.dart';

abstract class Event {
  late EventTarget _target;

  final String type;

  Event(this.type);

  EventTarget get target => _target;
}

typedef EventListener = void Function(Event event);

class EventTarget {
  final Map<String, Set<EventListener>> _eventRegistrations = {};

  DateTime? _emptyListenersSince = clock.now();

  DateTime? get emptyListenersSince => _emptyListenersSince;

  bool get hasEventRegistrations =>
      _eventRegistrations.values.any((v) => v.isNotEmpty);

  Iterable<String> get eventTypesWithRegistrations =>
      _eventRegistrations.keys.where((k) => _eventRegistrations[k]!.isNotEmpty);

  final Map<EventListener, IncompleteData> _valuesNotified = {};

  void notifyDataChanged(IncompleteData newValue) {
    if (hasEventRegistrations) {
      for (var t in eventTypesWithRegistrations) {
        var cache = <IncompleteData, List<Event>>{};

        for (var l in _eventRegistrations[t]!) {
          var oldValue = _valuesNotified[l] ?? IncompleteData.empty();
          if (!newValue.isComplete && oldValue.isComplete) continue;
          var events = cache[oldValue] ??
              const TreeEventGenerator().generateEvents(t, oldValue, newValue);

          for (var e in events) {
            l(e);
          }
          _valuesNotified[l] = newValue;
        }
      }
    }
  }

  void dispatchEvent(Event event) {
    event._target = this;
    if (!_eventRegistrations.containsKey(event.type)) return;
    _eventRegistrations[event.type]!.toList().forEach((l) => l(event));
  }

  void addEventListener(
      String type, EventListener listener, IncompleteData value) {
    _eventRegistrations
        .putIfAbsent(type, () => <void Function(Event)>{})
        .add(listener);
    _emptyListenersSince = null;

    var events = const TreeEventGenerator()
        .generateEvents(type, IncompleteData.empty(), value);
    events.where((e) => e.type == type).forEach((e) => listener(e));
    _valuesNotified[listener] = value;
  }

  void removeEventListener(String type, EventListener? listener) {
    if (listener == null) {
      _eventRegistrations.remove(type);
    } else {
      _eventRegistrations
          .putIfAbsent(type, () => <void Function(Event)>{})
          .remove(listener);
    }
    _valuesNotified.remove(listener);
    if (!hasEventRegistrations) {
      _emptyListenersSince = clock.now();
    }
  }
}
