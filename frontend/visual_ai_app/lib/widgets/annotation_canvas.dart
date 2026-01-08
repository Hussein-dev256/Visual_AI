import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AnnotationCanvas extends StatefulWidget {
  final String imagePath;
  final Function(List<Offset>) onAnnotationComplete;

  const AnnotationCanvas({
    Key? key,
    required this.imagePath,
    required this.onAnnotationComplete,
  }) : super(key: key);

  @override
  State<AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends State<AnnotationCanvas> {
  List<Offset> points = [];
  bool isDrawing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          isDrawing = true;
          points = [details.localPosition];
        });
      },
      onPanUpdate: (details) {
        if (!isDrawing) return;
        setState(() {
          points.add(details.localPosition);
        });
      },
      onPanEnd: (details) {
        setState(() {
          isDrawing = false;
          widget.onAnnotationComplete(points);
        });
      },
      child: CustomPaint(
        painter: AnnotationPainter(
          points: points,
          imagePath: widget.imagePath,
        ),
        child: Container(),
      ),
    );
  }
}

class AnnotationPainter extends CustomPainter {
  final List<Offset> points;
  final String imagePath;
  ui.Image? image;

  AnnotationPainter({
    required this.points,
    required this.imagePath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    if (points.length > 1) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      
      if (points.length > 2) {
        path.close(); // Close the path if we have enough points
      }
      
      // Draw the stroke
      canvas.drawPath(
        path,
        paint,
      );

      // Draw the fill with semi-transparency
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.yellow.withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) {
    return oldDelegate.points != points;
  }
} 