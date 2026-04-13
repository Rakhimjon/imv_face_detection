import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:face_imv/application/bloc_status.dart';

part 'camera_state.freezed.dart';

@freezed
abstract class CameraState with _$CameraState {
  const factory CameraState({
    @Default(BlocStatus()) BlocStatus status,
    CameraController? controller,
    @Default(CameraLensDirection.front) CameraLensDirection selectedDirection,
  }) = _CameraState;
}

class CameraCubit extends Cubit<CameraState> {
  CameraCubit() : super(const CameraState());

  Future<void> initialize() async {
    // Release previous controller if any
    await stopCamera();
    
    emit(state.copyWith(status: BlocStatus.loading()));
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        emit(state.copyWith(status: BlocStatus.fail('No cameras found')));
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == state.selectedDirection,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.nv21 
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      emit(state.copyWith(
        status: BlocStatus.success(),
        controller: controller,
      ));
    } catch (e) {
      emit(state.copyWith(status: BlocStatus.fail('Camera Error: $e')));
    }
  }

  Future<void> stopCamera() async {
    if (state.controller != null) {
      if (state.controller!.value.isStreamingImages) {
        await state.controller!.stopImageStream();
      }
      await state.controller!.dispose();
      emit(state.copyWith(controller: null));
    }
  }

  Future<void> switchCamera() async {
    final newDirection = state.selectedDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    
    emit(state.copyWith(selectedDirection: newDirection));
    await initialize();
  }

  @override
  Future<void> close() async {
    await stopCamera();
    return super.close();
  }
}
