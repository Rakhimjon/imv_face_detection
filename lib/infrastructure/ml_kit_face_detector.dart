import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
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

      // 🔍 DEBUG LOGGING - Face Detection Results
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════');
        debugPrint('🎯 FACE DETECTION ANALYSIS');
        debugPrint('═══════════════════════════════════════════════');
        debugPrint('📊 Faces detected: ${faces.length}');

        for (var i = 0; i < faces.length; i++) {
          final face = faces[i];
          debugPrint('\n👤 Face #${i + 1}:');
          debugPrint('  📏 Bounding Box: ${face.boundingBox}');
          debugPrint('  🎭 Tracking ID: ${face.trackingId ?? "N/A"}');

          // Head Rotation Analysis
          debugPrint('\n  🔄 HEAD ROTATION (Euler Angles):');
          final pitch = face.headEulerAngleX ?? 0.0;
          final yaw = face.headEulerAngleY ?? 0.0;
          final roll = face.headEulerAngleZ ?? 0.0;
          debugPrint(
            '    ↕️  Pitch (X): ${pitch.toStringAsFixed(2)}° ${_getPitchDirection(pitch)}',
          );
          debugPrint(
            '    ↔️  Yaw (Y):   ${yaw.toStringAsFixed(2)}° ${_getYawDirection(yaw)}',
          );
          debugPrint(
            '    🔃 Roll (Z):  ${roll.toStringAsFixed(2)}° ${_getRollDirection(roll)}',
          );

          // Eye & Smile Detection
          debugPrint('\n  😊 FACIAL EXPRESSIONS:');
          final leftEye = face.leftEyeOpenProbability ?? 0.0;
          final rightEye = face.rightEyeOpenProbability ?? 0.0;
          final smile = face.smilingProbability ?? 0.0;
          debugPrint(
            '    👁️  Left Eye:  ${(leftEye * 100).toStringAsFixed(1)}% ${leftEye > 0.7
                ? "OPEN ✅"
                : leftEye < 0.3
                ? "CLOSED ❌"
                : "PARTIAL 👀"}',
          );
          debugPrint(
            '    👁️  Right Eye: ${(rightEye * 100).toStringAsFixed(1)}% ${rightEye > 0.7
                ? "OPEN ✅"
                : rightEye < 0.3
                ? "CLOSED ❌"
                : "PARTIAL 👀"}',
          );
          debugPrint(
            '    😄 Smile:     ${(smile * 100).toStringAsFixed(1)}% ${smile > 0.7 ? "SMILING 😊" : "NEUTRAL 😐"}',
          );

          // Face Quality Checks
          debugPrint('\n  ✅ FACE QUALITY VALIDATION:');
          final faceSize = face.boundingBox.width;
          debugPrint(
            '    📐 Face Width: ${faceSize.toStringAsFixed(0)}px ${_getFaceSizeQuality(faceSize)}',
          );
          debugPrint(
            '    🎯 Position: ${_isHeadCentered(yaw, pitch) ? "CENTERED ✅" : "OFF-CENTER ⚠️"}',
          );
          debugPrint(
            '    👁️  Blink Detection: ${leftEye < 0.35 && rightEye < 0.35 ? "BLINKING 👀" : "EYES OPEN ✅"}',
          );
          debugPrint(
            '    🧑 Human Face: ${_isHumanFace(face) ? "VERIFIED ✅" : "UNCERTAIN ⚠️"}',
          );

          // Landmarks
          if (face.landmarks.isNotEmpty) {
            debugPrint('\n  📍 LANDMARKS DETECTED: ${face.landmarks.length}');
            for (final landmark in face.landmarks.values) {
              if (landmark != null) {
                debugPrint(
                  '    - ${landmark.type.name}: (${landmark.position.x.toInt()}, ${landmark.position.y.toInt()})',
                );
              }
            }
          }

          // Contours
          if (face.contours.isNotEmpty) {
            debugPrint('  🎨 CONTOURS DETECTED: ${face.contours.length}');
          }
        }

        debugPrint('═══════════════════════════════════════════════\n');
      }

      final entities = faces.map(_mapToEntity).toList();
      return Right(entities);
    } catch (e) {
      debugPrint('❌ ML Kit Detection Error: $e');
      return Left('ML Kit Detection Error: $e');
    }
  }

  // Helper methods for debug analysis
  String _getPitchDirection(double pitch) {
    if (pitch < -15) return '(Looking DOWN ⬇️)';
    if (pitch > 15) return '(Looking UP ⬆️)';
    return '(Looking STRAIGHT 👁️)';
  }

  String _getYawDirection(double yaw) {
    if (yaw < -20) return '(Turning LEFT ⬅️)';
    if (yaw > 20) return '(Turning RIGHT ➡️)';
    return '(Facing CENTER 🎯)';
  }

  String _getRollDirection(double roll) {
    if (roll.abs() < 10) return '(Head STRAIGHT 📏)';
    return '(Head TILTED 🔄)';
  }

  String _getFaceSizeQuality(double width) {
    if (width > 280) return '(TOO CLOSE 🔴 - Move back)';
    if (width < 100) return '(TOO FAR 🟡 - Move closer)';
    return '(PERFECT DISTANCE 🟢)';
  }

  bool _isHeadCentered(double yaw, double pitch) {
    return yaw.abs() < 15 && pitch.abs() < 15;
  }

  bool _isHumanFace(ml_kit.Face face) {
    // Validate that detected face has human characteristics
    final hasValidSize =
        face.boundingBox.width > 50 && face.boundingBox.height > 50;
    final hasEyeData =
        face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null;
    final hasValidRotation =
        face.headEulerAngleY != null && face.headEulerAngleX != null;

    return hasValidSize && hasEyeData && hasValidRotation;
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
    }
  }

  @override
  Future<void> dispose() async {
    await _detector.close();
  }
}
