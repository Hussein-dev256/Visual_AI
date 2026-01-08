import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ModelManager {
  static const String MODEL_FILENAME = "mobilenet_v3_small.tflite";
  Interpreter? _interpreter;
  bool _isInitialized = false;
  List<String>? _labels;

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    try {
      // Copy model file from assets to local storage
      final appDir = await getApplicationDocumentsDirectory();
      final modelFile = File('${appDir.path}/$MODEL_FILENAME');

      if (!await modelFile.exists()) {
        final modelData = await rootBundle.load('assets/models/$MODEL_FILENAME');
        await modelFile.writeAsBytes(modelData.buffer.asUint8List());
      }

      // Load labels using the provided context
      final labelData = await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
      _labels = labelData.split('\n')..removeWhere((label) => label.isEmpty);

      // Initialize TFLite interpreter
      _interpreter = await Interpreter.fromFile(modelFile.path);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing model: $e');
      _isInitialized = false;
    }
  }

  Future<List<Map<String, dynamic>>> runInference(Uint8List imageData, Rect? annotation) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('Model not loaded');
    }
    
    try {
      // Decode and preprocess image
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      // Resize image to 224x224
      final resizedImage = img.copyResize(image, width: 224, height: 224);

      // Convert to float32 array and normalize to [-1, 1]
      final inputArray = Float32List(1 * 224 * 224 * 3);
      var index = 0;
      for (var y = 0; y < 224; y++) {
        for (var x = 0; x < 224; x++) {
          final pixel = resizedImage.getPixel(x, y);
          inputArray[index++] = (img.getRed(pixel) - 127.5) / 127.5;
          inputArray[index++] = (img.getGreen(pixel) - 127.5) / 127.5;
          inputArray[index++] = (img.getBlue(pixel) - 127.5) / 127.5;
        }
      }

      // Reshape input to match model's expected shape [1, 224, 224, 3]
      final input = inputArray.reshape([1, 224, 224, 3]);

      // Create output tensor
      final output = List<double>.filled(1000, 0).reshape([1, 1000]);

      // Run inference
      _interpreter!.run(input, output);

      // Get results
      final results = List<Map<String, dynamic>>.empty(growable: true);
      for (var i = 0; i < output[0].length && i < _labels!.length; i++) {
        results.add({
          'label': _labels![i],
          'confidence': output[0][i],
        });
      }

      // Sort by confidence
      results.sort((a, b) => b['confidence'].compareTo(a['confidence']));
      return results.take(3).toList();
    } catch (e) {
      debugPrint('Inference error: $e');
      return [];
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}