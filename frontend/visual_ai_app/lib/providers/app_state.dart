import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path_util;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../model_manager.dart';
import '../api_client.dart';
import '../services/api_service.dart';
import '../services/cache_manager.dart';

class AppState extends ChangeNotifier {
  final ModelManager _modelManager = ModelManager();
  final ApiClient _apiClient;
  final ApiService _apiService;
  final CacheManager _cacheManager;
  final ImagePicker _imagePicker = ImagePicker();
  Database? _database;
  
  // Image processing state
  File? _selectedImage;
  List<List<Offset>> _annotations = [];
  bool _isProcessing = false;
  String? _error;
  List<Map<String, dynamic>>? _predictions;
  bool _modelLoaded = false;
  bool _isOffline = false;
  List<Map<String, dynamic>> _allPredictions = [];

  // Getters
  File? get selectedImage => _selectedImage;
  List<List<Offset>> get annotations => _annotations;
  bool get isLoading => _isProcessing;
  String? get error => _error;
  List<Map<String, dynamic>>? get predictions => _predictions;
  bool get modelLoaded => _modelLoaded;
  bool get hasImage => _selectedImage != null;
  bool get hasAnnotations => _annotations.isNotEmpty;
  bool get isOffline => _isOffline;

  AppState({
    ApiService? apiService,
    CacheManager? cacheManager,
    String baseUrl = 'http://localhost:8000/api',
  })  : _apiService = apiService ?? ApiService(),
        _cacheManager = cacheManager ?? CacheManager(),
        _apiClient = ApiClient(baseUrl: baseUrl) {
    _initializeDatabase();
    _loadCachedPredictions();
    _loadAllPredictions();
    // Clean cache periodically
    Future.delayed(const Duration(minutes: 5), () => _cacheManager.cleanCache());
  }

  Future<void> initializeModel(BuildContext context) async {
    try {
      await _modelManager.initialize(context);
      _modelLoaded = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load model: $e';
      _modelLoaded = false;
      notifyListeners();
    }
  }

  Future<void> _initializeDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = path_util.join(documentsDirectory.path, 'visual_ai.db');
      
      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE annotations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              image_path TEXT NOT NULL,
              points TEXT NOT NULL,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
          ''');
        },
      );
    } catch (e) {
      _error = 'Failed to initialize database: $e';
      notifyListeners();
    }
  }

  Future<void> selectImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await setSelectedImage(File(image.path));
      }
    } catch (e) {
      _error = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  Future<void> captureImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await setSelectedImage(File(image.path));
      }
    } catch (e) {
      _error = 'Failed to capture image: $e';
      notifyListeners();
    }
  }

  Future<void> setSelectedImage(File image) async {
    try {
      // Cache the image
      final cachedImage = await _cacheManager.cacheImage(image);
      _selectedImage = cachedImage;
      _annotations = [];
      _predictions = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to cache image: $e';
      notifyListeners();
    }
  }

  void addAnnotation(List<Offset> points) {
    _annotations.add(points);
    notifyListeners();
  }

  void removeLastAnnotation() {
    if (_annotations.isNotEmpty) {
      _annotations.removeLast();
      notifyListeners();
    }
  }

  void clearAnnotations() {
    _annotations = [];
    notifyListeners();
  }

  void setOfflineStatus(bool status) {
    _isOffline = status;
    if (!status) {
      // Try to sync when coming back online
      syncOfflinePredictions();
    }
    notifyListeners();
  }

  Future<void> processAnnotation(List<Offset> annotation) async {
    if (_selectedImage == null) {
      _error = 'No image selected';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiClient.processImage(
        imageFile: _selectedImage!,
        annotationPoints: annotation,
      );

      _predictions = [result];
      _error = null;
    } catch (e) {
      _error = 'Failed to process image: $e';
      _predictions = null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> syncData() async {
    try {
      await _apiClient.syncUnsynced();
    } catch (e) {
      _error = 'Failed to sync data: $e';
      notifyListeners();
    }
  }

  Future<void> syncOfflinePredictions() async {
    if (_database == null || _isOffline) return;

    try {
      final unsynced = await _database!.query(
        'predictions',
        where: 'is_synced = ? AND retry_count < ?',
        whereArgs: [0, 3],  // Limit retries to 3 attempts
      );

      for (final prediction in unsynced) {
        try {
          final predictions = await _apiService.createPrediction(
            imagePath: prediction['image_path'] as String,
            bbox: {
              'left': prediction['bbox_left'] as double,
              'top': prediction['bbox_top'] as double,
              'right': prediction['bbox_right'] as double,
              'bottom': prediction['bbox_bottom'] as double,
            },
          );

          if (predictions.isNotEmpty) {
            // Cache the successful predictions
            await _cacheManager.cachePredictions(predictions);

            await _database!.update(
              'predictions',
              {
                'label': predictions[0]['label'],
                'confidence': predictions[0]['confidence'],
                'is_synced': 1,
                'retry_count': 0,
              },
              where: 'id = ?',
              whereArgs: [prediction['id']],
            );
          }
        } catch (e) {
          // Mark as failed
          await _database!.update(
            'predictions',
            {
              'is_synced': -1,  // Use -1 to indicate failure
              'label': 'Failed: $e',
            },
            where: 'id = ?',
            whereArgs: [prediction['id']],
          );
        }
      }

      await _loadAllPredictions();
    } catch (e) {
      _error = 'Failed to sync predictions: $e';
      notifyListeners();
    }
  }

  Future<void> deletePrediction(int id) async {
    if (_database == null) return;

    try {
      await _database!.delete(
        'predictions',
        where: 'id = ?',
        whereArgs: [id],
      );

      await _loadAllPredictions();
    } catch (e) {
      _error = 'Failed to delete prediction: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _modelManager.dispose();
    _apiClient.dispose();
    _database?.close();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadCachedPredictions() async {
    if (_predictions == null || _predictions!.isEmpty) {
      _predictions = await _cacheManager.getCachedPredictions();
      notifyListeners();
    }
  }

  Future<void> _loadAllPredictions() async {
    if (_database == null) return;

    try {
      final predictions = await _database!.query(
        'predictions',
        orderBy: 'timestamp DESC',
      );

      _allPredictions = predictions;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load predictions: $e';
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    _isProcessing = loading;
    notifyListeners();
  }

  void setCurrentImage(String? imagePath) {
    _selectedImage = imagePath != null ? File(imagePath) : null;
    notifyListeners();
  }

  void setAnnotations(List<List<Offset>> annotations) {
    _annotations = annotations;
    notifyListeners();
  }

  Future<void> saveAnnotation(Map<String, dynamic> annotation) async {
    if (_database == null) await _initializeDatabase();
    
    await _database!.insert(
      'annotations',
      {
        'image_path': _selectedImage?.path,
        'annotation_data': annotation.toString(),
      },
    );
    
    final annotations = await _database!.query('annotations');
    _annotations = annotations.map((a) => _parseAnnotation(a)).toList();
    notifyListeners();
  }

  List<Offset> _parseAnnotation(Map<String, dynamic> data) {
    try {
      final List<dynamic> points = data['annotation_data'] as List<dynamic>;
      return points.map((p) => Offset(p['x'] as double, p['y'] as double)).toList();
    } catch (e) {
      print('Error parsing annotation: $e');
      return [];
    }
  }
} 