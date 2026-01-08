import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'model_manager.dart';
import 'api_client.dart';

class AnnotateImageScreen extends StatefulWidget {
  final XFile imageFile;

  const AnnotateImageScreen({super.key, required this.imageFile});

  @override
  AnnotateImageScreenState createState() => AnnotateImageScreenState();
}

class AnnotateImageScreenState extends State<AnnotateImageScreen> {
  late Future<ui.Image> _imageFuture;
  List<List<Offset>> _shapes = [];
  List<Offset> _currentShape = [];
  int? _selectedShapeIndex;
  final List<List<Offset>> _undoHistory = [];
  final List<List<Offset>> _redoHistory = [];
  bool _isDrawing = false;
  final ModelManager _modelManager = ModelManager();
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadImage();
    _modelManager.loadModel();
  }

  Future<void> _loadImage() async {
    _imageFuture = _loadImageFromFile();
  }

  Future<ui.Image> _loadImageFromFile() async {
    final bytes = kIsWeb 
        ? await widget.imageFile.readAsBytes()
        : await File(widget.imageFile.path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _startShape(Offset point) {
    setState(() {
      _isDrawing = true;
      _currentShape = [point];
      _selectedShapeIndex = null;
    });
  }

  void _updateShape(Offset point) {
    if (_isDrawing) {
      setState(() {
        _currentShape.add(point);
      });
    }
  }

  void _endShape() {
    if (_currentShape.length > 2) {
      setState(() {
        _undoHistory.add(List.from(_currentShape));
        _shapes.add(List.from(_currentShape));
        _currentShape = [];
        _isDrawing = false;
        _redoHistory.clear();
      });
    } else {
      setState(() {
        _currentShape = [];
        _isDrawing = false;
      });
    }
  }

  void _selectShape(int index) {
    setState(() {
      _selectedShapeIndex = _selectedShapeIndex == index ? null : index;
    });
  }

  void _deleteSelectedShape() {
    if (_selectedShapeIndex != null) {
      setState(() {
        _undoHistory.add(List.from(_shapes[_selectedShapeIndex!]));
        _shapes.removeAt(_selectedShapeIndex!);
        _selectedShapeIndex = null;
      });
    }
  }

  void _undo() {
    if (_undoHistory.isNotEmpty) {
      setState(() {
        final lastShape = _undoHistory.removeLast();
        _redoHistory.add(lastShape);
        if (_shapes.isNotEmpty) {
          _shapes.removeLast();
        }
        _selectedShapeIndex = null;
      });
    }
  }

  void _redo() {
    if (_redoHistory.isNotEmpty) {
      setState(() {
        final shape = _redoHistory.removeLast();
        _undoHistory.add(shape);
        _shapes.add(shape);
        _selectedShapeIndex = null;
      });
    }
  }

  void _clearAll() {
    setState(() {
      _undoHistory.addAll(_shapes);
      _shapes = [];
      _currentShape = [];
      _selectedShapeIndex = null;
      _redoHistory.clear();
    });
  }

  Future<void> _processAnnotation() async {
    if (_shapes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw a shape around an object first')),
      );
      return;
    }

    try {
      final imageData = kIsWeb 
          ? await widget.imageFile.readAsBytes()
          : await File(widget.imageFile.path).readAsBytes();
      
      // Convert shape to bounding box for inference
      final selectedShape = _selectedShapeIndex != null 
          ? _shapes[_selectedShapeIndex!] 
          : _shapes.last;
      
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = -double.infinity;
      double maxY = -double.infinity;
      
      for (final point in selectedShape) {
        minX = point.dx < minX ? point.dx : minX;
        minY = point.dy < minY ? point.dy : minY;
        maxX = point.dx > maxX ? point.dx : maxX;
        maxY = point.dy > maxY ? point.dy : maxY;
      }
      
      final boundingBox = Rect.fromLTRB(minX, minY, maxX, maxY);
      final results = await _modelManager.runInference(imageData, boundingBox);
      
      if (results.isNotEmpty) {
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Object Identified'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var result in results.take(3))
                  ListTile(
                    title: Text(result['label']),
                    trailing: Text('${(result['confidence'] * 100).toStringAsFixed(1)}%'),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _saveToBackend(results[0]['label'], boundingBox);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveToBackend(String label, Rect boundingBox) async {
    try {
      if (!kIsWeb) {
        final uploadResult = await _apiClient.uploadImage(File(widget.imageFile.path));
        if (uploadResult['status'] == 'success') {
          final annotationResult = await _apiClient.saveAnnotation(
            imagePath: widget.imageFile.path,
            boundingBoxes: [
              {
                'x': boundingBox.left,
                'y': boundingBox.top,
                'width': boundingBox.width,
                'height': boundingBox.height,
              }
            ],
            labels: [label],
          );
          
          if (annotationResult['status'] == 'success') {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Saved annotation: $label')),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save annotation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annotate Image'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _shapes.isEmpty ? null : _processAnnotation,
            icon: const Icon(Icons.check),
            tooltip: 'Process Annotation',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FutureBuilder<ui.Image>(
                  future: _imageFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return GestureDetector(
                        onPanStart: (details) {
                          final box = context.findRenderObject() as RenderBox;
                          final point = box.globalToLocal(details.globalPosition);
                          _startShape(point);
                        },
                        onPanUpdate: (details) {
                          final box = context.findRenderObject() as RenderBox;
                          final point = box.globalToLocal(details.globalPosition);
                          _updateShape(point);
                        },
                        onPanEnd: (_) => _endShape(),
                        child: CustomPaint(
                          painter: AnnotationPainter(
                            image: snapshot.data!,
                            shapes: _shapes,
                            currentShape: _currentShape,
                            selectedShapeIndex: _selectedShapeIndex,
                          ),
                          child: Container(),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading image: ${snapshot.error}'),
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ],
            ),
          ),
          Material(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _undoHistory.isEmpty ? null : _undo,
                    icon: const Icon(Icons.undo),
                    tooltip: 'Undo',
                  ),
                  IconButton(
                    onPressed: _redoHistory.isEmpty ? null : _redo,
                    icon: const Icon(Icons.redo),
                    tooltip: 'Redo',
                  ),
                  IconButton(
                    onPressed: _selectedShapeIndex == null ? null : _deleteSelectedShape,
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete Selected',
                  ),
                  IconButton(
                    onPressed: _shapes.isEmpty ? null : _clearAll,
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Clear All',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnnotationPainter extends CustomPainter {
  final ui.Image image;
  final List<List<Offset>> shapes;
  final List<Offset> currentShape;
  final int? selectedShapeIndex;

  AnnotationPainter({
    required this.image,
    required this.shapes,
    required this.currentShape,
    required this.selectedShapeIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Calculate scale to fit image
    final scale = size.width / image.width;
    final scaledHeight = image.height * scale;
    final dy = (size.height - scaledHeight) / 2;

    // Draw image
    canvas.save();
    canvas.translate(0, dy);
    canvas.scale(scale);
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.restore();

    // Transform canvas for annotations
    canvas.save();
    canvas.translate(0, dy);
    canvas.scale(scale);

    // Draw completed shapes
    for (var i = 0; i < shapes.length; i++) {
      final shape = shapes[i];
      if (shape.length < 2) continue;

      paint.color = i == selectedShapeIndex 
          ? Colors.blue.withOpacity(0.8)
          : Colors.red.withOpacity(0.8);

      final path = Path()..moveTo(shape[0].dx, shape[0].dy);
      for (var j = 1; j < shape.length; j++) {
        path.lineTo(shape[j].dx, shape[j].dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // Draw current shape
    if (currentShape.length >= 2) {
      paint.color = Colors.red.withOpacity(0.8);
      final path = Path()..moveTo(currentShape[0].dx, currentShape[0].dy);
      for (var i = 1; i < currentShape.length; i++) {
        path.lineTo(currentShape[i].dx, currentShape[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) => true;
}