import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../entities/detection.dart';

/// Abstract repository interface for detection operations
abstract class DetectionRepository {
  /// Detect objects in an image from a file
  Future<List<Detection>> detectFromFile(File imageFile);

  /// Pick image from camera or gallery
  Future<File?> pickImage(ImageSource source);

  /// Initialize the model
  Future<void> initialize();

  /// Dispose resources
  Future<void> dispose();
}
