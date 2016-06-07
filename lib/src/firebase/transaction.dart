// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase_dart;

class TransactionResult {
  final Object error;
  final bool committed;
  final DataSnapshot snapshot;

  TransactionResult(this.error, this.committed, this.snapshot);
}