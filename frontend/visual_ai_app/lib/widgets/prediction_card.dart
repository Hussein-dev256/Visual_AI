import 'dart:io';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class PredictionCard extends StatelessWidget {
  final Map<String, dynamic> prediction;
  final VoidCallback? onTap;
  final bool showImage;
  final bool isExpanded;

  const PredictionCard({
    super.key,
    required this.prediction,
    this.onTap,
    this.showImage = true,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = DateTime.parse(prediction['timestamp'] as String);
    final confidence = (prediction['confidence'] as double) * 100;
    final label = prediction['label'] as String;
    final imagePath = prediction['image_path'] as String;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showImage && imagePath.isNotEmpty) ...[
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildImage(imagePath),
              ),
              const Divider(height: 1),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getConfidenceColor(confidence),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${confidence.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Bounding Box',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildBoundingBoxValue(
                          context,
                          'Left',
                          prediction['bbox_left'] as double,
                        ),
                        _buildBoundingBoxValue(
                          context,
                          'Top',
                          prediction['bbox_top'] as double,
                        ),
                        _buildBoundingBoxValue(
                          context,
                          'Right',
                          prediction['bbox_right'] as double,
                        ),
                        _buildBoundingBoxValue(
                          context,
                          'Bottom',
                          prediction['bbox_bottom'] as double,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    timeago.format(timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 48),
        ),
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 48),
        ),
      );
    }
  }

  Widget _buildBoundingBoxValue(BuildContext context, String label, double value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 90) return Colors.green;
    if (confidence >= 70) return Colors.orange;
    return Colors.red;
  }
} 