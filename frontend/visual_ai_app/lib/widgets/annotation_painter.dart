import 'package:flutter/material.dart';

class AnnotationPainter extends CustomPainter {
  final List<List<Offset>> annotations;
  final List<Offset> currentPath;
  final Size? imageSize;
  
  static const double strokeWidth = 2.0;
  static const Color strokeColor = Colors.blue;
  static const Color fillColor = Color(0x402196F3); // Semi-transparent blue

  AnnotationPainter({
    required this.annotations,
    required this.currentPath,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == null) return;

    // Calculate scale factors to map image coordinates to screen coordinates
    final scaleX = size.width / imageSize!.width;
    final scaleY = size.height / imageSize!.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Calculate offset to center the image
    final offsetX = (size.width - imageSize!.width * scale) / 2;
    final offsetY = (size.height - imageSize!.height * scale) / 2;

    // Setup paint styles
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw completed annotations
    for (final path in annotations) {
      if (path.length < 2) continue;

      final scaledPath = Path();
      
      // Move to first point
      final firstPoint = Offset(
        path[0].dx * scale + offsetX,
        path[0].dy * scale + offsetY,
      );
      scaledPath.moveTo(firstPoint.dx, firstPoint.dy);

      // Add lines to subsequent points
      for (int i = 1; i < path.length; i++) {
        final point = Offset(
          path[i].dx * scale + offsetX,
          path[i].dy * scale + offsetY,
        );
        scaledPath.lineTo(point.dx, point.dy);
      }

      // Close the path
      scaledPath.close();

      // Draw fill first, then stroke
      canvas.drawPath(scaledPath, fillPaint);
      canvas.drawPath(scaledPath, strokePaint);
    }

    // Draw current path
    if (currentPath.length >= 2) {
      final currentScaledPath = Path();
      
      // Move to first point
      final firstPoint = Offset(
        currentPath[0].dx * scale + offsetX,
        currentPath[0].dy * scale + offsetY,
      );
      currentScaledPath.moveTo(firstPoint.dx, firstPoint.dy);

      // Add lines to subsequent points
      for (int i = 1; i < currentPath.length; i++) {
        final point = Offset(
          currentPath[i].dx * scale + offsetX,
          currentPath[i].dy * scale + offsetY,
        );
        currentScaledPath.lineTo(point.dx, point.dy);
      }

      // Draw the current path with dashed effect
      final dashedStrokePaint = Paint()
        ..color = strokeColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawPath(currentScaledPath, dashedStrokePaint);
    }
  }

  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) {
    return oldDelegate.annotations != annotations ||
           oldDelegate.currentPath != currentPath ||
           oldDelegate.imageSize != imageSize;
  }
} 