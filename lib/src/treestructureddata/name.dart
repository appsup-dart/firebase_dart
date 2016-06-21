// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.treestructureddata;

class _SpecialName extends Name {
  const _SpecialName(String value) : super(value);

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) => [];

  @override
  Match matchAsPrefix(String string, [int start = 0]) => null;

  @override
  int get length => 0;
}

class Name implements Pattern, Comparable<Name> {
  static const Name min = const _SpecialName("[MIN_NAME]");
  static const Name max = const _SpecialName("[MAX_NAME]");

  final String _value;

  const Name(this._value);

  @override
  String toString() => _value;

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) =>
      _value.allMatches(string, start);

  @override
  Match matchAsPrefix(String string, [int start = 0]) =>
      _value.matchAsPrefix(string, start);

  @override
  int get hashCode => hash2(this is _SpecialName, _value.hashCode);

  @override
  bool operator ==(dynamic other) =>
      other is Name &&
      (this is _SpecialName == other is _SpecialName) &&
      other._value == _value;

  @override
  int compareTo(Name other) => compare(this, other);

  String asString() => _value;
  int asInt() => int.parse(_value, onError: (_) => null);

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
    return new Path<Name>.from(path
        .split("/")
        .where((v) => v.isNotEmpty)
        .map/*<Name>*/((v) => new Name(v)));
  }
}
