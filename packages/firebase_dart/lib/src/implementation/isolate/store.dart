import 'package:firebase_dart/src/implementation/isolate/util.dart';

abstract class Store<K, V> {
  Future<V?> get(K key);

  Future<V> set(K key, V value);

  Stream<V> get values;

  Future<V?> remove(K key);
}

class MemoryStore<K, V> extends Store<K, V> {
  final Map<K, V> _memory = {};

  @override
  Future<V?> get(K key) async => _memory[key];

  @override
  Future<V> set(K key, V value) async => _memory[key] = value;

  @override
  Stream<V> get values => Stream.fromIterable(_memory.values);

  @override
  Future<V?> remove(K key) async => _memory.remove(key);
}

class IsolateStore<K, V> extends Store<K, V> {
  final IsolateCommander commander;

  IsolateStore(this.commander);

  factory IsolateStore.forStore(Store<K, V> store) {
    var worker = IsolateWorker()
      ..registerFunction(#get, store.get)
      ..registerFunction(#set, store.set)
      ..registerFunction(#remove, store.remove)
      ..registerFunction(#values, () => store.values.toList());
    return IsolateStore(worker.commander);
  }

  @override
  Future<V?> get(K key) {
    return commander.execute(RegisteredFunctionCall(#get, [key]));
  }

  @override
  Future<V> set(K key, V value) {
    return commander.execute(RegisteredFunctionCall(#set, [key, value]));
  }

  @override
  Future<V?> remove(K key) {
    return commander.execute(RegisteredFunctionCall(#remove, [key]));
  }

  @override
  Stream<V> get values async* {
    yield* Stream.fromIterable(
        await commander.execute(RegisteredFunctionCall(#values, [])));
  }
}
