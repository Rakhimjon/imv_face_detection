import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:face_imv/domain/face_entity.dart';
import 'package:face_imv/domain/i_face_detector.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    as ml_kit;

class MLKitFaceDetector implements IFaceDetector {
  final ml_kit.FaceDetector _detector;
  bool _isProcessing = false;

  MLKitFaceDetector({ml_kit.FaceDetectorOptions? options})
    : _detector = ml_kit.FaceDetector(
        options:
            options ??
            ml_kit.FaceDetectorOptions(
              enableLandmarks: true,
              enableClassification: true,
              enableTracking: true,
              enableContours: true,
              minFaceSize: 0.08,
              performanceMode: ml_kit.FaceDetectorMode.accurate,
            ),
      );

  @override
  Future<Either<String, List<FaceEntity>>> detectFromCameraImage(
    CameraImage cameraImage,
    CameraDescription camera,
  ) async {
    if (_isProcessing) return const Right([]);
    _isProcessing = true;

    try {
      final inputImage = await _convertCameraImage(cameraImage, camera);
      if (inputImage == null) {
        return const Left('Failed to convert camera image');
      }

      final result = await detectFromInputImage(inputImage);
      return result;
    } catch (e) {
      return Left('Camera processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<ml_kit.InputImage?> _convertCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) async {
    try {
      final rotation = _getImageRotation(camera.sensorOrientation);

      if (Platform.isAndroid) {
        final bytes = _androidImageToNv21Bytes(image);
        if (bytes == null) {
      
          return null;
        }

        final metadata = ml_kit.InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: ml_kit.InputImageFormat.nv21,
          bytesPerRow: image.width,
        );

        return ml_kit.InputImage.fromBytes(bytes: bytes, metadata: metadata);
      } else if (Platform.isIOS) {
        final bytes = image.planes[0].bytes;

        final metadata = ml_kit.InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: ml_kit.InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        );

        return ml_kit.InputImage.fromBytes(bytes: bytes, metadata: metadata);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Uint8List? _androidImageToNv21Bytes(CameraImage image) {
    if (image.planes.isEmpty) return null;

    // Many Android devices return NV21 in a single plane when requested.
    if (image.planes.length == 1) {
      return image.planes.first.bytes;
    }

    if (image.planes.length >= 3) {
      return _convertYUV420ToNV21(image);
    }

    return null;
  }

  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;

    // 🔧 FIXED: yPlane = (was yPimage.planes[0])
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final nv21 = Uint8List(width * height + (width * height ~/ 2));

    // Copy Y plane
    final yBytes = yPlane.bytes;
    for (int i = 0; i < width * height; i++) {
      nv21[i] = yBytes[i];
    }

    // Interleave U and V
    int uvIndex = width * height;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;

    for (int row = 0; row < uvHeight; row++) {
      for (int col = 0; col < uvWidth; col++) {
        final uvPixelStride = uPlane.bytesPerPixel ?? 1;
        final uvIndexSrc = row * uPlane.bytesPerRow + col * uvPixelStride;
        if (uvIndexSrc < uBytes.length && uvIndexSrc < vBytes.length) {
          nv21[uvIndex++] = vBytes[uvIndexSrc];
          nv21[uvIndex++] = uBytes[uvIndexSrc];
        }
      }
    }

    return nv21;
  }

  // 🔧 FIXED: return ml_kit.InputImageRotation (was ret.InputImageRotation)
  ml_kit.InputImageRotation _getImageRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:
        return ml_kit.InputImageRotation.rotation0deg;
      case 90:
        return ml_kit.InputImageRotation.rotation90deg;
      case 180:
        return ml_kit.InputImageRotation.rotation180deg;
      case 270:
        return ml_kit.InputImageRotation.rotation270deg;
      default:
        return ml_kit.InputImageRotation.rotation0deg;
    }
  }

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

      // Quality filter
      final validFaces = faces
          .where((face) => _isHighQualityFace(face))
          .toList();

      final entities = validFaces.map(_mapToEntity).toList();
      return Right(entities);
    } catch (e) {
      //showError('ML Kit Detection Error: $e');
      return Left('ML Kit Detection Error: $e');
    }
  }

  bool _isHighQualityFace(ml_kit.Face face) {
    final width = face.boundingBox.width;
    final height = face.boundingBox.height;
    if (width < 40 || height < 40) return false;
    final yaw = face.headEulerAngleY?.abs() ?? 0;
    final pitch = face.headEulerAngleX?.abs() ?? 0;
    if (yaw > 70 || pitch > 60) return false;

    return true;
  }

  FaceEntity _mapToEntity(ml_kit.Face face) {
    final landmarks = <FaceLandmarkType, Offset>{};

    for (final landmark in face.landmarks.values) {
      if (landmark != null) {
        final type = _mapLandmarkType(landmark.type);
        if (type != null) {
          landmarks[type] = Offset(
            landmark.position.x.toDouble(),
            // 🔧 FIXED: landmark.position.y (was landmark.ition.y)
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
      case ml_kit.FaceContourType.rightEyebrowBottom: // Fixed: Bttom -> Bottom
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
