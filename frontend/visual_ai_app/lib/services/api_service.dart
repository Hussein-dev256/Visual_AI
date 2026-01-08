import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'retry_config.dart';
import 'api_exception.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;
  final RetryConfig _retryConfig;
  final Duration timeout;

  ApiService({
    String? baseUrl,
    http.Client? client,
    RetryConfig? retryConfig,
    this.timeout = const Duration(seconds: 30),
  })  : baseUrl = baseUrl ?? 'http://localhost:8000/api',
        _client = client ?? http.Client(),
        _retryConfig = retryConfig ?? const RetryConfig();

  Future<T> _retryRequest<T>({
    required Future<T> Function() request,
    String? operationName,
  }) async {
    int attempt = 0;
    ApiException? lastError;

    while (attempt < _retryConfig.maxAttempts) {
      try {
        attempt++;
        return await request();
      } catch (e, stackTrace) {
        lastError = e is ApiException
            ? e
            : ApiException(
                message: e.toString(),
                originalError: e,
                stackTrace: stackTrace,
                isRetryable: true,
              );

        if (!lastError.isRetryable || attempt >= _retryConfig.maxAttempts) {
          break;
        }

        final delay = _retryConfig.getDelayForAttempt(attempt);
        if (kDebugMode) {
          print(
            '${operationName ?? 'Request'} failed (attempt $attempt): ${e.toString()}\n'
            'Retrying in ${delay.inMilliseconds}ms...',
          );
        }
        await Future.delayed(delay);
      }
    }

    throw lastError ??
        ApiException(
          message: 'Request failed after $_retryConfig.maxAttempts attempts',
          isRetryable: false,
        );
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    try {
      final data = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      throw ApiException.fromStatusCode(
        response.statusCode,
        data['detail'] ?? 'Request failed',
      );
    } on FormatException {
      throw ApiException.invalidResponse('Invalid JSON response');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return data['path'] as String;
      } else {
        throw Exception('Failed to upload image: ${data['message']}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<List<Map<String, dynamic>>> createPrediction({
    required String imagePath,
    required Map<String, double> bbox,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_path': imagePath,
          'bbox': bbox,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final predictions = data['predictions'] as List;
        return predictions.map((p) => Map<String, dynamic>.from(p)).toList();
      } else {
        throw Exception('Failed to create prediction: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating prediction: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPredictions({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/predictions/').replace(
        queryParameters: {
          'skip': skip.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await _client
          .get(uri)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        throw Exception('Failed to get predictions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting predictions: $e');
    }
  }

  Future<bool> deleteImage(String filename) async {
    return _retryRequest(
      operationName: 'Delete Image',
      request: () async {
        try {
          final uri = Uri.parse('$baseUrl/images/$filename');
          final response = await _client
              .delete(uri)
              .timeout(timeout);

          await _handleResponse(response);
          return true;
        } on TimeoutException {
          throw ApiException.timeout();
        } on SocketException catch (e) {
          throw ApiException.network(e);
        }
      },
    );
  }

  void dispose() {
    _client.close();
  }
} 