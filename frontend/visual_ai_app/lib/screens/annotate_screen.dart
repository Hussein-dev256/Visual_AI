import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/annotation_canvas.dart';
import '../widgets/network_status_indicator.dart';

class AnnotateScreen extends StatefulWidget {
  const AnnotateScreen({super.key});

  @override
  State<AnnotateScreen> createState() => _AnnotateScreenState();
}

class _AnnotateScreenState extends State<AnnotateScreen> {
  ui.Image? _image;
  List<Offset>? _currentPath;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final appState = context.read<AppState>();
      if (appState.selectedImage == null) {
        throw Exception('No image selected');
      }

      final bytes = await appState.selectedImage!.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      
      setState(() {
        _image = frame.image;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handlePointerDown(Offset position) {
    setState(() {
      _currentPath = [position];
    });
  }

  void _handlePointerMove(Offset position) {
    if (_currentPath == null) return;
    
    setState(() {
      _currentPath = [..._currentPath!, position];
    });
  }

  void _handlePointerUp(Offset position) {
    if (_currentPath == null) return;

    final appState = context.read<AppState>();
    appState.addAnnotation(_currentPath!);
    
    setState(() {
      _currentPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annotate Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: context.watch<AppState>().annotations.isEmpty
                ? null
                : () => context.read<AppState>().removeLastAnnotation(),
            tooltip: 'Undo last annotation',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: context.watch<AppState>().annotations.isEmpty
                ? null
                : () => context.read<AppState>().clearAnnotations(),
            tooltip: 'Clear all annotations',
          ),
        ],
      ),
      body: Column(
        children: [
          const NetworkStatusIndicator(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: context.watch<AppState>().annotations.isEmpty
                  ? null
                  : () => _processAnnotations(),
              icon: const Icon(Icons.check),
              label: const Text('Process'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadImage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading || _image == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return AnnotationCanvas(
          paths: appState.annotations,
          currentPath: _currentPath,
          image: _image,
          imageSize: Size(_image!.width.toDouble(), _image!.height.toDouble()),
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
        );
      },
    );
  }

  Future<void> _processAnnotations() async {
    final appState = context.read<AppState>();
    if (appState.annotations.isEmpty) return;

    try {
      // Process the last annotation
      await appState.processAnnotation(appState.annotations.last);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }
} 