import 'dart:io';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../domain/entities/detection.dart';
import '../../domain/entities/freshness_result.dart';

/// States for detection BLoC
abstract class DetectionState extends Equatable {
  const DetectionState();

  @override
  List<Object?> get props => [];
}

class DetectionInitial extends DetectionState {
  const DetectionInitial();
}

class DetectionLoading extends DetectionState {
  final String message;

  const DetectionLoading([this.message = 'Processing...']);

  @override
  List<Object?> get props => [message];
}

class DetectionSuccess extends DetectionState {
  final File imageFile;
  final List<Detection> detections;
  final int inferenceTime;
  final Uint8List? maskBytes;
  final FreshnessResult? freshnessResult;

  const DetectionSuccess({
    required this.imageFile,
    required this.detections,
    required this.inferenceTime,
    this.maskBytes,
    this.freshnessResult,
  });

  @override
  List<Object?> get props =>
      [imageFile, detections, inferenceTime, maskBytes, freshnessResult];

  DetectionSuccess copyWith({
    File? imageFile,
    List<Detection>? detections,
    int? inferenceTime,
    Uint8List? maskBytes,
    FreshnessResult? freshnessResult,
  }) {
    return DetectionSuccess(
      imageFile: imageFile ?? this.imageFile,
      detections: detections ?? this.detections,
      inferenceTime: inferenceTime ?? this.inferenceTime,
      maskBytes: maskBytes ?? this.maskBytes,
      freshnessResult: freshnessResult ?? this.freshnessResult,
    );
  }
}

class DetectionError extends DetectionState {
  final String message;

  const DetectionError(this.message);

  @override
  List<Object?> get props => [message];
}
