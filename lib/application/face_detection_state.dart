import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:face_imv/application/bloc_status.dart';
import 'package:face_imv/domain/face_entity.dart';
import 'package:face_imv/domain/i_face_detector.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart' as ml_kit;

part 'face_detection_state.freezed.dart';

@freezed
abstract class FaceDetectionState with _$FaceDetectionState {
  const factory FaceDetectionState({
    @Default(BlocStatus()) BlocStatus status,
    @Default([]) List<FaceEntity> faces,
  }) = _FaceDetectionState;
}

class FaceDetectionCubit extends Cubit<FaceDetectionState> {
  final IFaceDetector _faceDetector;

  FaceDetectionCubit(this._faceDetector) : super( FaceDetectionState());

  Future<void> processImage(ml_kit.InputImage inputImage) async {
    
    final result = await _faceDetector.detectFromInputImage(inputImage);

    result.fold(
      (error) => emit(state.copyWith(status: BlocStatus.fail(error))),
      (faces) => emit(state.copyWith(
        status: BlocStatus.success(),
        faces: faces,
      )),
    );
  }

  @override
  Future<void> close() {
    _faceDetector.dispose();
    return super.close();
  }
}
