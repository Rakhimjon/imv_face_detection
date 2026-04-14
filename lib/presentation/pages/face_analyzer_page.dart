import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:face_imv/application/camera_state.dart';
import 'package:face_imv/application/face_detection_state.dart';
import 'package:face_imv/presentation/widgets/face_overlay_painter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    as ml_kit;
import 'package:face_imv/presentation/pages/myid_verification_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class FaceAnalyzerPage extends StatefulWidget {
  const FaceAnalyzerPage({super.key});

  @override
  State<FaceAnalyzerPage> createState() => _FaceAnalyzerPageState();
}

class _FaceAnalyzerPageState extends State<FaceAnalyzerPage> {
  bool _isProcessing = false;
  int _lastFrameTime = 0;
  
  // Track camera direction for overlay mirroring
  bool _isFrontCamera = true;

  void _initStreaming(CameraController controller) {
    if (controller.value.isStreamingImages) return;
    
    // Update camera direction
    _isFrontCamera = controller.description.lensDirection == CameraLensDirection.front;
    
    controller.startImageStream((image) async {
      if (_isProcessing) return;

      // Throttle to ~15 FPS (66ms), but skip if still processing
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastFrameTime < 66) return;
      _lastFrameTime = now;

      _isProcessing = true;
      try {
        final inputImage = _prepareInputImage(image, controller);
        if (inputImage != null) {
          await context.read<FaceDetectionCubit>().processImage(inputImage);
        }
      } catch (e) {
        debugPrint('Error processing image stream: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  // 🔧 FIXED: Proper YUV handling for Android vs iOS
  ml_kit.InputImage? _prepareInputImage(
    CameraImage image,
    CameraController controller,
  ) {
    try {
      final rotation = _rotationFromSensor(
        controller.description.sensorOrientation,
      );
      if (rotation == null) return null;

      // Platform-specific format handling
      if (Platform.isAndroid) {
        // Android: Convert YUV420_888 to NV21 properly
        final bytes = _convertYUV420ToNV21(image);
        if (bytes == null) return null;

        return ml_kit.InputImage.fromBytes(
          bytes: bytes,
          metadata: ml_kit.InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: ml_kit.InputImageFormat.nv21,
            bytesPerRow: image.width,
          ),
        );
      } else if (Platform.isIOS) {
        // iOS: BGRA is already contiguous
        if (image.planes.isEmpty) return null;
        
        return ml_kit.InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: ml_kit.InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: ml_kit.InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Image preparation error: $e');
      return null;
    }
  }

  // 🔧 CRITICAL: Correct YUV420 to NV21 conversion
  Uint8List? _convertYUV420ToNV21(CameraImage image) {
    try {
      final width = image.width;
      final height = image.height;
      final ySize = width * height;
      
      final uvWidth = width ~/ 2;
      final uvHeight = height ~/ 2;
      final uvSize = uvWidth * uvHeight;
      
      final nv21 = Uint8List(ySize + uvSize * 2);
      
      // Copy Y plane
      final yPlane = image.planes[0];
      final yBytes = yPlane.bytes;
      for (int i = 0; i < ySize; i++) {
        nv21[i] = yBytes[i];
      }
      
      // Interleave U and V planes
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      
      int uvIndex = ySize;
      for (int row = 0; row < uvHeight; row++) {
        for (int col = 0; col < uvWidth; col++) {
          final uIndex = row * uPlane.bytesPerRow + col * uPlane.bytesPerPixel!;
          final vIndex = row * vPlane.bytesPerRow + col * vPlane.bytesPerPixel!;
          
          if (uIndex < uPlane.bytes.length && vIndex < vPlane.bytes.length) {
            nv21[uvIndex++] = vPlane.bytes[vIndex]; // V first
            nv21[uvIndex++] = uPlane.bytes[uIndex]; // Then U
          }
        }
      }
      
      return nv21;
    } catch (e) {
      debugPrint('YUV conversion error: $e');
      return null;
    }
  }

  ml_kit.InputImageRotation? _rotationFromSensor(int sensorOrientation) {
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
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<CameraCubit, CameraState>(
        builder: (context, state) {
          if (state.status.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status.isFail) {
            return Center(child: Text(state.status.error));
          }
          if (state.controller != null &&
              state.controller!.value.isInitialized) {
            return Stack(
              children: [
                // ① Full-screen camera feed
                _CameraPreviewLayer(
                  controller: state.controller!,
                  onStream: _initStreaming,
                ),
                // ② ML face-landmark overlay (FIXED: Pass front camera flag)
                _FaceOverlayLayer(
                  controller: state.controller!,
                  isFrontCamera: _isFrontCamera,
                ),
                // ③ Status badge + camera-switch button
                const _AnalyzerHeader(),
                // ④ Face metrics panel
                const _AnalyzerFooter(),
              ],
            );
          }
          return const Center(child: Text('Initializing Camera...'));
        },
      ),
    );
  }
}

// ─── ① Camera preview ───────────────────────────────────────────────────────

class _CameraPreviewLayer extends StatelessWidget {
  const _CameraPreviewLayer({required this.controller, required this.onStream});

  final CameraController controller;
  final void Function(CameraController) onStream;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(
          controller,
          child: LayoutBuilder(
            builder: (context, _) {
              // Defer stream initialization to avoid build-phase side effects
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onStream(controller);
              });
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
  }
}

// ─── ② Face overlay ─────────────────────────────────────────────────────────

class _FaceOverlayLayer extends StatelessWidget {
  const _FaceOverlayLayer({
    required this.controller,
    required this.isFrontCamera,
  });

  final CameraController controller;
  final bool isFrontCamera;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FaceDetectionCubit, FaceDetectionState>(
      builder: (context, state) {
        // Don't rebuild if no faces (performance)
        if (state.faces.isEmpty) return const SizedBox.shrink();
        
        return Positioned.fill(
          child: CustomPaint(
            painter: FaceOverlayPainter(
              faces: state.faces,
              imageSize: controller.value.previewSize!,
              rotation: controller.description.sensorOrientation,
              isFrontCamera: isFrontCamera, // 🔧 FIXED: Pass this for mirroring
            ),
          ),
        );
      },
    );
  }
}

// ─── ③ Header ────────────────────────────────────────────────────────────────

class _AnalyzerHeader extends StatelessWidget {
  const _AnalyzerHeader();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50.h,
      left: 20.w,
      right: 20.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Status badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(Icons.face, color: Colors.indigoAccent),
                SizedBox(width: 8.w),
                Text(
                  'ANALYZING',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          // Camera-flip button
          Row(
            children: [
              TextButton.icon(
                onPressed: () async {
                  final cameraCubit = context.read<CameraCubit>();
                  await cameraCubit.stopCamera();
                  if (context.mounted) {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MyIdVerificationPage(),
                      ),
                    );
                    await cameraCubit.initialize();
                  }
                },
                icon: const Icon(
                  Icons.verified_user,
                  color: Colors.indigoAccent,
                  size: 18,
                ),
                label: const Text(
                  'VERIFY ID',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: const BorderSide(color: Colors.white12),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: () => context.read<CameraCubit>().switchCamera(), // 🔧 FIXED: cext -> context
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── ④ Footer ────────────────────────────────────────────────────────────────

class _AnalyzerFooter extends StatelessWidget {
  const _AnalyzerFooter();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40.h,
      left: 20.w,
      right: 20.w,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(24.r), // 🔧 FIXED: borderRius
          border: Border.all(color: Colors.white12),
        ),
        child: BlocBuilder<FaceDetectionCubit, FaceDetectionState>(
          builder: (context, state) {
            if (state.faces.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'Scanning for faces...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              );
            }

            final face = state.faces.first;
            final leftEye = face.leftEyeOpenProbability ?? 0.0;
            final rightEye = face.rightEyeOpenProbability ?? 0.0;
            final isBlinking = leftEye < 0.3 && rightEye < 0.3;
            final leftEyePct = '${(leftEye * 100).toStringAsFixed(0)}%';
            final rightEyePct = '${(rightEye * 100).toStringAsFixed(0)}%';
            final smile = face.smilingProbability ?? 0.0;
            final smileStr = smile > 0.7 ? "😊 Smiling" : "😐 Neutral";
            final smilePct = '${(smile * 100).toStringAsFixed(0)}%';
            final yaw = face.headEulerAngleY ?? 0.0;
            String directionY = "Facing CENTER ✅";
            if (yaw < -20) directionY = "Turning LEFT ⬅️";
            else if (yaw > 20) directionY = "Turning RIGHT ➡️";
            
            final pitch = face.headEulerAngleX ?? 0.0;
            String directionX = "Looking CENTER";
            if (pitch < -15) directionX = "Looking DOWN ⬇️";
            else if (pitch > 15) directionX = "Looking UP ⬆️";

            final width = face.boundingBox.width;
            String distance = "🟢 PERFECT DISTANCE";
            if (width > 280) distance = "🔴 TOO CLOSE — Move Back"; // 🔧 FIXED: wid280 -> width > 280
            else if (width < 100) distance = "🟡 TOO FAR — Move Closer";

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.faces.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Faces detected: ${state.faces.length}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (isBlinking)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: const Text(
                      '👁️ BLINK DETECTED 👁️',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                _buildStatRow('👁 Left Eye:', leftEyePct),
                _buildStatRow('👁 Right Eye:', rightEyePct),
                _buildStatRow('😊 Smile:', '$smileStr ($smilePct)'),
                _buildStatRow('↔️ Head Y:', directionY),
                _buildStatRow('↕️ Head X:', directionX),
                _buildStatRow('📏 Distance:', distance),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}