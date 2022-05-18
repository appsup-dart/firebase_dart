import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:expressions/expressions.dart';
import 'package:firebase_dart/src/database/impl/events/cancel.dart';
import 'package:firebase_dart/src/database/impl/events/value.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:rxdart/rxdart.dart';

import '../backend_connection.dart';

class SecurityTree {
  final ModifiableTreeNode<String, SecurityNode> root;

  SecurityTree._(this.root);
  factory SecurityTree.fromJson(Map<String, dynamic> json) {
    ModifiableTreeNode<String, SecurityNode> process(
        Map<String, dynamic> json) {
      var n = SecurityNode(
        indexOn: json.remove('.indexOn') ?? [],
        read: Expression.parse(json.remove('.read') ?? 'false'),
        write: Expression.parse(json.remove('.write') ?? 'false'),
        validate: Expression.parse(json.remove('.validate') ?? 'true'),
      );

      return ModifiableTreeNode(n, json.map((k, v) => MapEntry(k, process(v))));
    }

    return SecurityTree._(process(json));
  }

  Stream<bool> canRead(
      {RuleDataSnapshot? root, required String path, Auth? auth}) {
    return CombineLatestStream<bool?, bool>(
        _canReadStreams(root: root, path: path, auth: auth), (l) {
      return l.any((element) => element ?? false);
    });
  }

  Iterable<Stream<bool?>> _canReadStreams(
      {RuleDataSnapshot? root, required String path, Auth? auth}) sync* {
    var p = Name.parsePath(path);

    var tree = this.root;

    var data = root;

    var locations = <String, String>{};

    yield tree.value
        .canRead(root: root, data: data, auth: auth, locations: locations);
    for (var n in p) {
      var node = tree.children[n.asString()];
      if (node == null) {
        var l = tree.children.keys.firstWhereOrNull((v) => v.startsWith(r'$'));
        if (!tree.children.containsKey(l)) {
          return;
        }
        node = tree.children[l]!;
        locations[l!] = n.asString();
      }
      tree = node;

      data = data!.child(BehaviorSubject.seeded(n.asString()));

      yield node.value
          .canRead(root: root, data: data, auth: auth, locations: locations);
    }
  }
}

class SecurityNode {
  final Expression read;
  final Expression write;
  final Expression validate;
  final List<String> indexOn;

  SecurityNode(
      {required this.read,
      required this.write,
      required this.validate,
      required this.indexOn});

  Stream<bool?> canRead(
      {RuleDataSnapshot? root,
      RuleDataSnapshot? data,
      Auth? auth,
      required Map<String, String> locations}) {
    return (const _ExpressionEvaluator().eval(read, {
      'root': root,
      'data': data,
      'now': DateTime.now().millisecondsSinceEpoch,
      'auth': auth,
      ...locations
    }) as Stream)
        .cast<bool?>();
  }
}

class _ExpressionEvaluator extends ExpressionEvaluator {
  const _ExpressionEvaluator();

  @override
  dynamic eval(Expression expression, Map<String, dynamic> context) {
    var v = super.eval(expression, context);

    if (v == null) {
      return Stream<void>.value(null);
    }
    if (v is bool) {
      return Stream<bool>.value(v);
    }
    if (v is num) {
      return Stream<num>.value(v);
    }
    if (v is String) {
      return Stream<String>.value(v);
    }
    if (v is Auth) {
      return Stream<Auth>.value(v);
    }
    return v;
  }

