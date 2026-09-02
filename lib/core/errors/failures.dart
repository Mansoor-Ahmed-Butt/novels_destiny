sealed class AppFailure implements Exception {
  final String message;
  final dynamic cause;

  const AppFailure(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Unable to connect to the network. Please check your connection.', super.cause]);
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'You must be signed in to perform this action.', super.cause]);
}

class PermissionFailure extends AppFailure {
  const PermissionFailure([super.message = 'You do not have permission to access this resource.', super.cause]);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure([super.message = 'Please check the entered information and try again.', super.cause]);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'The requested story or episode was not found.', super.cause]);
}

class StorageFailure extends AppFailure {
  const StorageFailure([super.message = 'Failed to upload or retrieve file asset.', super.cause]);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'An unexpected error occurred. Please try again.', super.cause]);
}
