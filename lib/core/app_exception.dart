class AppException implements Exception {
  const AppException(this.message, [this.stackTrace]);
  final String message;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException: $message';
}
