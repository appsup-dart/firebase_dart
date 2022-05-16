// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.treestructureddata;

class _SpecialName extends Name {
  const _SpecialName(String value) : super._(value);

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) => [];

  @override
  Match? matchAsPrefix(String string, [int start = 0]) => null;

  @override
  int get length => 0;

  @override
  int? asInt() => null;
}

abstract class Name implements Pattern, Comparable<Name> {
  static const Name min = _SpecialName('[MIN_NAME]');
  static const Name max = _SpecialName('[MAX_NAME]');
  static const Name priorityKey = _SpecialName('.priority');

  final String _value;

  factory Name(String value) {
    if (value == '[MIN_NAME]') return min;
    if (value == '[MAX_NAME]') return max;
    if (value == '.priority') return priorityKey;
    return _NameImpl(value);
  }

  const Name._(this._value);

  @override
  String toString() => _value;

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) =>
      _value.allMatches(string, start);

  @override
  Match? matchAsPrefix(String string, [int start = 0]) =>
      _value.matchAsPrefix(string, start);

  @override
  int get hashCode => Object.hash(this is _SpecialName, _value.hashCode);

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    return other is Name &&
        (this is _SpecialName == other is _SpecialName) &&
        other._value == _value;
  }

  @override
  int compareTo(Name other) => compare(this, other);

  String asString() => _value;

  int? asInt();

  int get length => _value.length;

  static int compare(Name a, Name b) {
    if (a == b) {
      return 0;
    } else {
      if (a == min || b == max) {
        return -1;
      }
      if (b == min || a == max) {
        return 1;
      }

      var aAsInt = a.asInt();
      var bAsInt = b.asInt();
      if (aAsInt != null) {
        if (bAsInt != null) {
          return aAsInt - bAsInt == 0 ? a.length - b.length : aAsInt - bAsInt;
        } else {
          return -1;
        }
      } else {
        if (bAsInt != null) {
          return 1;
        } else {
          return a._value.compareTo(b._value);
        }
      }
    }
  }

  static Path<Name> parsePath(String path) {
    return Path<Name>.from(
        path.split('/').where((v) => v.isNotEmpty).map<Name>((v) => Name(v)));
  }
}

class _NameImpl extends Name {
  /// For use in keys, the minimum possible 32-bit integer.
  static const min32bitInteger = -2147483648;

  /// For use in kyes, the maximum possible 32-bit integer.
  static const max32bitInteger = 2147483647;

  _NameImpl(String value) : super._(value);

  late final int? _intValue = int.tryParse(_value);

  /// If the string contains a 32-bit integer, return it.  Else return null.
  @override
  int? asInt() {
    var intValue = _intValue;
    if (intValue != null) {
      if (intValue >= min32bitInteger && intValue <= max32bitInteger) {
        return intValue;
      }
    }
    return null;
  }
}
