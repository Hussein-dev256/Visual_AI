import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ModelManager {
  Interpreter? _interpreter;
  List<String>? _labels;
  static const platform = MethodChannel('com.example.visual_ai_app/image_processor');

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/mobilenetv3_small.tflite');
      final labelData = await DefaultAssetBundle.of(WidgetsBinding.instance.rootElement!.context)
          .loadString('assets/labels.txt');
      _labels = labelData.split('\n')..removeWhere((label) => label.isEmpty);
    } catch (e) {
      debugPrint('Error loading model: $e');
    }
  }

  Future<List<Map<String, dynamic>>> runInference(Uint8List imageData, Rect? annotation) async {
    if (_interpreter == null) {
      throw Exception('Model not loaded');
    }
    try {
      // Preprocess with C++ (placeholder)
      final processedData = await platform.invokeMethod('preprocessImage', {
        'image': imageData,
        'width': 224,
        'height': 224,
      }) as Uint8List;

      // Prepare input tensor
      var input = processedData.buffer.asFloat32List().reshape([1, 224, 224, 3]);
      var output = List.filled(1 * 1000, 0.0).reshape([1, 1000]);

      // Run inference
      _interpreter!.run(input, output);

      // Map scores to labels
      List<Map<String, dynamic>> results = [];
      for (int i = 0; i < output[0].length && i < _labels!.length; i++) {
        results.add({'label': _labels![i], 'confidence': output[0][i]});
      }
      results.sort((a, b) => b['confidence'].compareTo(a['confidence']));
      return results.take(3).toList();
    } catch (e) {
      debugPrint('Inference error: $e');
      return [];
    }
  }
}