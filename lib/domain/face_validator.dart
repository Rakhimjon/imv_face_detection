
import 'package:face_imv/domain/face_entity.dart';

class FaceValidationResult {
  final bool isValid;
  final List<String> warnings;
  final List<String> errors;
  final double confidenceScore;

  const FaceValidationResult({
    required this.isValid,
    this.warnings = const [],
    this.errors = const [],
    required this.confidenceScore,
  });

  @override
  String toString() {
    return '''
FaceValidationResult(
  isValid: $isValid,
  confidenceScore: ${(confidenceScore * 100).toStringAsFixed(1)}%,
  warnings: ${warnings.length},
  errors: ${errors.length}
)''';
  }
}

class FaceValidator {
  static const double _minFaceSize = 50;
  static const double _recommendedFaceSize = 80;
  static const double _maxFaceSize = 380;
  static const double _maxValidYaw = 35;
  static const double _warnYaw = 22;
  static const double _maxValidPitch = 30;
  static const double _warnRoll = 22;
  static const double _closedEyeThreshold = 0.2;

  static FaceValidationResult validateHumanFace(FaceEntity face) {
    final warnings = <String>[];
    final errors = <String>[];
    double confidenceScore = 100.0;

    final faceWidth = face.width;
    final faceHeight = face.height;

    if (faceWidth < _minFaceSize || faceHeight < _minFaceSize) {
      errors.add(
        'Face too small (${faceWidth.toInt()}x${faceHeight.toInt()}px) - Move closer',
      );
      confidenceScore -= 30;
    } else if (faceWidth < _recommendedFaceSize) {
      warnings.add('Face somewhat small - Recommended to move closer');
      confidenceScore -= 10;
    }

    if (faceWidth > _maxFaceSize || faceHeight > _maxFaceSize) {
      errors.add('Face too large - Move back from camera');
      confidenceScore -= 20;
    }

    final aspectRatio = faceWidth / faceHeight;
    if (aspectRatio < 0.6 || aspectRatio > 1.4) {
      warnings.add(
        'Unusual face aspect ratio: ${aspectRatio.toStringAsFixed(2)}',
      );
      confidenceScore -= 15;
    }

    final yaw = face.yaw;
    final pitch = face.pitch;
    final roll = face.roll;

    if (yaw.abs() > _maxValidYaw) {
      errors.add('Head turned too far (Yaw: ${yaw.toStringAsFixed(1)}°)');
      confidenceScore -= 25;
    } else if (yaw.abs() > _warnYaw) {
      warnings.add('Head slightly turned (Yaw: ${yaw.toStringAsFixed(1)}°)');
      confidenceScore -= 10;
    }

    if (pitch.abs() > _maxValidPitch) {
      errors.add(
        'Head tilted too much up/down (Pitch: ${pitch.toStringAsFixed(1)}°)',
      );
      confidenceScore -= 20;
    }

    if (roll.abs() > _warnRoll) {
      warnings.add('Head rolled (Roll: ${roll.toStringAsFixed(1)}°)');
      confidenceScore -= 10;
    }
    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;

    if (leftEye == null || rightEye == null) {
      // Downgrade to warning — poor lighting should not hard-block detection.
      warnings.add('Eye data unavailable — improve lighting');
      confidenceScore -= 15;
    } else {
      // Check if eyes are closed (not blinking intentionally)
      if (leftEye < _closedEyeThreshold && rightEye < _closedEyeThreshold) {
        warnings.add('Both eyes appear closed');
        confidenceScore -= 15;
      }

      // Check for asymmetric eye opening (could indicate spoofing)
      final eyeDifference = (leftEye - rightEye).abs();
      if (eyeDifference > 0.5) {
        warnings.add('Asymmetric eye opening detected');
        confidenceScore -= 10;
      }
    }

    // 5. Smile/Expression Check
    final smile = face.smilingProbability;
    if (smile != null && smile > 0.9) {
      warnings.add('Excessive smiling detected - Maintain neutral expression');
      confidenceScore -= 5;
    }

    // 6. Tracking ID Validation (for anti-spoofing)
    if (face.trackingId == null) {
      warnings.add('Face tracking ID not available');
    }

    // 7. Landmark Validation - Should have key facial landmarks
    if (face.landmarks.isEmpty) {
      errors.add('No facial landmarks detected - Face may be obscured');
      confidenceScore -= 30;
    } else {
      // Check for essential landmarks
      final hasLeftEye = face.hasLandmark(FaceLandmarkType.leftEye);
      final hasRightEye = face.hasLandmark(FaceLandmarkType.rightEye);
      final hasNose = face.hasLandmark(FaceLandmarkType.noseBase);
      final hasMouth = face.hasLandmark(FaceLandmarkType.bottomMouth);

      if (!hasLeftEye || !hasRightEye) {
        // Warn rather than error — face may still be usable.
        warnings.add('Eyes not fully detected — adjust lighting');
        confidenceScore -= 15;
      }

      if (!hasNose) {
        warnings.add('Nose landmark not detected');
        confidenceScore -= 10;
      }

      if (!hasMouth) {
        warnings.add('Mouth landmark not detected');
        confidenceScore -= 10;
      }
    }

    // 8. Position Validation - Face should be reasonably centered
    // Future enhancement: Add position validation based on camera resolution

    // Final confidence score adjustment
    confidenceScore = confidenceScore.clamp(0.0, 100.0);

    // Determine if valid based on confidence and errors
    final isValid = errors.isEmpty && confidenceScore >= 45.0;

    return FaceValidationResult(
      isValid: isValid,
      warnings: warnings,
      errors: errors,
      confidenceScore: confidenceScore / 100.0,
    );
  }

