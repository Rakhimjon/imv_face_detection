import 'dart:io';
import 'dart:ui';
import 'package:fpdart/fpdart.dart';
import 'package:face_imv/domain/face_entity.dart';
import 'package:face_imv/domain/i_face_detector.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    as ml_kit;

class MLKitFaceDetector implements IFaceDetector {
  final ml_kit.FaceDetector _detector;

  MLKitFaceDetector({ml_kit.FaceDetectorOptions? options})
    : _detector = ml_kit.FaceDetector(
        options:
            options ??
            ml_kit.FaceDetectorOptions(
              enableLandmarks: true,
              enableClassification: true,
              enableTracking: true,
              enableContours: true,
              minFaceSize: 0.15,
              performanceMode: ml_kit.FaceDetectorMode.accurate,
            ),
      );

  @override
  Future<Either<String, List<FaceEntity>>> detectFromImage(
    File imageFile,
  ) async {
    try {
      final inputImage = ml_kit.InputImage.fromFile(imageFile);
      return detectFromInputImage(inputImage);
    } catch (e) {
      return Left('Failed to process image: $e');
    }
  }

  @override
  Future<Either<String, List<FaceEntity>>> detectFromInputImage(
    ml_kit.InputImage inputImage,
  ) async {
    try {
      final faces = await _detector.processImage(inputImage);
      final entities = faces.map(_mapToEntity).toList();
      return Right(entities);
    } catch (e, stackTrace) {
      return Left('ML Kit Detection Error: $e');
    }
  }

  FaceEntity _mapToEntity(ml_kit.Face face) {
    final landmarks = <FaceLandmarkType, Offset>{};

    for (final landmark in face.landmarks.values) {
      if (landmark != null) {
        final type = _mapLandmarkType(landmark.type);
        if (type != null) {
          landmarks[type] = Offset(
            landmark.position.x.toDouble(),
            landmark.position.y.toDouble(),
          );
        }
      }
    }

    final contours = <FaceContourType, List<Offset>>{};
    for (final contour in face.contours.values) {
      if (contour != null) {
        final type = _mapContourType(contour.type);
        if (type != null) {
          contours[type] = contour.points
              .map((point) => Offset(point.x.toDouble(), point.y.toDouble()))
              .toList();
        }
      }
    }

    return FaceEntity(
      boundingBox: face.boundingBox,
      headEulerAngleX: face.headEulerAngleX,
      headEulerAngleY: face.headEulerAngleY,
      headEulerAngleZ: face.headEulerAngleZ,
      landmarks: landmarks,
      contours: contours,
      trackingId: face.trackingId,
      smilingProbability: face.smilingProbability,
      leftEyeOpenProbability: face.leftEyeOpenProbability,
      rightEyeOpenProbability: face.rightEyeOpenProbability,
    );
  }

  FaceLandmarkType? _mapLandmarkType(ml_kit.FaceLandmarkType type) {
    switch (type) {
      case ml_kit.FaceLandmarkType.bottomMouth:
        return FaceLandmarkType.bottomMouth;
      case ml_kit.FaceLandmarkType.leftCheek:
        return FaceLandmarkType.leftCheek;
      case ml_kit.FaceLandmarkType.leftEar:
        return FaceLandmarkType.leftEar;
      case ml_kit.FaceLandmarkType.leftEye:
        return FaceLandmarkType.leftEye;
      case ml_kit.FaceLandmarkType.leftMouth:
        return FaceLandmarkType.leftMouth;
      case ml_kit.FaceLandmarkType.noseBase:
        return FaceLandmarkType.noseBase;
      case ml_kit.FaceLandmarkType.rightCheek:
        return FaceLandmarkType.rightCheek;
      case ml_kit.FaceLandmarkType.rightEar:
        return FaceLandmarkType.rightEar;
      case ml_kit.FaceLandmarkType.rightEye:
        return FaceLandmarkType.rightEye;
      case ml_kit.FaceLandmarkType.rightMouth:
        return FaceLandmarkType.rightMouth;
      default:
        return null;
    }
  }

  FaceContourType? _mapContourType(ml_kit.FaceContourType type) {
    switch (type) {
      case ml_kit.FaceContourType.face:
        return FaceContourType.face;
      case ml_kit.FaceContourType.leftCheek:
        return FaceContourType.leftCheek;
      case ml_kit.FaceContourType.leftEye:
        return FaceContourType.leftEye;
      case ml_kit.FaceContourType.leftEyebrowBottom:
        return FaceContourType.leftEyebrowBottom;
      case ml_kit.FaceContourType.leftEyebrowTop:
        return FaceContourType.leftEyebrowTop;
      case ml_kit.FaceContourType.lowerLipBottom:
        return FaceContourType.lowerLipBottom;
      case ml_kit.FaceContourType.lowerLipTop:
        return FaceContourType.lowerLipTop;
      case ml_kit.FaceContourType.noseBottom:
        return FaceContourType.noseBottom;
      case ml_kit.FaceContourType.noseBridge:
        return FaceContourType.noseBridge;
      case ml_kit.FaceContourType.rightCheek:
        return FaceContourType.rightCheek;
      case ml_kit.FaceContourType.rightEye:
        return FaceContourType.rightEye;
      case ml_kit.FaceContourType.rightEyebrowBottom:
        return FaceContourType.rightEyebrowBottom;
      case ml_kit.FaceContourType.rightEyebrowTop:
        return FaceContourType.rightEyebrowTop;
      case ml_kit.FaceContourType.upperLipBottom:
        return FaceContourType.upperLipBottom;
      case ml_kit.FaceContourType.upperLipTop:
        return FaceContourType.upperLipTop;
      default:
        return null;
    }
  }

  @override
  Future<void> dispose() async {
    await _detector.close();
  }
}
