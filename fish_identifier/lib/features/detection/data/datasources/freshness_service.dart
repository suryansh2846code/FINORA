import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../domain/entities/freshness_result.dart';

class FreshnessService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  static const int _inputSize = 224;
  static const String _modelPath = 'assets/models/fish_freshness.tflite';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final options = InterpreterOptions();
      // Use XNNPACK delegate for better performance if available, or GPU delegate
      // For now, default CPU options are usually fine for MobileNet/EfficientNet on modern phones

      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
      _isInitialized = true;
      print('✅ Freshness Model loaded successfully');
    } catch (e) {
      print('❌ Failed to load Freshness model: $e');
    }
  }

  Future<FreshnessResult?> predict(File imageFile) async {
    if (!_isInitialized || _interpreter == null) {
      await initialize();
      if (!_isInitialized) return null;
    }

    try {
      // 1. Read and resize image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) return null;

      final resizedImage =
          img.copyResize(image, width: _inputSize, height: _inputSize);

      // 2. Preprocess (Normalize to [0, 1] and then standard normalization if needed)
      // EfficientNet usually expects normalization: mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
      // But let's check the training script.
      // Yes: transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])

      final input = Float32List(1 * _inputSize * _inputSize * 3);
      var pixelIndex = 0;

      for (var y = 0; y < _inputSize; y++) {
        for (var x = 0; x < _inputSize; x++) {
          final pixel = resizedImage.getPixel(x, y);

          // Normalize RGB
          final r = pixel.r / 255.0;
          final g = pixel.g / 255.0;
          final b = pixel.b / 255.0;

          input[pixelIndex++] = (r - 0.485) / 0.229;
          input[pixelIndex++] = (g - 0.456) / 0.224;
          input[pixelIndex++] = (b - 0.406) / 0.225;
        }
      }

      // Reshape input to [1, 224, 224, 3] or [1, 3, 224, 224] depending on model
      // PyTorch is NCHW [1, 3, 224, 224].
      // TFLite conversion usually keeps NCHW or converts to NHWC.
      // onnx2tf usually converts to NHWC [1, 224, 224, 3] for TFLite compatibility.
      // Let's assume NHWC for now as it's standard for TFLite.
      // Wait, if I filled the buffer as RGB RGB RGB, that is NHWC (pixel-interleaved).
      // If the model expects NCHW (planar), I should fill RRR GGG BBB.

      // Let's check the input shape of the interpreter if possible, or assume NHWC.
      final inputShape = _interpreter!.getInputTensor(0).shape;
      // print('Input shape: $inputShape');

      // If input shape is [1, 3, 224, 224], we need planar.
      // If input shape is [1, 224, 224, 3], we need interleaved.

      // I'll implement a check based on shape.
      Object inputTensor;
      if (inputShape[1] == 3) {
        // NCHW
        final planarInput = Float32List(1 * 3 * _inputSize * _inputSize);
        int rIdx = 0;
        int gIdx = _inputSize * _inputSize;
        int bIdx = 2 * _inputSize * _inputSize;

        for (var y = 0; y < _inputSize; y++) {
          for (var x = 0; x < _inputSize; x++) {
            final pixel = resizedImage.getPixel(x, y);
            planarInput[rIdx++] = ((pixel.r / 255.0) - 0.485) / 0.229;
            planarInput[gIdx++] = ((pixel.g / 255.0) - 0.456) / 0.224;
            planarInput[bIdx++] = ((pixel.b / 255.0) - 0.406) / 0.225;
          }
        }
        inputTensor = planarInput.reshape([1, 3, _inputSize, _inputSize]);
      } else {
        // NHWC
        inputTensor = input.reshape([1, _inputSize, _inputSize, 3]);
      }

      // 3. Run Inference
      final outputTensor = Float32List(1)
          .reshape([1, 1]); // Output is [1, 1] (sigmoid probability)

      _interpreter!.run(inputTensor, outputTensor);

      // 4. Parse Result
      final score = outputTensor[0][0];

      // 0 = Fresh, 1 = Not Fresh (based on previous analysis)
      // If score > 0.5, it's Not Fresh.
      // Confidence: if > 0.5, confidence is score. If < 0.5, confidence is 1 - score.

      final isFresh = score <= 0.5;
      final confidence = isFresh ? (1.0 - score) : score;

      return FreshnessResult(isFresh: isFresh, confidence: confidence);
    } catch (e) {
      print("Freshness inference error: $e");
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
