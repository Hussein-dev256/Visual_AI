import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final bool enableOfflineMode;
  final int maxCacheSize;
  final Duration syncInterval;
  final bool enableDebugLogging;

  static late AppConfig _instance;

  factory AppConfig({
    Environment environment = Environment.development,
    String? apiBaseUrl,
    bool? enableOfflineMode,
    int? maxCacheSize,
    Duration? syncInterval,
    bool? enableDebugLogging,
  }) {
    _instance = AppConfig._internal(
      environment: environment,
      apiBaseUrl: apiBaseUrl ??
          _getDefaultApiUrl(environment),
      enableOfflineMode: enableOfflineMode ?? true,
      maxCacheSize: maxCacheSize ?? (50 * 1024 * 1024), // 50MB default
      syncInterval: syncInterval ?? const Duration(minutes: 15),
      enableDebugLogging: enableDebugLogging ?? !kReleaseMode,
    );
    return _instance;
  }

  AppConfig._internal({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableOfflineMode,
    required this.maxCacheSize,
    required this.syncInterval,
    required this.enableDebugLogging,
  });

  static AppConfig get instance {
    return _instance;
  }

  static String _getDefaultApiUrl(Environment env) {
    switch (env) {
      case Environment.development:
        return 'http://localhost:8000/api';
      case Environment.staging:
        return 'https://staging-api.visualai.com/api';
      case Environment.production:
        return 'https://api.visualai.com/api';
    }
  }

  bool get isDevelopment => environment == Environment.development;
  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;

  // Add any additional environment-specific configurations here
  Map<String, dynamic> toJson() => {
        'environment': environment.toString(),
        'apiBaseUrl': apiBaseUrl,
        'enableOfflineMode': enableOfflineMode,
        'maxCacheSize': maxCacheSize,
        'syncInterval': syncInterval.inMilliseconds,
        'enableDebugLogging': enableDebugLogging,
      };
} 