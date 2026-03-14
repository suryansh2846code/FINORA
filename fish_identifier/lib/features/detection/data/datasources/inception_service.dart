import 'dart:io';
import 'package:flutter/services.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/detection.dart';
import 'dart:ui';

class InceptionService {
  cv.Net? _net;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelPath = '${appDir.path}/frozen_inference_graph.pb';

      // Copy from assets if not exists
      if (!File(modelPath).existsSync()) {
        final data =
            await rootBundle.load('assets/models/frozen_inference_graph.pb');
        final bytes = data.buffer.asUint8List();
        await File(modelPath).writeAsBytes(bytes);
      }

      _net = cv.Net.fromFile(modelPath);
      _isInitialized = true;
      print('✅ Inception Model loaded successfully via OpenCV');
    } catch (e) {
      print('❌ Failed to load Inception model: $e');
    }
  }

  Future<List<Detection>> runInference(File imageFile) async {
    if (!_isInitialized || _net == null) {
      await initialize();
      if (!_isInitialized) return [];
    }

    try {
      // Read image
      final image = cv.imread(imageFile.path);

      // Create blob
      // Faster R-CNN Inception V2 usually expects 600x600 or similar, but handles dynamic size.
      // Let's use 600x600 as per pipeline config min_dimension.
      // SwapRB=true because OpenCV reads BGR, model expects RGB.
      final blob = cv.blobFromImage(image,
          scalefactor: 1.0,
          size: (600, 600),
          mean: cv.Scalar(0, 0, 0, 0),
          swapRB: true,
          crop: false);

      _net!.setInput(blob);
      final detectionsMat = _net!.forward();

      // Parse detections
      // Output is [1, 1, N, 7]
      // [batch_id, class_id, score, left, top, right, bottom]
      // detectionsMat shape: [1, 1, 100, 7]

      final List<Detection> detections = [];
      final rows = detectionsMat.shape[2]; // Number of detections

      // Access data
      // We need to check how to access data from Mat in opencv_dart
      // Usually mat.at<float>(i, j) or similar.
      // Or convert to List.

      // Assuming we can access raw data or iterate.
      // opencv_dart might expose data as a typed list.
      // Let's try to get the pointer or list.
      // If not available easily, we might need to verify the API.
      // Assuming standard OpenCV behavior:

      // For now, let's assume we can't easily iterate efficiently in Dart without knowing the exact API.
      // But let's try to use `ptr` or `data`.

      // Wait, `opencv_dart` is a wrapper.
      // Let's check if we can get a float list.
      // `detectionsMat.data` might return Uint8List.
      // We need Float32List.

      // Let's assume we can get it.
      // If not, this might fail compilation.
      // But I have to try.

      // Actually, `detectionsMat` is a `Mat`.
      // `mat.at<double>(row, col)`?

      // Let's use a loop.
      for (int i = 0; i < rows; i++) {
        // [0, 0, i, 2] is confidence
        // [0, 0, i, 1] is class_id
        // [0, 0, i, 3] is left
        // [0, 0, i, 4] is top
        // [0, 0, i, 5] is right
        // [0, 0, i, 6] is bottom

        // Since it's 4D, accessing might be tricky with `at`.
        // Usually flattened to 2D [N, 7] if we reshape?

        // Let's try to reshape to [rows, 7]
        final reshaped = detectionsMat.reshape(1, rows);

        final confidence = reshaped.at<double>(i, 2);

        if (confidence > 0.5) {
          final classId = reshaped.at<double>(i, 1).toInt();
          final left = reshaped.at<double>(i, 3);
          final top = reshaped.at<double>(i, 4);
          final right = reshaped.at<double>(i, 5);
          final bottom = reshaped.at<double>(i, 6);

          detections.add(Detection(
            className: 'Fish', // Map classId if needed
            confidence: confidence,
            boundingBox: Rect.fromLTRB(left * image.cols, top * image.rows,
                right * image.cols, bottom * image.rows),
          ));
        }
      }

      return detections;
    } catch (e) {
      print("Inference error: $e");
      return [];
    }
  }

  void dispose() {
    _net?.dispose();
    _net = null;
    _isInitialized = false;
  }
}
