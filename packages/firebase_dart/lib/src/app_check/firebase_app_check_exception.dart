import 'package:firebase_dart/src/core/exception.dart';

/// Failure while obtaining an App Check token.
class FirebaseAppCheckException extends FirebaseException {
  FirebaseAppCheckException({
    required super.code,
    super.message,
    List<Object> causes = const [],
  })  : causes = List.unmodifiable(causes),
        super(plugin: 'app-check');

  /// Provider or exchange errors that led to this failure.
  final List<Object> causes;

  @override
  String toString() {
    final summary = '[$plugin/$code] $message';
    if (causes.isEmpty) return summary;
    return '$summary: ${causes.join('; ')}';
  }
}
