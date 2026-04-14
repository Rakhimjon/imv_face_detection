import 'dart:io';
import 'package:camera/camera.dart';
import 'package:face_imv/domain/face_entity.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart' as ml_kit;

abstract class IFaceDetector {
  Future<Either<String, List<FaceEntity>>> detectFromImage(File imageFile);
  Future<Either<String, List<FaceEntity>>> detectFromInputImage(ml_kit.InputImage inputImage);
  Future<Either<String, List<FaceEntity>>> detectFromCameraImage(
    CameraImage cameraImage, 
    CameraDescription camera,
  );
  Future<void> dispose();
}