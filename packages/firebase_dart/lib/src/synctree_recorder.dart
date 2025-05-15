import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:firebase_dart/src/database/impl/event.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:sortedmap/sortedmap.dart';

import 'database/impl/data_observer.dart';
import 'database/impl/synctree.dart';

class SyncTreeRecording {
  List<SyncTreeOperation> events = [];

  SyncTreeRecording({List<SyncTreeOperation>? events}) : events = events ?? [];

  @override
  String toString() {
    return 'SyncTreeRecording{events: $events}';
  }

  String toCode() {
    var buffer = StringBuffer();
    buffer.writeln('SyncTreeRecording(');
    buffer.writeln('  events: [');
    for (var e in events) {
      buffer.writeln('    ${e.toCode()},');
    }
    buffer.writeln('  ]');
    buffer.writeln(')');
    return buffer.toString();
  }

  @override
  int get hashCode => const ListEquality().hash(events);

  @override
  bool operator ==(Object other) =>
      other is SyncTreeRecording &&
      const ListEquality().equals(events, other.events);
}

class SyncTreeRecorder extends SyncTree {
  List<SyncTreeOperation>? _events;

  SyncTreeRecorder(super.name,
      {super.queryRegistrar, super.persistenceManager});

  void startRecording() {
    _events = [];
  }

  SyncTreeRecording stopRecording() {
    final recording = SyncTreeRecording(events: _events ?? []);
    _events = null;
    return recording;
  }

  @override
  Future<void> addEventListener(String type, Path<Name> path,
      QueryFilter filter, EventListener listener) {
    _events?.add(SyncTreeOperation.listen(
        QuerySpec(path, filter), type, listener.hashCode));
    return super.addEventListener(type, path, filter, listener);
  }

  @override
  Future<void> removeEventListener(String type, Path<Name> path,
      QueryFilter filter, EventListener listener) {
    _events?.add(SyncTreeOperation.unlisten(
        QuerySpec(path, filter), type, listener.hashCode));
    return super.removeEventListener(type, path, filter, listener);
  }

  @override
  void applyAckListen(Path<Name> path, QueryFilter filter) {
    _events?.add(SyncTreeOperation.ackListen(QuerySpec(path, filter)));
    super.applyAckListen(path, filter);
  }

  @override
  void applyAckUnlisten(Path<Name> path, QueryFilter filter) {
    _events?.add(SyncTreeOperation.ackUnlisten(QuerySpec(path, filter)));
    super.applyAckUnlisten(path, filter);
  }

  @override
  void applyAck(Path<Name> path, int writeId, bool success) {
    if (success) {
      _events?.add(SyncTreeOperation.ackWrite(path, writeId));
    } else {
      _events?.add(SyncTreeOperation.revertWrite(path, writeId));
    }
    super.applyAck(path, writeId, success);
  }

  @override
  void applyListenRevoked(Path<Name> path, QueryFilter? filter) {
    _events?.add(SyncTreeOperation.listenRevoked(
        QuerySpec(path, filter ?? QueryFilter())));
    super.applyListenRevoked(path, filter);
  }

  @override
  void applyServerOperation(TreeOperation operation, QuerySpec? query) {
    _events?.add(SyncTreeOperation.serverOperation(operation, query));
    super.applyServerOperation(operation, query);
  }

  @override
  void applyUpgrade(Path<Name> path, QueryFilter filter) {
    _events?.add(SyncTreeOperation.upgrade(QuerySpec(path, filter)));
    super.applyUpgrade(path, filter);
  }

  @override
  void applyUserOperation(TreeOperation operation, int writeId) {
    _events?.add(SyncTreeOperation.operation(operation, writeId));
    super.applyUserOperation(operation, writeId);
  }
}

enum SyncTreeOperationType {
  listen,
  unlisten,
  operation,
  ackListen,
  ackUnlisten,
  listenRevoked,
  upgrade,
  ackWrite,
  revertWrite,
  serverOperation
}

class SyncTreeOperation {
  final SyncTreeOperationType type;

  final QuerySpec? query;

  final TreeOperation? operation;

  final int? listenerId;

  final String? listenType;

  final int? writeId;

  SyncTreeOperation.listen(this.query, this.listenType, this.listenerId)
      : operation = null,
        writeId = null,
        type = SyncTreeOperationType.listen;
  SyncTreeOperation.unlisten(this.query, this.listenType, this.listenerId)
      : operation = null,
        writeId = null,
        type = SyncTreeOperationType.unlisten;
  SyncTreeOperation.operation(this.operation, this.writeId)
      : query = null,
        listenType = null,
        listenerId = null,
        type = SyncTreeOperationType.operation;
  SyncTreeOperation.ackListen(this.query)
      : operation = null,
        writeId = null,
        listenType = null,
        listenerId = null,
        type = SyncTreeOperationType.ackListen;
  SyncTreeOperation.ackUnlisten(this.query)
      : operation = null,
        writeId = null,
        listenType = null,
        listenerId = null,
        type = SyncTreeOperationType.ackUnlisten;
  SyncTreeOperation.ackWrite(Path<Name> path, this.writeId)
      : operation = null,
        listenerId = null,
        listenType = null,
        query = QuerySpec(path, QueryFilter()),
        type = SyncTreeOperationType.ackWrite;
  SyncTreeOperation.revertWrite(Path<Name> path, this.writeId)
      : operation = null,
        listenType = null,
        listenerId = null,
        query = QuerySpec(path, QueryFilter()),
        type = SyncTreeOperationType.revertWrite;
  SyncTreeOperation.serverOperation(this.operation, this.query)
      : listenType = null,
        listenerId = null,
        writeId = null,
        type = SyncTreeOperationType.serverOperation;
  SyncTreeOperation.listenRevoked(this.query)
      : operation = null,
        writeId = null,
        listenType = null,
        listenerId = null,
        type = SyncTreeOperationType.listenRevoked;
  SyncTreeOperation.upgrade(this.query)
      : writeId = null,
        listenType = null,
        listenerId = null,
        operation = null,
        type = SyncTreeOperationType.upgrade;