  @override
  dynamic evalBinaryExpression(
      BinaryExpression expression, Map<String, dynamic> context) {
    var left = eval(expression.left, context);
    var right = eval(expression.right, context);

    if (left is Stream<bool> && right is Stream<bool>) {
      switch (expression.operator) {
        case '||':
          return CombineLatestStream.combine2<bool, bool, bool>(
              left, right, (a, b) => a || b);
        case '&&':
          return CombineLatestStream.combine2<bool, bool, bool>(
              left, right, (a, b) => a && b);
      }
    }
    if (left is Stream<String> && right is Stream<String>) {
      switch (expression.operator) {
        case '+':
          return CombineLatestStream.combine2<String, String, String>(
              left, right, (a, b) => a + b);
      }
    }
    if (left is Stream<num> && right is Stream<num>) {
      switch (expression.operator) {
        case '+':
          return CombineLatestStream.combine2<num, num, num>(
              left, right, (a, b) => a + b);
        case '-':
          return CombineLatestStream.combine2<num, num, num>(
              left, right, (a, b) => a - b);
        case '*':
          return CombineLatestStream.combine2<num, num, num>(
              left, right, (a, b) => a * b);
        case '/':
          return CombineLatestStream.combine2<num, num, num>(
              left, right, (a, b) => a / b);
        case '%':
          return CombineLatestStream.combine2<num, num, num>(
              left, right, (a, b) => a % b);
        case '>':
          return CombineLatestStream.combine2<num, num, bool>(
              left, right, (a, b) => a > b);
        case '<':
          return CombineLatestStream.combine2<num, num, bool>(
              left, right, (a, b) => a < b);
        case '>=':
          return CombineLatestStream.combine2<num, num, bool>(
              left, right, (a, b) => a >= b);
        case '<=':
          return CombineLatestStream.combine2<num, num, bool>(
              left, right, (a, b) => a <= b);
      }
    }
    if (left is Stream && right is Stream) {
      switch (expression.operator) {
        case '==':
          return CombineLatestStream.combine2<dynamic, dynamic, bool>(
              left, right, (a, b) => a == b);
        case '!=':
          return CombineLatestStream.combine2<dynamic, dynamic, bool>(
              left, right, (a, b) => a != b);
      }
    }
    throw ArgumentError(
        'Unexpected operands $left and $right for operator ${expression.operator}');
  }

  @override
  dynamic evalUnaryExpression(
      UnaryExpression expression, Map<String, dynamic> context) {
    var argument = eval(expression.argument, context);

    if (argument is Stream<bool>) {
      switch (expression.operator) {
        case '!':
          return argument.map((v) => !v);
      }
    } else if (argument is Stream<num>) {
      switch (expression.operator) {
        case '-':
          return argument.map((v) => -v);
      }
    }
    throw ArgumentError(
        'Unexpected operands $argument for operator ${expression.operator}');
  }

  @override
  dynamic evalMemberExpression(
      MemberExpression expression, Map<String, dynamic> context) {
    var v = eval(expression.object, context);

    var name = expression.property.name;
    if (v is RuleDataSnapshot) {
      switch (name) {
        case 'val':
          return v.val;
        case 'child':
          return v.child;
        case 'parent':
          return v.parent;
        case 'hasChild':
          return v.hasChild;
        case 'hasChildren':
          return v.hasChildren;
        case 'exists':
          return v.exists;
        case 'getPriority':
          return v.getPriority;
        case 'isNumber':
          return v.isNumber;
        case 'isString':
          return v.isString;
        case 'isBoolean':
          return v.isBoolean;
      }
    } else if (v is Auth) {
      switch (name) {
        case 'provider':
          return v.provider;
        case 'uid':
          return v.uid;
        case 'token':
          return v.token;
      }
    } else if (v is Map) {
      return v[name];
    } else if (v is Stream) {
//      return v.map((v)=>)
    }

    return super.evalMemberExpression(expression, context);
  }
}

abstract class RuleDataSnapshot {
  final Stream<String> _path;

  RuleDataSnapshot._(this._path);

  /// Gets the primitive value (string, number, boolean, or null) from this
  /// [RuleDataSnapshot].
  ///
  /// Calling val() on a [RuleDataSnapshot] that has child data will not return
  /// an object containing the children. It will instead return a special
  /// sentinel value. This ensures the rules can always operate extremely
  /// efficiently.
  ///
  /// As a consequence, you must always use child() to access children (e.g.
  /// data.child('name').val(), not data.val().name).
  Stream<dynamic> val() => _val().map((v) {
        if (v.isNil) return null;
        if (v.isLeaf) return v.value!.value;
        return const SentinalObjectValue._();
      });

