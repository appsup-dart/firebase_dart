// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

calculateHash(obj) {
  if (obj is Map) {
    String toHash = "";
    // TODO priority hash
/*
    if (!this.getPriority().isEmpty()) {
      toHash += "priority:" + fb.core.snap.priorityHashText((this.getPriority().val())) + ":";
    }
*/
    obj.forEach((key, child) {
      var childHash = calculateHash(child);
      if (child != "") {
        toHash += ":" + key + ":" + childHash;
      }
    });
    return toHash == "" ? "" : BASE64.encode(sha1.convert(toHash.codeUnits).bytes);
  } else {
    var toHash = "";
/*
    if (!this.priorityNode_.isEmpty()) {
      toHash += "priority:" + fb.core.snap.priorityHashText((this.priorityNode_.val())) + ":";
    }
*/
    if (obj is num) {
      toHash += "number:${doubleToIEEE754String(obj)}";
    } else if (obj is bool) {
      toHash += "boolean:$obj";
    } else if (obj is String) {
      toHash += "string:$obj";
    }
    return BASE64.encode(sha1.convert(toHash.codeUnits).bytes);
  }
}

String doubleToIEEE754String(num v) {
  var l = new Float64List.fromList([v.toDouble()]);
  var hex = "";
  for (int i = 0; i < 8; i++) {
    var b = l.buffer.asByteData().getUint8(i).toRadixString(16);
    if (b.length==1) b = "0$b";
    hex = "$b$hex";
  }
  return hex;
}

