import 'package:get_it/get_it.dart';
import '../../features/detection/data/datasources/tflite_detection_service.dart';
import '../../features/detection/data/datasources/freshness_service.dart';
import '../../features/detection/data/repositories/detection_repository_impl.dart';
import '../../features/detection/domain/repositories/detection_repository.dart';
import '../../features/detection/domain/usecases/detect_objects.dart';
import '../../features/detection/presentation/bloc/detection_bloc.dart';

final getIt = GetIt.instance;

/// Setup dependency injection
Future<void> setupDependencyInjection() async {
  // Services (Singletons)
  getIt.registerLazySingleton<TFLiteDetectionService>(
    () => TFLiteDetectionService(),
  );
  getIt.registerLazySingleton<FreshnessService>(
    () => FreshnessService(),
  );

  // Repositories
  getIt.registerLazySingleton<DetectionRepository>(
    () => DetectionRepositoryImpl(
      detectionService: getIt<TFLiteDetectionService>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<DetectObjects>(
    () => DetectObjects(getIt<DetectionRepository>()),
  );

  // BLoCs (Factories - new instance each time)
  getIt.registerFactory<DetectionBloc>(
    () => DetectionBloc(
      repository: getIt<DetectionRepository>(),
      detectObjectsUseCase: getIt<DetectObjects>(),
      freshnessService: getIt<FreshnessService>(),
    ),
  );
}
