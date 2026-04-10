import 'dart:io';
import 'package:face_imv/domain/face_entity.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart' as ml_kit;

abstract class IFaceDetector {
  /// Analyzes a single image file for faces.
  Future<Either<String, List<FaceEntity>>> detectFromImage(File imagePath);

  /// Analyzes a stream of camera frames.
  Future<Either<String, List<FaceEntity>>> detectFromInputImage(ml_kit.InputImage inputImage);

  /// Cleans up resources.
  Future<void> dispose();
}
