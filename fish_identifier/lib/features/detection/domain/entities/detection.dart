import 'package:equatable/equatable.dart';
import 'dart:ui';

/// Domain entity representing a detected object
class Detection extends Equatable {
  final String className;
  final double confidence;
  final Rect boundingBox;

  const Detection({
    required this.className,
    required this.confidence,
    required this.boundingBox,
  });

  @override
  List<Object?> get props => [className, confidence, boundingBox];

  @override
  String toString() {
    return 'Detection(class: $className, confidence: ${(confidence * 100).toStringAsFixed(1)}%, box: $boundingBox)';
  }
}
