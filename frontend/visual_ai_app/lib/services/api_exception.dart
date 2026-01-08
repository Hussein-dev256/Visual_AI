class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final bool isRetryable;

  ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.originalError,
    this.stackTrace,
    this.isRetryable = false,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (statusCode != null) {
      buffer.write(' (Status Code: $statusCode)');
    }
    if (errorCode != null) {
      buffer.write(' [Error Code: $errorCode]');
    }
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }

  factory ApiException.fromStatusCode(int statusCode, String message) {
    final isRetryable = statusCode >= 500 || statusCode == 429;
    return ApiException(
      message: message,
      statusCode: statusCode,
      isRetryable: isRetryable,
    );
  }

  factory ApiException.network(dynamic error, [StackTrace? stackTrace]) {
    return ApiException(
      message: 'Network error occurred',
      originalError: error,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }

  factory ApiException.timeout([String? message]) {
    return ApiException(
      message: message ?? 'Request timed out',
      errorCode: 'TIMEOUT',
      isRetryable: true,
    );
  }

  factory ApiException.server([String? message]) {
    return ApiException(
      message: message ?? 'Server error occurred',
      errorCode: 'SERVER_ERROR',
      isRetryable: true,
    );
  }

  factory ApiException.invalidResponse([String? message]) {
    return ApiException(
      message: message ?? 'Invalid response received',
      errorCode: 'INVALID_RESPONSE',
      isRetryable: false,
    );
  }
} 