  /// Validates liveness based on head movement sequence
  static bool validateLivenessSequence({
    required FaceEntity currentFace,
    required FaceEntity? previousFace,
    required LivenessAction expectedAction,
  }) {
    if (previousFace == null) return false;

    final currentYaw = currentFace.yaw;
    final previousYaw = previousFace.yaw;
    final currentPitch = currentFace.pitch;
    final previousPitch = previousFace.pitch;

    switch (expectedAction) {
      case LivenessAction.turnLeft:
        return currentYaw < previousYaw && currentYaw < -15;
      case LivenessAction.turnRight:
        return currentYaw > previousYaw && currentYaw > 15;
      case LivenessAction.lookUp:
        return currentPitch > previousPitch && currentPitch > 15;
      case LivenessAction.lookDown:
        return currentPitch < previousPitch && currentPitch < -15;
      case LivenessAction.blink:
        final leftEye = currentFace.leftEyeOpenProbability ?? 1.0;
        final rightEye = currentFace.rightEyeOpenProbability ?? 1.0;
        return leftEye < 0.35 && rightEye < 0.35;
      case LivenessAction.smile:
        final smile = currentFace.smilingProbability ?? 0.0;
        return smile > 0.7;
      case LivenessAction.neutral:
        return currentYaw.abs() < 10 && currentPitch.abs() < 10;
    }
  }

  /// Checks if face distance is optimal
  static String getFaceDistanceQuality(double faceWidth) {
    if (faceWidth > 280) return 'TOO_CLOSE';
    if (faceWidth < 100) return 'TOO_FAR';
    if (faceWidth >= 180 && faceWidth <= 240) return 'OPTIMAL';
    return 'ACCEPTABLE';
  }

  /// Anti-spoofing check - detects unusual patterns
  static bool isSuspiciousPattern(FaceEntity face) {
    // Check for perfectly still face (could be a photo)
    final leftEye = face.leftEyeOpenProbability ?? 0.5;
    final rightEye = face.rightEyeOpenProbability ?? 0.5;

    // Perfectly symmetric values might indicate spoofing
    if ((leftEye - rightEye).abs() < 0.01 && leftEye == 1.0) {
      return true; // Suspicious: perfect symmetry
    }

    // Check for unnatural stillness
    final yaw = face.yaw;
    final pitch = face.pitch;
    final roll = face.roll;

    if (yaw == 0.0 && pitch == 0.0 && roll == 0.0) {
      return true; // Suspicious: perfect alignment
    }

    return false;
  }
}

enum LivenessAction {
  turnLeft,
  turnRight,
  lookUp,
  lookDown,
  blink,
  smile,
  neutral,
}
