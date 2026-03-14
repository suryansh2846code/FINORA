import 'dart:io';
import '../repositories/detection_repository.dart';
import '../entities/detection.dart';

/// Use case for detecting objects in an image
class DetectObjects {
  final DetectionRepository repository;

  DetectObjects(this.repository);

  Future<List<Detection>> call(File imageFile) async {
    return await repository.detectFromFile(imageFile);
  }
}
