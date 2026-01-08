import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';

class CacheManager {
  static const String IMAGE_CACHE_DIR = 'image_cache';
  static const String PREDICTION_CACHE_FILE = 'predictions_cache.json';
  static const int MAX_CACHE_AGE = 7; // days
  static const int MAX_CACHE_SIZE = 100 * 1024 * 1024; // 100MB

  Future<String> getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, IMAGE_CACHE_DIR));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir.path;
  }

  Future<File> cacheImage(File imageFile) async {
    final cacheDir = await getCacheDirectory();
    final String fileName = _generateFileName(imageFile.path);
    final String cachePath = path.join(cacheDir, fileName);
    
    // Copy the file to cache
    return await imageFile.copy(cachePath);
  }

  Future<File?> getCachedImage(String originalPath) async {
    final cacheDir = await getCacheDirectory();
    final String fileName = _generateFileName(originalPath);
    final String cachePath = path.join(cacheDir, fileName);
    
    final file = File(cachePath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  Future<void> cachePredictions(List<Map<String, dynamic>> predictions) async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File(path.join(appDir.path, PREDICTION_CACHE_FILE));
    
    List<Map<String, dynamic>> existingPredictions = [];
    if (await file.exists()) {
      final content = await file.readAsString();
      existingPredictions = List<Map<String, dynamic>>.from(
        json.decode(content)
      );
    }
    
    // Add new predictions at the beginning
    existingPredictions.insertAll(0, predictions);
    
    // Save back to file
    await file.writeAsString(json.encode(existingPredictions));
  }

  Future<List<Map<String, dynamic>>> getCachedPredictions() async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File(path.join(appDir.path, PREDICTION_CACHE_FILE));
    
    if (await file.exists()) {
      final content = await file.readAsString();
      return List<Map<String, dynamic>>.from(json.decode(content));
    }
    return [];
  }

  String _generateFileName(String originalPath) {
    final bytes = utf8.encode(originalPath);
    final hash = md5.convert(bytes);
    return '${hash.toString()}.${path.extension(originalPath)}';
  }

  Future<void> cleanCache() async {
    final cacheDir = await getCacheDirectory();
    final directory = Directory(cacheDir);
    
    if (!await directory.exists()) return;

    int totalSize = 0;
    final List<FileSystemEntity> files = await directory.list().toList();
    
    // Sort files by last modified time
    files.sort((a, b) {
      return File(b.path).lastModifiedSync()
          .compareTo(File(a.path).lastModifiedSync());
    });

    final now = DateTime.now();
    
    for (var file in files) {
      if (file is File) {
        final stat = await file.stat();
        final age = now.difference(stat.modified).inDays;
        
        // Remove old files
        if (age > MAX_CACHE_AGE) {
          await file.delete();
          continue;
        }
        
        totalSize += stat.size;
        
        // Remove excess files if total size exceeds MAX_CACHE_SIZE
        if (totalSize > MAX_CACHE_SIZE) {
          await file.delete();
        }
      }
    }
  }
} 