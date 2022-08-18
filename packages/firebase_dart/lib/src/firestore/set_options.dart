part of firebase_dart.firestore;

/// An options class that configures the behavior of set() calls in [DocumentReference],
/// [WriteBatch] and [Transaction].
class SetOptions {
  /// Creates a [SetOptions] instance.
  SetOptions({
    this.merge,
    List<Object>? mergeFields,
  })  : assert(
          (merge != null) ^ (mergeFields != null),
          "options must provide either 'merge' or 'mergeFields'",
        ),
        mergeFields = mergeFields?.map((field) {
          assert(
            field is String || field is FieldPath,
            '[mergeFields] can only contain Strings or FieldPaths but got $field',
          );

          if (field is String) return FieldPath.fromString(field);
          return field as FieldPath;
        }).toList(growable: false);

  /// Changes the behavior of a set() call to only replace the values specified
  /// in its data argument.
  ///
  /// Fields omitted from the set() call remain untouched.
  final bool? merge;

  /// Changes the behavior of set() calls to only replace the specified field paths.
  ///
  /// Any field path that is not specified is ignored and remains untouched.
  final List<FieldPath>? mergeFields;
}
