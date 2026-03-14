import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../../../core/constants/model_config.dart';
import 'dart:math' as math;

/// TFLite detection service with optimized inference
class TFLiteDetectionService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  /// Initialize the TFLite model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final options = InterpreterOptions()..threads = 4;

      _interpreter = await Interpreter.fromAsset(
        ModelConfig.modelPath,
        options: options,
      );

      _isInitialized = true;
      print('✅ Model loaded successfully');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      print('❌ Failed to load model: $e');
      rethrow;
    }
  }

  /// Run inference on preprocessed image data
  Future<List<Map<String, dynamic>>> runInference(Float32List imageData) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('Model not initialized');
    }

    final stopwatch = Stopwatch()..start();

    // Reshape input to [1, 640, 640, 3]
    final input = imageData.reshape([
      1,
      ModelConfig.inputSize,
      ModelConfig.inputSize,
      3,
    ]);

    // Get actual output shape from the model
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    print('📊 Output tensor shape: $outputShape');

    // Allocate output buffer based on actual shape
    // YOLOv8 typically outputs [1, 84, 8400] or [1, 8400, 84]
    final output = List.generate(
      outputShape[0],
      (_) => List.generate(
        outputShape[1],
        (_) => List<double>.filled(outputShape[2], 0.0),
      ),
    );

    // Run inference
    _interpreter!.run(input, output);

    stopwatch.stop();
    print('⏱️ Inference time: ${stopwatch.elapsedMilliseconds}ms');

    // Parse detections
    final detections = _parseDetections(output, outputShape);

    return detections;
  }

  /// Parse YOLO output to detection format
  List<Map<String, dynamic>> _parseDetections(List output, List<int> shape) {
    List<Map<String, dynamic>> detections = [];

    // YOLOv8 can output in two formats:
    // [1, 84, 8400] or [1, 8400, 84]
    // We need to handle both

    final predictions = output[0] as List;

    // Determine format based on shape
    final bool isTransposed = shape[1] > shape[2]; // [1, 8400, 84]
    final int numPredictions = isTransposed ? shape[1] : shape[2];
    final int numChannels = isTransposed ? shape[2] : shape[1];

    print(
        '🔍 Processing $numPredictions predictions with $numChannels channels');
    print(
        '🔄 Format: ${isTransposed ? "transposed [1, 8400, 84]" : "normal [1, 84, 8400]"}');

    for (int i = 0; i < numPredictions; i++) {
      // Get values based on format
      double x, y, w, h;
      List<double> classScores = [];

      if (isTransposed) {
        // Format: [1, 8400, 84] - each prediction is a row
        final pred = predictions[i] as List;
        x = (pred[0] as num).toDouble();
        y = (pred[1] as num).toDouble();
        w = (pred[2] as num).toDouble();
        h = (pred[3] as num).toDouble();

        // Class scores start from index 4
        for (int j = 4;
            j < math.min(4 + ModelConfig.labels.length, pred.length);
            j++) {
          classScores.add((pred[j] as num).toDouble());
        }
      } else {
        // Format: [1, 84, 8400] - each channel is a column
        x = (predictions[0][i] as num).toDouble();
        y = (predictions[1][i] as num).toDouble();
        w = (predictions[2][i] as num).toDouble();
        h = (predictions[3][i] as num).toDouble();

        // Class scores from channels 4 onwards
        for (int j = 4;
            j < math.min(4 + ModelConfig.labels.length, predictions.length);
            j++) {
          classScores.add((predictions[j][i] as num).toDouble());
        }
      }

      // Find max class score
      double maxScore = 0;
      int maxIndex = 0;
      for (int j = 0; j < classScores.length; j++) {
        if (classScores[j] > maxScore) {
          maxScore = classScores[j];
          maxIndex = j;
        }
      }

      // Filter by confidence threshold
      if (maxScore > 0.1) { // Log everything above 0.1 for debugging
        if (maxScore > ModelConfig.confidenceThreshold) {
          print('🎯 High Confidence Detection: ${ModelConfig.labels[maxIndex]} ($maxScore) at [$x, $y]');
          detections.add({
            'class': maxIndex,
            'confidence': maxScore,
            'x': x,
            'y': y,
            'w': w,
            'h': h,
          });
        } else {
          // Low confidence log
          // print('💡 Low Confidence: ${ModelConfig.labels[maxIndex]} ($maxScore)');
        }
      }
    }

    // Apply NMS (Non-Maximum Suppression)
    detections = _applyNMS(detections);

    print('✨ Found ${detections.length} detections after NMS');

    return detections;
  }

  /// Apply Non-Maximum Suppression to remove overlapping boxes
  List<Map<String, dynamic>> _applyNMS(List<Map<String, dynamic>> detections) {
    if (detections.isEmpty) return [];

    // Sort by confidence (descending)
    detections.sort(
      (a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double),
    );

    List<Map<String, dynamic>> result = [];
    List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;

      result.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;

        // Calculate IoU
        final iou = _calculateIoU(detections[i], detections[j]);

        if (iou > ModelConfig.iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return result;
  }

  /// Calculate Intersection over Union
  double _calculateIoU(Map<String, dynamic> box1, Map<String, dynamic> box2) {
    final double x1Min = (box1['x'] as double) - (box1['w'] as double) / 2;
    final double y1Min = (box1['y'] as double) - (box1['h'] as double) / 2;
    final double x1Max = (box1['x'] as double) + (box1['w'] as double) / 2;
    final double y1Max = (box1['y'] as double) + (box1['h'] as double) / 2;

    final double x2Min = (box2['x'] as double) - (box2['w'] as double) / 2;
    final double y2Min = (box2['y'] as double) - (box2['h'] as double) / 2;
    final double x2Max = (box2['x'] as double) + (box2['w'] as double) / 2;
    final double y2Max = (box2['y'] as double) + (box2['h'] as double) / 2;

    final double intersectXMin = math.max(x1Min, x2Min);
    final double intersectYMin = math.max(y1Min, y2Min);
    final double intersectXMax = math.min(x1Max, x2Max);
    final double intersectYMax = math.min(y1Max, y2Max);

    final double intersectArea = math.max(0.0, intersectXMax - intersectXMin) *
        math.max(0.0, intersectYMax - intersectYMin);

    final double box1Area = (x1Max - x1Min) * (y1Max - y1Min);
    final double box2Area = (x2Max - x2Min) * (y2Max - y2Min);

    final double unionArea = box1Area + box2Area - intersectArea;

    return intersectArea / unionArea;
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    print('🗑️ Model resources disposed');
  }

  /// Helper function for min
  T min<T extends num>(T a, T b) => a < b ? a : b;

  /// Helper function for max
  T max<T extends num>(T a, T b) => a > b ? a : b;
}
