import 'package:firebase_dart/database.dart' show FirebaseDatabaseException;

import '../event.dart';

class CancelEvent extends Event {
  final FirebaseDatabaseException? error;

  final StackTrace? stackTrace;

  CancelEvent(this.error, this.stackTrace) : super('cancel');
}
