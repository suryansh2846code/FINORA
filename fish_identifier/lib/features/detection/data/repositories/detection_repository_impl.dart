import 'dart:developer';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/detection.dart';
import '../../domain/repositories/detection_repository.dart';
import '../datasources/tflite_detection_service.dart';
import '../models/detection_model.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/constants/model_config.dart';
import '../../../../core/errors/failures.dart';

/// Implementation of detection repository
class DetectionRepositoryImpl implements DetectionRepository {
  final TFLiteDetectionService _detectionService;
  final ImagePicker _imagePicker;

  DetectionRepositoryImpl({
    required TFLiteDetectionService detectionService,
    ImagePicker? imagePicker,
  })  : _detectionService = detectionService,
        _imagePicker = imagePicker ?? ImagePicker();

  @override
  Future<void> initialize() async {
    try {
      await _detectionService.initialize();
    } catch (e) {
      throw ModelLoadFailure('Failed to initialize model: $e');
    }
  }

  @override
  Future<List<Detection>> detectFromFile(File imageFile) async {
    try {
      // Decode image for dimensions
      final decodedImage = await ImageUtils.decodeImage(imageFile);
      if (decodedImage == null) {
        throw const ImageProcessingFailure('Could not decode image');
      }

      final imageWidth = decodedImage.width.toDouble();
      final imageHeight = decodedImage.height.toDouble();

      // Preprocess image with letterboxing
      final preprocessResult = await ImageUtils.preprocessImage(
        imageFile,
        ModelConfig.inputSize,
      );

      // Run inference
      final rawDetections = await _detectionService.runInference(
        preprocessResult.data,
      );

      // Convert to domain entities with proper scaling and padding removal
      final detections = rawDetections.map((data) {
        return DetectionModel.fromRawData(
          data,
          imageWidth,
          imageHeight,
          scale: preprocessResult.scale,
          padX: preprocessResult.padX,
          padY: preprocessResult.padY,
        );
      }).where((d) => d.className != 'unreliable' && d.confidence > 0).toList();

      return detections;
    } catch (e) {
      if (e is Failure) rethrow;
      log(e.toString());
      throw InferenceFailure('Detection failed: $e');
    }
  }

  @override
  Future<File?> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      throw ImagePickFailure('Failed to pick image: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _detectionService.dispose();
  }
}
