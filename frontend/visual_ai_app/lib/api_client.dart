import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  static const String _offlineDir = 'visual_ai_offline';
  static Database? _database;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'visual_ai.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE predictions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image_path TEXT,
            label TEXT,
            confidence REAL,
            timestamp INTEGER,
            bbox_left REAL,
            bbox_top REAL,
            bbox_right REAL,
            bbox_bottom REAL,
            is_synced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<void> savePrediction({
    required String imagePath,
    required String label,
    required double confidence,
    required Rect boundingBox,
  }) async {
    final db = await database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      // First try to sync with backend
      final response = await http.post(
        Uri.parse('$baseUrl/predictions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_path': imagePath,
          'label': label,
          'confidence': confidence,
          'bbox': {
            'left': boundingBox.left,
            'top': boundingBox.top,
            'right': boundingBox.right,
            'bottom': boundingBox.bottom,
          },
          'timestamp': timestamp,
        }),
      );

      final isSynced = response.statusCode == 200;

      // Save locally regardless of sync status
      await db.insert(
        'predictions',
        {
          'image_path': imagePath,
          'label': label,
          'confidence': confidence,
          'bbox_left': boundingBox.left,
          'bbox_top': boundingBox.top,
          'bbox_right': boundingBox.right,
          'bbox_bottom': boundingBox.bottom,
          'timestamp': timestamp,
          'is_synced': isSynced ? 1 : 0,
        },
      );
    } catch (e) {
      // If backend sync fails, just save locally
      await db.insert(
        'predictions',
        {
          'image_path': imagePath,
          'label': label,
          'confidence': confidence,
          'bbox_left': boundingBox.left,
          'bbox_top': boundingBox.top,
          'bbox_right': boundingBox.right,
          'bbox_bottom': boundingBox.bottom,
          'timestamp': timestamp,
          'is_synced': 0,
        },
      );
    }
  }

  Future<List<Map<String, dynamic>>> getLocalPredictions() async {
    final db = await database;
    return await db.query('predictions', orderBy: 'timestamp DESC');
  }

  Future<void> syncUnsynced() async {
    final db = await database;
    final unsynced = await db.query(
      'predictions',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    for (final prediction in unsynced) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/predictions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'image_path': prediction['image_path'],
            'label': prediction['label'],
            'confidence': prediction['confidence'],
            'bbox': {
              'left': prediction['bbox_left'],
              'top': prediction['bbox_top'],
              'right': prediction['bbox_right'],
              'bottom': prediction['bbox_bottom'],
            },
            'timestamp': prediction['timestamp'],
          }),
        );

        if (response.statusCode == 200) {
          await db.update(
            'predictions',
            {'is_synced': 1},
            where: 'id = ?',
            whereArgs: [prediction['id']],
          );
        }
      } catch (e) {
        print('Failed to sync prediction ${prediction['id']}: $e');
      }
    }
  }

  Future<String> saveImage(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await imageFile.copy('${appDir.path}/images/$fileName');
    return savedImage.path;
  }

  Future<void> dispose() async {
    _client.close();
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    if (kIsWeb) {
      return {'status': 'success', 'message': 'Web mode - image processed locally'};
    }

    try {
      // Try to connect to server
      final serverAvailable = await _checkServerConnection();
      
      if (!serverAvailable) {
        // Save locally if server is not available
        final savedPath = await _saveImageLocally(imageFile);
        return {
          'status': 'success',
          'message': 'Image saved locally',
          'path': savedPath,
          'offline': true,
        };
      }

      // Upload to server if available
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      
      var response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);
      
      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': 'Image uploaded to server',
          'path': jsonResponse['path'],
          'offline': false,
        };
      } else {
        throw Exception('Server returned ${response.statusCode}: ${jsonResponse['message']}');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      // Fallback to local storage on error
      final savedPath = await _saveImageLocally(imageFile);
      return {
        'status': 'success',
        'message': 'Saved locally (server error: $e)',
        'path': savedPath,
        'offline': true,
      };
    }
  }

  Future<Map<String, dynamic>> saveAnnotation({
    required String imagePath,
    required List<Map<String, double>> boundingBoxes,
    required List<String> labels,
  }) async {
    if (kIsWeb) {
      return {'status': 'success', 'message': 'Web mode - annotation processed locally'};
    }

    final annotationData = {
      'image_path': imagePath,
      'bounding_boxes': boundingBoxes,
      'labels': labels,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // Try to connect to server
      final serverAvailable = await _checkServerConnection();
      
      if (!serverAvailable) {
        // Save locally if server is not available
        final savedPath = await _saveAnnotationLocally(annotationData);
        return {
          'status': 'success',
          'message': 'Annotation saved locally',
          'path': savedPath,
          'offline': true,
        };
      }

      // Send to server if available
      final response = await http.post(
        Uri.parse('$baseUrl/annotate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(annotationData),
      );

      final jsonResponse = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': 'Annotation saved to server',
          'path': jsonResponse['path'],
          'offline': false,
        };
      } else {
        throw Exception('Server returned ${response.statusCode}: ${jsonResponse['message']}');
      }
    } catch (e) {
      debugPrint('Annotation error: $e');
      // Fallback to local storage on error
      final savedPath = await _saveAnnotationLocally(annotationData);
      return {
        'status': 'success',
        'message': 'Saved locally (server error: $e)',
        'path': savedPath,
        'offline': true,
      };
    }
  }

  Future<bool> _checkServerConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String> _saveImageLocally(File imageFile) async {
    final directory = await _getOfflineDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'image_$timestamp.jpg';
    final savedFile = await imageFile.copy('${directory.path}/$fileName');
    return savedFile.path;
  }

  Future<String> _saveAnnotationLocally(Map<String, dynamic> annotationData) async {
    final directory = await _getOfflineDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'annotation_$timestamp.json';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(json.encode(annotationData));
    return file.path;
  }

  Future<Directory> _getOfflineDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${appDir.path}/$_offlineDir');
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }
    return offlineDir;
  }

  Future<List<Map<String, dynamic>>> getPendingUploads() async {
    if (kIsWeb) return [];

    try {
      final directory = await _getOfflineDirectory();
      final files = await directory.list().toList();
      
      List<Map<String, dynamic>> pendingUploads = [];
      
      for (var file in files) {
        if (file is File) {
          if (file.path.endsWith('.json')) {
            final content = await file.readAsString();
            pendingUploads.add(json.decode(content));
          }
        }
      }
      
      return pendingUploads;
    } catch (e) {
      debugPrint('Error getting pending uploads: $e');
      return [];
    }
  }

  Future<void> syncPendingUploads() async {
    if (kIsWeb) return;

    final serverAvailable = await _checkServerConnection();
    if (!serverAvailable) return;

    final pendingUploads = await getPendingUploads();
    for (var upload in pendingUploads) {
      try {
        // Upload image
        final imageFile = File(upload['image_path']);
        if (await imageFile.exists()) {
          final uploadResult = await uploadImage(imageFile);
          if (uploadResult['status'] == 'success' && !uploadResult['offline']) {
            // Upload annotation
            await saveAnnotation(
              imagePath: uploadResult['path'],
              boundingBoxes: List<Map<String, double>>.from(upload['bounding_boxes']),
              labels: List<String>.from(upload['labels']),
            );
            
            // Delete local files after successful upload
            await imageFile.delete();
            await File(upload['annotation_path']).delete();
          }
        }
      } catch (e) {
        debugPrint('Error syncing upload: $e');
      }
    }
  }

  Future<Map<String, dynamic>> processImage({
    required File imageFile,
    required List<Offset> annotationPoints,
  }) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Calculate bounding box from annotation points
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      for (final point in annotationPoints) {
        minX = point.dx < minX ? point.dx : minX;
        minY = point.dy < minY ? point.dy : minY;
        maxX = point.dx > maxX ? point.dx : maxX;
        maxY = point.dy > maxY ? point.dy : maxY;
      }

      final boundingBox = {
        'left': minX,
        'top': minY,
        'right': maxX,
        'bottom': maxY,
      };

      // Prepare request body
      final body = jsonEncode({
        'image': base64Image,
        'bounding_box': boundingBox,
        'annotation_points': annotationPoints
            .map((point) => {'x': point.dx, 'y': point.dy})
            .toList(),
      });

      // Send request
      final response = await _client.post(
        Uri.parse('$baseUrl/process_image'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to process image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error processing image: $e');
    }
  }
}