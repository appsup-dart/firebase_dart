import 'package:firebase_dart/src/implementation/isolate/util.dart';
import 'package:firebase_dart/src/util/store.dart';

class IsolateStore<K, V> extends Store<K, V> {
  final IsolateCommander commander;

  IsolateStore(this.commander);

  factory IsolateStore.forStore(Store<K, V> store) {
    var worker = IsolateWorker()
      ..registerFunction(#get, store.get)
      ..registerFunction(#set, store.set)
      ..registerFunction(#remove, store.remove)
      ..registerFunction(#values, () => store.values.toList())
      ..registerFunction(#keys, () => store.keys.toList());
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

  @override
  Stream<K> get keys async* {
    yield* Stream.fromIterable(
        await commander.execute(RegisteredFunctionCall(#keys, [])));
  }
}
