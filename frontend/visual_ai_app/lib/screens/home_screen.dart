import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize model when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().initializeModel(context);
    });
  }

  Future<void> _handleImageSelection(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text('Choose from Gallery'),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    // Let AppState handle image selection
                    await appState.selectImageFromGallery();
                  },
                ),
                const Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: const ListTile(
                    leading: Icon(Icons.photo_camera),
                    title: Text('Take a Picture'),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    // Let AppState handle image capture
                    await appState.captureImage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              final appState = Provider.of<AppState>(context, listen: false);
              appState.syncData();
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appState.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${appState.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _handleImageSelection(context),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (appState.selectedImage != null) ...[
                  Expanded(
                    child: Image.file(
                      appState.selectedImage!,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/annotate');
                    },
                    child: const Text('Start Annotation'),
                  ),
                ] else
                  const Text('No image selected'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _handleImageSelection(context),
                  child: const Text('Select Image'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleImageSelection(context),
        tooltip: 'Select Image',
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }
} 