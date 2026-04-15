import 'dart:ui';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'face_entity.freezed.dart';

@freezed
abstract class FaceEntity with _$FaceEntity {
  const factory FaceEntity({
    required Rect boundingBox,
    required double? headEulerAngleX, // Pitch
    required double? headEulerAngleY, // Yaw
    required double? headEulerAngleZ, // Roll
    required Map<FaceLandmarkType, Offset> landmarks,
    @Default({}) Map<FaceContourType, List<Offset>> contours,
    int? trackingId,
    @Default(0.0) double? smilingProbability,
    @Default(0.0) double? leftEyeOpenProbability,
    @Default(0.0) double? rightEyeOpenProbability,
    String? age, // Placeholder for future TFLite model
    String? gender, // Placeholder for future TFLite model
  }) = _FaceEntity;
}

enum FaceLandmarkType {
  bottomMouth,
  leftCheek,
  leftEar,
  leftEye,
  leftMouth,
  noseBase,
  rightCheek,
  rightEar,
  rightEye,
  rightMouth,
}

enum FaceContourType {
  face,
  leftCheek,
  leftEye,
  leftEyebrowBottom,
  leftEyebrowTop,
  lowerLipBottom,
  lowerLipTop,
  noseBottom,
  noseBridge,
  rightCheek,
  rightEye,
  rightEyebrowBottom,
  rightEyebrowTop,
  upperLipBottom,
  upperLipTop,
}

extension FaceEntityMetrics on FaceEntity {
  double get width => boundingBox.width;
  double get height => boundingBox.height;
  double get yaw => headEulerAngleY ?? 0.0;
  double get pitch => headEulerAngleX ?? 0.0;
  double get roll => headEulerAngleZ ?? 0.0;

  bool hasLandmark(FaceLandmarkType type) => landmarks.containsKey(type);
}
