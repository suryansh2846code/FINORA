import 'dart:io';
import 'package:equatable/equatable.dart';

/// Events for detection BLoC
abstract class DetectionEvent extends Equatable {
  const DetectionEvent();

  @override
  List<Object?> get props => [];
}

class InitializeModel extends DetectionEvent {
  const InitializeModel();
}

class PickImageFromCamera extends DetectionEvent {
  const PickImageFromCamera();
}

class PickImageFromGallery extends DetectionEvent {
  const PickImageFromGallery();
}

class DetectObjectsEvent extends DetectionEvent {
  final File imageFile;

  const DetectObjectsEvent(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}

class ResetDetection extends DetectionEvent {
  const ResetDetection();
}

class CheckFreshness extends DetectionEvent {
  final File imageFile;

  const CheckFreshness(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}
