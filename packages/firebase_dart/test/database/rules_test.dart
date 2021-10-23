import 'package:firebase_dart/src/database/impl/backend_connection/rules.dart';
import 'package:firebase_dart/src/database/impl/memory_backend.dart';
import 'package:test/test.dart';

void main() {
  group('SecurityTree', () {
    var backend = UnsecuredMemoryBackend();
    var root = RuleDataSnapshotFromBackend.root(backend);

    group('SecurityTree.canRead', () {
      test('Allows read when expression = `true` on root', () async {
        var tree = SecurityTree.fromJson({
          '.read': 'true',
          'persons': {'.read': 'false'}
        });

        testRead(tree: tree, root: root, auth: null, paths: {
          '/': true,
          '/persons': true,
          '/persons/jane-doe': true,
        });
      });
      test('Allows read when expression = `true` on parent', () async {
        var tree = SecurityTree.fromJson({
          'persons': {'.read': 'true'}
        });

        testRead(tree: tree, root: root, auth: null, paths: {
          '/': false,
          '/persons': true,
          '/persons/jane-doe': true,
        });
      });

      test('Allows read when expression evaluates to true', () async {
        await backend.put('/', {
          'persons': {
            'public-person': {'isPublic': true}
          }
        });
        var tree = SecurityTree.fromJson({
          'persons': {
            r'$personId': {'.read': "data.child('isPublic').val()"}
          }
        });

        testRead(tree: tree, root: root, auth: null, paths: {
          '/': false,
          '/persons': false,
          '/persons/jane-doe': false,
          '/persons/public-person': true,
        });
      });

      test('Allows read with expression using auth', () async {
        var tree = SecurityTree.fromJson({
          '.read': 'auth!=null',
        });

        testRead(
            tree: tree,
            root: root,
            auth: Auth(provider: 'password', uid: 'me', token: {}),
            paths: {
              '/': true,
              '/persons': true,
              '/persons/jane-doe': true,
            });

        testRead(tree: tree, root: root, auth: null, paths: {
          '/': false,
          '/persons': false,
          '/persons/jane-doe': false,
        });
      });
    });
  });
}

void testRead(
    {SecurityTree? tree,
    RuleDataSnapshot? root,
    Auth? auth,
    required Map<String, bool> paths}) async {
  for (var p in paths.keys) {
    var v = await tree!.canRead(root: root, path: p, auth: auth).first;
    expect(v, paths[p]);
  }
}
