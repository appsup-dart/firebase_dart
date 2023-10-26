part of firebase_dart;

class FirebaseDatabaseException extends FirebaseException {
  final String? details;

  FirebaseDatabaseException(
      {required String code, String? message, this.details})
      : super(plugin: 'database', code: code, message: message);

  /// Thrown when the transaction needs to be run again with current data
  ///
  /// For internal use only.
  FirebaseDatabaseException.dataStale()
      : this(
            code: 'datastale',
            message: 'The transaction needs to be run again with current data');

  /// Thrown when the server indicated that this operation failed
  FirebaseDatabaseException.operationFailed()
      : this(
            code: 'failure',
            message: 'The server indicated that this operation failed');

  /// Thrown when this client does not have permission to perform this operation
  FirebaseDatabaseException.permissionDenied()
      : this(
            code: 'permission_denied',
            message:
                'This client does not have permission to perform this operation');

  /// Thrown when the operation had to be aborted due to a network disconnect
  FirebaseDatabaseException.disconnected()
      : this(
            code: 'disconnected',
            message:
                'The operation had to be aborted due to a network disconnect');

  /// Thrown when the supplied auth token has expired
  FirebaseDatabaseException.expiredToken()
      : this(
            code: 'expired_token',
            message: 'The supplied auth token has expired');

  /// Thrown when the specified authentication token is invalid.
  ///
  /// This can occur when the token is malformed, expired, or the secret that
  /// was used to generate it has been revoked.
  FirebaseDatabaseException.invalidToken()
      : this(
            code: 'invalid_token',
            message: 'The supplied auth token was invalid');

  /// Thrown when the transaction had too many retries
  FirebaseDatabaseException.maxRetries()
      : this(
            code: 'max-retries',
            message: 'The transaction had too many retries');

  /// Thrown when the transaction was overridden by a subsequent set
  FirebaseDatabaseException.overriddenBySet()
      : this(
            code: 'overriddenbyset',
            message: 'The transaction was overridden by a subsequent set');

  /// Thrown when the service is unavailable
  FirebaseDatabaseException.unavailable()
      : this(code: 'unavailable', message: 'The service is unavailable');

  /// Thrown when an exception occurred in user code
  FirebaseDatabaseException.userCodeException()
      : this(
            code: 'user_code_exception',
            message: 'An exception occurred in user code');

  /// Thrown when the operation could not be performed due to a network error
  FirebaseDatabaseException.networkError()
      : this(
            code: 'network_error',
            message:
                'The operation could not be performed due to a network error');

  /// Thrown when the write was canceled locally
  FirebaseDatabaseException.writeCanceled()
      : this(
            code: 'write_canceled',
            message: 'The write was canceled by the user');

  /// Thrown when an unknown error occurred.
  ///
  /// Please refer to the error message and error details for more information.
  FirebaseDatabaseException.unknownError()
      : this(code: 'unknown_error', message: 'An unknown error occurred');

  /// Thrown when the operation could not complete because the app was deleted
  FirebaseDatabaseException.appDeleted()
      : this(code: 'app-deleted', message: 'The Firebase app was deleted.');

  FirebaseDatabaseException replace({String? message}) =>
      FirebaseDatabaseException(code: code, message: message ?? this.message);
}
