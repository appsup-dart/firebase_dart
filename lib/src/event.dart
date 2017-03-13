// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

class Event {
  EventTarget _target;

  final String type;

  Event(this.type);

  EventTarget get target => _target;
}

typedef void EventListener(Event event);

class EventTarget {
  final Map<String, Set<EventListener>> _eventRegistrations = {};

  bool get hasEventRegistrations =>
      _eventRegistrations.values.any((v) => v.isNotEmpty);
  Iterable<String> get eventTypesWithRegistrations =>
      _eventRegistrations.keys.where((k) => _eventRegistrations[k].isNotEmpty);

  void dispatchEvent(Event event) {
    event._target = this;
    if (!_eventRegistrations.containsKey(event.type)) return;
    _eventRegistrations[event.type].toList().forEach((l) => l(event));
  }

  void addEventListener(String type, EventListener listener) {
    _eventRegistrations.putIfAbsent(type, () => new Set()).add(listener);
  }

  void removeEventListener(String type, EventListener listener) {
    if (listener==null) {
      _eventRegistrations.remove(type);
    } else {
      _eventRegistrations.putIfAbsent(type, () => new Set()).remove(listener);
    }
  }
}
