import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'model_manager.dart';
import 'api_client.dart';

class AnnotateImageScreen extends StatelessWidget {
  const AnnotateImageScreen({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AnnotationEditor(imageFile: pickedFile),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Image'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Select an Image to Annotate',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Choose an image from your camera or gallery to begin annotation.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: kIsWeb ? null : () => _pickImage(context, ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(context, ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnnotationEditor extends StatefulWidget {
  final XFile imageFile;

  const AnnotationEditor({super.key, required this.imageFile});

  @override
  AnnotationEditorState createState() => AnnotationEditorState();
}

class AnnotationEditorState extends State<AnnotationEditor> {
  Uint8List? _imageBytes;
  List<Rect> _annotations = [];
  Offset? _startPoint;
  String _label = '';
  final ModelManager _modelManager = ModelManager();
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadImage();
    _modelManager.loadModel();
  }

  Future<void> _loadImage() async {
    if (kIsWeb) {
      final bytes = await widget.imageFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  void _startAnnotation(Offset point) {
    setState(() {
      _startPoint = point;
    });
  }

  void _updateAnnotation(Offset point) {
    // Optional: Real-time feedback for drawing
    if (_startPoint != null) {
      setState(() {
        // Temporary rectangle for preview
      });
    }
  }

  void _endAnnotation(Offset point) {
    if (_startPoint != null) {
      setState(() {
        _annotations.add(Rect.fromPoints(_startPoint!, point));
        _startPoint = null;
      });
    }
  }

  Future<void> _saveAnnotation() async {
    if (_annotations.isEmpty || _label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw a box and enter a label')),
      );
      return;
    }

    try {
      // Run inference
      final imageData = kIsWeb ? _imageBytes! : await File(widget.imageFile.path).readAsBytes();
      final results = await _modelManager.runInference(imageData, _annotations.first);
      final topLabel = results.isNotEmpty ? results[0]['label'] : _label;

      // Upload image and save annotation
      if (!kIsWeb) {
        final uploadResult = await _apiClient.uploadImage(File(widget.imageFile.path));
        if (uploadResult['status'] == 'success') {
          final annotationResult = await _apiClient.saveAnnotation(
            imagePath: widget.imageFile.path,
            boundingBoxes: [
              {
                'x': _annotations.first.left,
                'y': _annotations.first.top,
                'width': _annotations.first.width,
                'height': _annotations.first.height,
              }
            ],
            labels: [_label],
          );
          if (annotationResult['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Annotation saved: $topLabel')),
            );
          } else {
            throw Exception('Failed to save annotation');
          }
        } else {
          throw Exception('Failed to upload image');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Annotation processed locally: $topLabel')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annotate Item'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAnnotation,
            tooltip: 'Save Annotation',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Draw a box around the item of interest and enter a label',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: _imageBytes == null && kIsWeb
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
                    onPanStart: (details) => _startAnnotation(details.localPosition),
                    onPanUpdate: (details) => _updateAnnotation(details.localPosition),
                    onPanEnd: (details) => _endAnnotation(details.localPosition),
                    child: CustomPaint(
                      painter: AnnotationPainter(_annotations, _startPoint),
                      child: kIsWeb
                          ? Image.memory(_imageBytes!, fit: BoxFit.contain)
                          : Image.file(File(widget.imageFile.path), fit: BoxFit.contain),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Item Label',
                border: const OutlineInputBorder(),
                hintText: 'e.g., Car, Tree',
                errorText: _label.isEmpty && _annotations.isNotEmpty ? 'Label is required' : null,
              ),
              onChanged: (value) {
                setState(() {
                  _label = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AnnotationPainter extends CustomPainter {
  final List<Rect> annotations;
  final Offset? startPoint;

  AnnotationPainter(this.annotations, this.startPoint);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var rect in annotations) {
      canvas.drawRect(rect, paint);
    }

    // Draw temporary rectangle during drag
    if (startPoint != null) {
      // Placeholder for real-time preview
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}