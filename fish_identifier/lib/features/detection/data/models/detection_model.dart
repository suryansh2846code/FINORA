import 'dart:ui';
import '../../domain/entities/detection.dart';
import '../../../../core/constants/model_config.dart';

/// Data model for Detection with JSON serialization
class DetectionModel extends Detection {
  const DetectionModel({
    required super.className,
    required super.confidence,
    required super.boundingBox,
  });

  /// Create from raw detection data and image dimensions
  factory DetectionModel.fromRawData(
    Map<String, dynamic> data,
    double imageWidth,
    double imageHeight, {
    double scale = 1.0,
    double padX = 0.0,
    double padY = 0.0,
  }) {
    final classIndex = data['class'] as int;
    final className =
        classIndex < ModelConfig.labels.length
            ? ModelConfig.labels[classIndex]
            : 'unknown';

    // 1. Coordinates from YOLOv8 TFLite are often already in pixel space [0, 640].
    // If they are normalized [0, 1], we scale them. If they are > 1, they are already px.
    final double rawX = data['x'] as double;
    final double rawY = data['y'] as double;
    final double rawW = data['w'] as double;
    final double rawH = data['h'] as double;

    final inputX = rawX > 1.1 ? rawX : rawX * ModelConfig.inputSize;
    final inputY = rawY > 1.1 ? rawY : rawY * ModelConfig.inputSize;
    final inputW = rawW > 1.1 ? rawW : rawW * ModelConfig.inputSize;
    final inputH = rawH > 1.1 ? rawH : rawH * ModelConfig.inputSize;

    // Additional filter for 'shrimp' which has high false positive rate on humans
    if (className.toLowerCase() == 'shrimp' && (data['confidence'] as double) < 0.65) {
      // Invalidate if shrimp confidence is too low
      return DetectionModel(
        className: 'unreliable',
        confidence: 0,
        boundingBox: Rect.zero,
      );
    }

    // 2. Subtract padding to get coordinates relative to the resized image area
    final resizedX = inputX - padX;
    final resizedY = inputY - padY;

    // 3. Scale back to original image dimensions
    final centerX = resizedX / scale;
    final centerY = resizedY / scale;
    final width = inputW / scale;
    final height = inputH / scale;

    // Convert from center format to corner format
    final left = centerX - width / 2;
    final top = centerY - height / 2;

    return DetectionModel(
      className: className,
      confidence: data['confidence'] as double,
      boundingBox: Rect.fromLTWH(left, top, width, height),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'confidence': confidence,
      'boundingBox': {
        'left': boundingBox.left,
        'top': boundingBox.top,
        'right': boundingBox.right,
        'bottom': boundingBox.bottom,
      },
    };
  }

  /// Create from JSON
  factory DetectionModel.fromJson(Map<String, dynamic> json) {
    final bbox = json['boundingBox'] as Map<String, dynamic>;
    return DetectionModel(
      className: json['className'] as String,
      confidence: json['confidence'] as double,
      boundingBox: Rect.fromLTRB(
        bbox['left'] as double,
        bbox['top'] as double,
        bbox['right'] as double,
        bbox['bottom'] as double,
      ),
    );
  }
}
