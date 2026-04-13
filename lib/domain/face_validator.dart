/// Face Validation Utility
///
/// Provides comprehensive validation logic to ensure detected faces
/// are real human faces and meet quality standards for biometric verification.

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    as ml_kit;

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
  /// Validates if the detected face is a real human face with good quality
  static FaceValidationResult validateHumanFace(ml_kit.Face face) {
    final warnings = <String>[];
    final errors = <String>[];
    double confidenceScore = 100.0;

    // 1. Size Validation - Face must be large enough
    final faceWidth = face.boundingBox.width;
    final faceHeight = face.boundingBox.height;

    if (faceWidth < 80 || faceHeight < 80) {
      errors.add(
        'Face too small (${faceWidth.toInt()}x${faceHeight.toInt()}px) - Move closer',
      );
      confidenceScore -= 30;
    } else if (faceWidth < 120) {
      warnings.add('Face somewhat small - Recommended to move closer');
      confidenceScore -= 10;
    }

    if (faceWidth > 350 || faceHeight > 350) {
      errors.add('Face too large - Move back from camera');
      confidenceScore -= 20;
    }

    // 2. Aspect Ratio - Face should have natural proportions
    final aspectRatio = faceWidth / faceHeight;
    if (aspectRatio < 0.6 || aspectRatio > 1.4) {
      warnings.add(
        'Unusual face aspect ratio: ${aspectRatio.toStringAsFixed(2)}',
      );
      confidenceScore -= 15;
    }

    // 3. Head Orientation - Face should be relatively straight
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;

    if (yaw.abs() > 30) {
      errors.add('Head turned too far (Yaw: ${yaw.toStringAsFixed(1)}°)');
      confidenceScore -= 25;
    } else if (yaw.abs() > 20) {
      warnings.add('Head slightly turned (Yaw: ${yaw.toStringAsFixed(1)}°)');
      confidenceScore -= 10;
    }

    if (pitch.abs() > 25) {
      errors.add(
        'Head tilted too much up/down (Pitch: ${pitch.toStringAsFixed(1)}°)',
      );
      confidenceScore -= 20;
    }

    if (roll.abs() > 20) {
      warnings.add('Head rolled (Roll: ${roll.toStringAsFixed(1)}°)');
      confidenceScore -= 10;
    }

    // 4. Eye Detection - Both eyes should be detected and open
    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;

    if (leftEye == null || rightEye == null) {
      errors.add('Eye data not available - Poor lighting or face obscured');
      confidenceScore -= 40;
    } else {
      // Check if eyes are closed (not blinking intentionally)
      if (leftEye < 0.2 && rightEye < 0.2) {
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
      final hasLeftEye = face.landmarks.containsKey(
        ml_kit.FaceLandmarkType.leftEye,
      );
      final hasRightEye = face.landmarks.containsKey(
        ml_kit.FaceLandmarkType.rightEye,
      );
      final hasNose = face.landmarks.containsKey(
        ml_kit.FaceLandmarkType.noseBase,
      );
      final hasMouth = face.landmarks.containsKey(
        ml_kit.FaceLandmarkType.bottomMouth,
      );

      if (!hasLeftEye || !hasRightEye) {
        errors.add('Eyes not properly detected');
        confidenceScore -= 35;
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
    final isValid = errors.isEmpty && confidenceScore >= 60.0;

    return FaceValidationResult(
      isValid: isValid,
      warnings: warnings,
      errors: errors,
      confidenceScore: confidenceScore / 100.0,
    );
  }

  /// Validates liveness based on head movement sequence
  static bool validateLivenessSequence({
    required ml_kit.Face currentFace,
    required ml_kit.Face? previousFace,
    required LivenessAction expectedAction,
  }) {
    if (previousFace == null) return false;

    final currentYaw = currentFace.headEulerAngleY ?? 0.0;
    final previousYaw = previousFace.headEulerAngleY ?? 0.0;
    final currentPitch = currentFace.headEulerAngleX ?? 0.0;
    final previousPitch = previousFace.headEulerAngleX ?? 0.0;

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
  static bool isSuspiciousPattern(ml_kit.Face face) {
    // Check for perfectly still face (could be a photo)
    final leftEye = face.leftEyeOpenProbability ?? 0.5;
    final rightEye = face.rightEyeOpenProbability ?? 0.5;

    // Perfectly symmetric values might indicate spoofing
    if ((leftEye - rightEye).abs() < 0.01 && leftEye == 1.0) {
      return true; // Suspicious: perfect symmetry
    }

    // Check for unnatural stillness
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;

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
