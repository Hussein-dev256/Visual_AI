import 'dart:math';

class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffFactor;
  final Set<int> retryStatusCodes;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    this.backoffFactor = 1.5,
    this.retryStatusCodes = const {
      408, // Request Timeout
      429, // Too Many Requests
      500, // Internal Server Error
      502, // Bad Gateway
      503, // Service Unavailable
      504, // Gateway Timeout
    },
  });

  Duration getDelayForAttempt(int attempt) {
    if (attempt <= 0) return Duration.zero;
    
    final exponentialDelay = initialDelay.inMilliseconds * pow(backoffFactor, attempt - 1);
    final jitter = Random().nextInt(200) - 100; // Add random jitter between -100ms and +100ms
    
    return Duration(
      milliseconds: min(
        maxDelay.inMilliseconds,
        exponentialDelay.toInt() + jitter,
      ),
    );
  }

  bool shouldRetry(int statusCode, int attempt) {
    return attempt < maxAttempts && retryStatusCodes.contains(statusCode);
  }
} 