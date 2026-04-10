import 'package:get_it/get_it.dart';
import 'package:face_imv/application/camera_state.dart';
import 'package:face_imv/application/face_detection_state.dart';
import 'package:face_imv/infrastructure/ml_kit_face_detector.dart';
import 'package:face_imv/domain/i_face_detector.dart';

final getIt = GetIt.instance;

void setupDependencyInjection() {
  // Infrastructure
  getIt.registerLazySingleton<IFaceDetector>(() => MLKitFaceDetector());

  // Application
  getIt.registerFactory(() => CameraCubit());
  getIt.registerFactory(() => FaceDetectionCubit(getIt<IFaceDetector>()));
}
