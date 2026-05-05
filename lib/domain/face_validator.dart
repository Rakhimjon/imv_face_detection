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

    // 1. Size Validation (Relative to frame if possible, but keeping pixels for now with better thresholds)
    if (faceWidth < 60 || faceHeight < 60) {
      errors.add('Yuz juda uzoqda - yaqinroq keling');
      confidenceScore -= 30;
    } else if (faceWidth < 100) {
      warnings.add('Yuz biroz uzoqda');
      confidenceScore -= 10;
    }

    if (faceWidth > 450 || faceHeight > 450) {
      errors.add('Yuz juda yaqin - uzoqroq turing');
      confidenceScore -= 20;
    }

    // 2. Aspect Ratio (Typical human face is ~1.3-1.5 height/width, but we use width/height)
    final aspectRatio = faceWidth / faceHeight;
    if (aspectRatio < 0.5 || aspectRatio > 1.5) {
      warnings.add('Yuz formasi noodatiy');
      confidenceScore -= 15;
    }

    // 3. Orientation Validation
    final yaw = face.yaw;
    final pitch = face.pitch;
    final roll = face.roll;

    if (yaw.abs() > 40) {
      errors.add('Bosh juda ko\'p burilgan');
      confidenceScore -= 25;
    } else if (yaw.abs() > 25) {
      warnings.add('Bosh biroz burilgan');
      confidenceScore -= 10;
    }

    if (pitch.abs() > 35) {
      errors.add('Bosh juda ko\'p egilgan');
      confidenceScore -= 20;
    }

    if (roll.abs() > 25) {
      warnings.add('Bosh qiyshaygan');
      confidenceScore -= 10;
    }

    // 4. Eye Data Validation
    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;

    if (leftEye == null || rightEye == null) {
      warnings.add('Ko\'zlarni aniqlab bo\'lmadi');
      confidenceScore -= 15;
    } else {
      if (leftEye < 0.1 && rightEye < 0.1) {
        warnings.add('Ko\'zlar yumuq');
        confidenceScore -= 10;
      }
    }

    // 5. Anti-spoofing: Pattern Check
    if (isSuspiciousPattern(face)) {
      warnings.add('Shubhali holat aniqlandi');
      confidenceScore -= 20;
    }

    // 6. Landmark Validation
    if (face.landmarks.isEmpty) {
      errors.add('Yuz chizgilari aniqlanmadi');
      confidenceScore -= 30;
    } else {
      final hasLeftEye = face.hasLandmark(FaceLandmarkType.leftEye);
      final hasRightEye = face.hasLandmark(FaceLandmarkType.rightEye);
      final hasNose = face.hasLandmark(FaceLandmarkType.noseBase);
      final hasMouth = face.hasLandmark(FaceLandmarkType.bottomMouth);

      if (!hasLeftEye || !hasRightEye) {
        warnings.add('Ko\'zlar to\'liq ko\'rinmayapti');
        confidenceScore -= 15;
      }
      if (!hasNose) confidenceScore -= 5;
    }

    confidenceScore = confidenceScore.clamp(0.0, 100.0);
    final isValid = errors.isEmpty && confidenceScore >= 40.0;

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
    Map<String, dynamic>? state, // For complex state like blink
  }) {
    if (previousFace == null && expectedAction != LivenessAction.neutral) return false;

    final currentYaw = currentFace.yaw;
    final currentPitch = currentFace.pitch;
    
    switch (expectedAction) {
      case LivenessAction.turnLeft:
        return currentYaw < -18;
      case LivenessAction.turnRight:
        return currentYaw > 18;
      case LivenessAction.lookUp:
        return currentPitch > 18;
      case LivenessAction.lookDown:
        return currentPitch < -18;
      case LivenessAction.blink:
        // Blink logic is handled by the page for better state management across frames
        return false; 
      case LivenessAction.smile:
        return (currentFace.smilingProbability ?? 0.0) > 0.75;
      case LivenessAction.neutral:
        return currentYaw.abs() < 10 && currentPitch.abs() < 10;
    }
  }

  /// Checks if face distance is optimal
  static String getFaceDistanceQuality(double faceWidth) {
    if (faceWidth > 380) return 'TOO_CLOSE';
    if (faceWidth < 80) return 'TOO_FAR';
    if (faceWidth >= 150 && faceWidth <= 300) return 'OPTIMAL';
    return 'ACCEPTABLE';
  }

  /// Anti-spoofing check - detects unusual patterns
  static bool isSuspiciousPattern(FaceEntity face) {
    final leftEye = face.leftEyeOpenProbability ?? 0.5;
    final rightEye = face.rightEyeOpenProbability ?? 0.5;

    // Photos often have perfect 1.0/1.0 eye probabilities or identical values
    if (leftEye > 0.999 && rightEye > 0.999) return false; // Normal
    if ((leftEye - rightEye).abs() < 0.0001 && leftEye < 0.9) return true;

    return false;
  }

  /// Checks for consistency across frames to detect deepfake "glitches"
  static bool isConsistencySuspicious(FaceEntity current, FaceEntity? previous) {
    if (previous == null) return false;

    // Detect teleportation (face moving too fast between frames)
    final currentCenter = current.boundingBox.center;
    final previousCenter = previous.boundingBox.center;
    final distance = (currentCenter - previousCenter).distance;

    // High threshold: 60% of face width. Normal movement is slower.
    if (distance > current.boundingBox.width * 0.6) return true;

    // Detect rapid size changes
    final currentSize = current.boundingBox.width;
    final previousSize = previous.boundingBox.width;
    final sizeChange = (currentSize - previousSize).abs() / previousSize;

    if (sizeChange > 0.45) return true;

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
