import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:8000/api';

  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        return {'status': 'success', 'message': 'Image uploaded'};
      } else {
        return {'status': 'error', 'message': 'Upload failed'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> saveAnnotation({
    required String imagePath,
    required List<Map<String, double>> boundingBoxes,
    required List<String> labels,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/annotate'),
        headers: {'Content-Type': 'application/json'},
        body: {
          'image_path': imagePath,
          'bounding_boxes': boundingBoxes,
          'labels': labels,
        },
      );
      if (response.statusCode == 200) {
        return {'status': 'success', 'message': 'Annotation saved'};
      } else {
        return {'status': 'error', 'message': 'Annotation failed'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}