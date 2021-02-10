import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:firebase_dart/src/database/impl/connections/protocol.dart';
import 'package:sortedmap/sortedmap.dart';
import 'package:test/test.dart';

void main() {
  group('QueryFilterCodec', () {
    test('QueryFilterCodec.toJson()', () {
      expect(QueryFilter().toJson(), null);

      expect(QueryFilter(limit: 3).toJson(), {'l': 3, 'vf': 'l'});

      expect(QueryFilter(ordering: KeyOrdering()).toJson(), {'i': '.key'});
      expect(
          QueryFilter(
                  ordering: KeyOrdering(),
                  validInterval: KeyValueInterval(
                      Name('key-002'), TreeStructuredData(), null, null))
              .toJson(),
          {'i': '.key', 'sp': 'key-002'});
    });

    test('QueryFilterCodec.fromJson()', () {
      expect(QueryFilterCodec.fromJson(null), QueryFilter());

      expect(QueryFilterCodec.fromJson({'l': 3, 'vf': 'l'}),
          QueryFilter(limit: 3));

      expect(QueryFilterCodec.fromJson({'i': '.key'}),
          QueryFilter(ordering: KeyOrdering()));
      expect(
          QueryFilterCodec.fromJson({'i': '.key', 'sp': 'key-002'}),
          QueryFilter(
              ordering: KeyOrdering(),
              validInterval: KeyValueInterval(
                  Name('key-002'), TreeStructuredData(), null, null)));
    });
  });
}
