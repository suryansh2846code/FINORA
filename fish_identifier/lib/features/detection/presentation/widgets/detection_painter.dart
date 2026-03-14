import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Custom painter for drawing bounding boxes on detected objects
import '../../domain/entities/detection.dart';

/// Custom painter for drawing bounding boxes on detected objects
class DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final ui.Image? image;

  DetectionPainter({required this.detections, this.image});

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;

    // Calculate scale to fit image in widget
    final imageAspect = image!.width / image!.height;
    final widgetAspect = size.width / size.height;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    if (imageAspect > widgetAspect) {
      // Image is wider - fit to width
      scale = size.width / image!.width;
      offsetY = (size.height - image!.height * scale) / 2;
    } else {
      // Image is taller - fit to height
      scale = size.height / image!.height;
      offsetX = (size.width - image!.width * scale) / 2;
    }

    final boxColor = const Color(0xFF006D77);
    final labelColor = const Color(0xFF83C5BE);

    for (int i = 0; i < detections.length; i++) {
      final detection = detections[i];
      final rect = detection.boundingBox;

      // Scale bounding box to widget size
      final scaledRect = Rect.fromLTWH(
        rect.left * scale + offsetX,
        rect.top * scale + offsetY,
        rect.width * scale,
        rect.height * scale,
      );

      // Draw bounding box with rounded corners (using path)
      final boxPaint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)),
        boxPaint,
      );

      // Draw label background
      final className = detection.className;
      final confidence = detection.confidence;
      final labelText = '${className.toUpperCase()} ${(confidence * 100).toStringAsFixed(0)}%';
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Color(0xFF006D77),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final labelRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          scaledRect.left,
          scaledRect.top - textPainter.height - 10,
          textPainter.width + 16,
          textPainter.height + 10,
        ),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      );

      final labelPaint = Paint()
        ..color = labelColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(labelRect, labelPaint);

      // Draw label text
      textPainter.paint(
        canvas,
        Offset(scaledRect.left + 8, scaledRect.top - textPainter.height - 5),
      );
    }
  }

  @override
  bool shouldRepaint(DetectionPainter oldDelegate) {
    return detections != oldDelegate.detections || image != oldDelegate.image;
  }
}