  /// Gets a [RuleDataSnapshot] for the location at the specified relative path.
  ///
  /// The relative path can either be a simple child name (e.g. 'fred') or a
  /// deeper slash-separated path (e.g. 'fred/name/first'). If the child
  /// location has no data, an empty RuleDataSnapshot is returned.
  RuleDataSnapshot child(Stream<String> childPath) =>
      withPath(_path.switchMap((v) {
        return childPath.map((childPath) {
          if (childPath.startsWith('/')) childPath = childPath.substring(1);
          if (childPath.endsWith('/')) {
            childPath = childPath.substring(0, childPath.length - 1);
          }
          if (v == '/') return '/$childPath';
          return '$v/$childPath';
        });
      }));

  /// Gets a RuleDataSnapshot for the parent location.
  ///
  /// If this instance refers to the root of your Firebase Realtime Database, it
  /// has no parent, and parent() will fail, causing the current rule expression
  /// to be skipped (as a failure).
  RuleDataSnapshot parent() => withPath(_path.map((v) {
        if (v == '/') throw StateError('Root has no parent');
        return v.substring(0, v.lastIndexOf('/'));
      }));

  /// Returns true if the specified child exists.
  Stream<bool> hasChild(String childPath) => _val().map((v) {
        v = v.subtreeNullable(Name.parsePath(childPath)) as TreeStructuredData;
        return (!v.isNil);
      });

  /// Checks for the existence of children.
  ///
  /// If no arguments are provided, it will return true if the [RuleDataSnapshot]
  /// has any children. If an array of child names is provided, it will return
  /// true only if all of the specified children exist in the RuleDataSnapshot.
  Stream<bool> hasChildren([List<String>? children]) => _val().map((v) {
        if (v.isEmpty) return false;
        return children!
            .map((v) => Name(v))
            .every((element) => v.children.containsKey(element));
      });

  /// Returns true if this RuleDataSnapshot contains any data.
  ///
  /// The exists function returns true if this [RuleDataSnapshot] contains any
  /// data. It is purely a convenience function since data.exists() is
  /// equivalent to data.val() != null.
  Stream<bool> exists() => val().map((v) => v != null);

  /// Gets the priority of the data in a [RuleDataSnapshot].
  Stream<dynamic> getPriority() => _val().map((v) => v.priority!.value);

  /// Returns true if this [RuleDataSnapshot] contains a numeric value.
  Stream<bool> isNumber() => val().map((v) => v is num);

  /// Returns true if this [RuleDataSnapshot] contains a string value.
  Stream<bool> isString() => val().map((v) => v is String);

  /// Returns true if this [RuleDataSnapshot] contains a boolean value.
  Stream<bool> isBoolean() => val().map((v) => v is bool);

  Stream<TreeStructuredData> _val();

  RuleDataSnapshot withPath(Stream<String> path);
}

class RuleDataSnapshotFromBackend extends RuleDataSnapshot {
  final Backend backend;

  RuleDataSnapshotFromBackend(this.backend, Stream<String> path)
      : super._(path);

  RuleDataSnapshotFromBackend.root(this.backend)
      : super._(BehaviorSubject.seeded('/')); // TODO check
  @override
  Stream<TreeStructuredData> _val() {
    return _path.switchMap((path) {
      var controller = StreamController<TreeStructuredData>();
      void listener(event) {
        if (event is ValueEvent<TreeStructuredData>) {
          controller.add(event.value);
        } else if (event is CancelEvent) {
          controller.addError(event.error!, event.stackTrace);
        } else {
          throw ArgumentError('Unexpected event type ${event.runtimeType}');
        }
      }

      controller
        ..onListen = () {
          backend.listen(path, listener);
        }
        ..onCancel = () {
          backend.unlisten(path, listener);
        };
      return controller.stream;
    });
  }

  @override
  RuleDataSnapshot withPath(Stream<String> path) =>
      RuleDataSnapshotFromBackend(backend, path);
}

class SentinalObjectValue {
  const SentinalObjectValue._();
}

class Auth {
  /// The authentication method used (e.g "password", "anonymous", "facebook",
  /// "github", "google", or "twitter").
  final String provider;

  /// A unique user id, guaranteed to be unique across all providers.
  final String uid;

  /// The contents of the Firebase Auth ID token.
  final Map<String, dynamic> token;

  Auth({required this.provider, required this.uid, required this.token});
}
