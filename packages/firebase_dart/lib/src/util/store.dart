abstract class Store<K, V> {
  Future<V?> get(K key);

  Future<V> set(K key, V value);

  Stream<V> get values;

  Stream<K> get keys;

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

  @override
  Stream<K> get keys => Stream.fromIterable(_memory.keys);
}
