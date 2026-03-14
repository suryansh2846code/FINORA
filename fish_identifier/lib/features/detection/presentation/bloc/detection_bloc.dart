import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/repositories/detection_repository.dart';
import '../../domain/usecases/detect_objects.dart';
import '../../data/datasources/freshness_service.dart';
import 'detection_event.dart';
import 'detection_state.dart';
import '../../../../core/errors/failures.dart';

/// BLoC for managing detection state
class DetectionBloc extends Bloc<DetectionEvent, DetectionState> {
  final DetectionRepository repository;
  final DetectObjects detectObjectsUseCase;
  final FreshnessService freshnessService;

  DetectionBloc({
    required this.repository,
    required this.detectObjectsUseCase,
    required this.freshnessService,
  }) : super(const DetectionInitial()) {
    on<InitializeModel>(_onInitializeModel);
    on<PickImageFromCamera>(_onPickImageFromCamera);
    on<PickImageFromGallery>(_onPickImageFromGallery);
    on<DetectObjectsEvent>(_onDetectObjectsEvent);
    on<ResetDetection>(_onResetDetection);
    on<CheckFreshness>(_onCheckFreshness);
  }

  Future<void> _onInitializeModel(
    InitializeModel event,
    Emitter<DetectionState> emit,
  ) async {
    emit(const DetectionLoading('Initializing model...'));

    try {
      await repository.initialize();
      emit(const DetectionInitial());
    } catch (e) {
      emit(DetectionError('Failed to initialize: ${_getErrorMessage(e)}'));
    }
  }

  Future<void> _onPickImageFromCamera(
    PickImageFromCamera event,
    Emitter<DetectionState> emit,
  ) async {
    try {
      emit(const DetectionLoading('Opening camera...'));

      final imageFile = await repository.pickImage(ImageSource.camera);

      if (imageFile != null) {
        add(DetectObjectsEvent(imageFile));
      } else {
        emit(const DetectionInitial());
      }
    } catch (e) {
      emit(DetectionError('Failed to pick image: ${_getErrorMessage(e)}'));
    }
  }

  Future<void> _onPickImageFromGallery(
    PickImageFromGallery event,
    Emitter<DetectionState> emit,
  ) async {
    try {
      emit(const DetectionLoading('Opening gallery...'));

      final imageFile = await repository.pickImage(ImageSource.gallery);

      if (imageFile != null) {
        add(DetectObjectsEvent(imageFile));
      } else {
        emit(const DetectionInitial());
      }
    } catch (e) {
      emit(DetectionError('Failed to pick image: ${_getErrorMessage(e)}'));
    }
  }

  Future<void> _onDetectObjectsEvent(
    DetectObjectsEvent event,
    Emitter<DetectionState> emit,
  ) async {
    emit(const DetectionLoading('Analyzing image...'));

    try {
      final stopwatch = Stopwatch()..start();

      final detections = await detectObjectsUseCase(event.imageFile);

      stopwatch.stop();

      emit(
        DetectionSuccess(
          imageFile: event.imageFile,
          detections: detections,
          inferenceTime: stopwatch.elapsedMilliseconds,
        ),
      );
    } catch (e) {
      log(e.toString());
      emit(DetectionError('Detection failed: ${_getErrorMessage(e)}'));
    }
  }

  Future<void> _onResetDetection(
    ResetDetection event,
    Emitter<DetectionState> emit,
  ) async {
    emit(const DetectionInitial());
  }

  Future<void> _onCheckFreshness(
    CheckFreshness event,
    Emitter<DetectionState> emit,
  ) async {
    final currentState = state;
    if (currentState is DetectionSuccess) {
      // Emit loading state while keeping current data?
      // Or just update UI to show loading.
      // Ideally we should have a specific loading state or a flag in DetectionSuccess.
      // But DetectionSuccess is immutable.
      // Let's assume we can just do the work and emit updated state.
      // To show loading, we might need a separate state or field.
      // For MVP, let's just run it. If it's fast (TFLite usually is), it might be fine.
      // Or we can emit a copy with null result first if we want to clear previous result.

      try {
        final result = await freshnessService.predict(event.imageFile);
        emit(currentState.copyWith(freshnessResult: result));
      } catch (e) {
        // Handle error, maybe show snackbar via listener in UI
        log('Freshness check failed: $e');
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is Failure) {
      return error.message;
    }
    return error.toString();
  }

  @override
  Future<void> close() {
    repository.dispose();
    return super.close();
  }
}