  @override
  String toString() {
    return 'SyncTreeOperation{type: $type, query: $query, operation: $operation}';
  }

  String toCode() {
    switch (type) {
      case SyncTreeOperationType.listen:
        return 'SyncTreeOperation.listen(${query!.toCode()}, \'$listenType\', $listenerId)';
      case SyncTreeOperationType.unlisten:
        return 'SyncTreeOperation.unlisten(${query!.toCode()}, \'$listenType\', $listenerId)';
      case SyncTreeOperationType.operation:
        return 'SyncTreeOperation.operation(${operation!.toCode()}, $writeId)';
      case SyncTreeOperationType.ackListen:
        return 'SyncTreeOperation.ackListen(${query!.toCode()})';
      case SyncTreeOperationType.ackUnlisten:
        return 'SyncTreeOperation.ackUnlisten(${query!.toCode()})';
      case SyncTreeOperationType.ackWrite:
        return 'SyncTreeOperation.ackWrite(${query!.path.toCode()}, $writeId)';
      case SyncTreeOperationType.revertWrite:
        return 'SyncTreeOperation.revertWrite(${query!.path.toCode()}, $writeId)';
      case SyncTreeOperationType.serverOperation:
        return 'SyncTreeOperation.serverOperation(${operation!.toCode()}, ${query!.toCode()})';
      case SyncTreeOperationType.listenRevoked:
        return 'SyncTreeOperation.listenRevoked(${query!.toCode()})';
      case SyncTreeOperationType.upgrade:
        return 'SyncTreeOperation.upgrade(${query!.toCode()})';
    }
  }

  @override
  int get hashCode =>
      Object.hash(type, query, operation, listenerId, writeId, listenType);

  @override
  bool operator ==(Object other) =>
      other is SyncTreeOperation &&
      other.type == type &&
      other.query == query &&
      other.operation == operation &&
      other.listenerId == listenerId &&
      other.writeId == writeId &&
      other.listenType == listenType;
}

extension QuerySpecCodeX on QuerySpec {
  String toCode() {
    return 'QuerySpec(${path.toCode()}, ${params.toCode()})';
  }
}

extension PathCodeX on Path<Name> {
  String toCode() {
    return 'Path.from([${map((v) => v.toCode()).join(', ')}])';
  }
}

extension NameCodeX on Name {
  String toCode() {
    return 'Name(\'$this\')';
  }
}

extension QueryFilterCodeX on QueryFilter {
  String toCode() {
    return 'QueryFilter(ordering: ${ordering.toCode()}, limit: $limit, reversed: $reversed, validInterval: ${validInterval.toCode()})';
  }
}

extension OrderingCodeX on Ordering {
  String toCode() {
    if (this is KeyOrdering) {
      return 'KeyOrdering()';
    } else if (this is PriorityOrdering) {
      return 'PriorityOrdering()';
    } else if (this is ValueOrdering) {
      return 'ValueOrdering()';
    } else {
      return 'ChildOrdering(\'${(this as ChildOrdering).child}\')';
    }
  }
}

extension KeyValueIntervalCodeX on KeyValueInterval {
  String toCode() {
    return 'KeyValueInterval(${(start.key as Name?)?.toCode()}, ${(start.value as TreeStructuredData?)?.toCode()}, ${(end.key as Name?)?.toCode()}, ${(end.value as TreeStructuredData?)?.toCode()})';
  }
}

extension TreeOperationCodeX on TreeOperation {
  String toCode() {
    return 'TreeOperation(${path.toCode()}, ${nodeOperation?.toCode()})';
  }
}

extension OperationCodeX on Operation {
  String toCode() {
    if (this is Overwrite) {
      return 'Overwrite(${(this as Overwrite).value.toCode()})';
    } else if (this is Merge) {
      return 'Merge.fromOperations([${(this as Merge).overwrites.map((o) => o.toCode()).join(', ')}])';
    } else {
      return 'SetPriority(${(this as SetPriority).value.toCode()})';
    }
  }
}

extension TreeStructuredDataCodeX on TreeStructuredData {
  String toCode() {
    return 'TreeStructuredData.fromJson(${json.encode(toJson(true))})';
  }
}
