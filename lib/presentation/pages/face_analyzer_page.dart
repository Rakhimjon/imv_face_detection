import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:face_imv/application/camera_state.dart';
import 'package:face_imv/application/face_detection_state.dart';
import 'package:face_imv/presentation/widgets/face_overlay_painter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    as ml_kit;
import 'package:face_imv/presentation/pages/myid_verification_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── Page ────────────────────────────────────────────────────────────────────

class FaceAnalyzerPage extends StatefulWidget {
  const FaceAnalyzerPage({super.key});

  @override
  State<FaceAnalyzerPage> createState() => _FaceAnalyzerPageState();
}

class _FaceAnalyzerPageState extends State<FaceAnalyzerPage> {
  bool _isProcessing = false;

  int _lastFrameTime = 0;

  // Image-stream logic lives here because it needs [_isProcessing] state
  // and access to the BLoC — kept lean, all UI delegated to child widgets.
  void _initStreaming(CameraController controller) {
    if (controller.value.isStreamingImages) return;
    controller.startImageStream((image) async {
      if (_isProcessing) return;

      // Throttle to max 15 FPS (approx 66ms between frames)
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

  ml_kit.InputImage? _prepareInputImage(
    CameraImage image,
    CameraController controller,
  ) {
    final rotation = _rotationFromSensor(
      controller.description.sensorOrientation,
    );
    if (rotation == null) return null;

    final format =
        ml_kit.InputImageFormatValue.fromRawValue(image.format.raw) ??
        (defaultTargetPlatform == TargetPlatform.android
            ? ml_kit.InputImageFormat.nv21
            : ml_kit.InputImageFormat.bgra8888);

    // Validate format for platform
    if ((defaultTargetPlatform == TargetPlatform.android &&
            format != ml_kit.InputImageFormat.nv21) ||
        (defaultTargetPlatform == TargetPlatform.iOS &&
            format != ml_kit.InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    final bytes = allBytes.done().buffer.asUint8List();

    return ml_kit.InputImage.fromBytes(
      bytes: bytes,
      metadata: ml_kit.InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
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
                // ② ML face-landmark overlay
                _FaceOverlayLayer(controller: state.controller!),
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

// ─── ① Camera preview ────────────────────────────────────────────────────────

/// Renders the full-screen camera feed and triggers image-stream processing.
///
/// Using a dedicated widget (not a helper method) means Flutter's element tree
/// can skip rebuilding this heavy layer when only the face-overlay data changes.
class _CameraPreviewLayer extends StatelessWidget {
  const _CameraPreviewLayer({required this.controller, required this.onStream});

  final CameraController controller;

  /// Called once per build so the parent state can start the image stream
  /// without this widget needing to hold any logic of its own.
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
              onStream(controller);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
  }
}

// ─── ② Face overlay ──────────────────────────────────────────────────────────

/// Listens to [FaceDetectionCubit] and paints face landmarks on top of the
/// camera feed.  Separated so it rebuilds independently from the header/footer.
class _FaceOverlayLayer extends StatelessWidget {
  const _FaceOverlayLayer({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FaceDetectionCubit, FaceDetectionState>(
      builder: (context, state) {
        return Positioned.fill(
          child: CustomPaint(
            painter: FaceOverlayPainter(
              faces: state.faces,
              imageSize: controller.value.previewSize!,
              rotation: controller.description.sensorOrientation,
            ),
          ),
        );
      },
    );
  }
}

// ─── ③ Header ────────────────────────────────────────────────────────────────

/// Top bar: "ANALYZING" badge on the left, camera-flip button on the right.
/// Has no rebuild dependency on face data — stays stable while overlays update.
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
                    // Restart camera when coming back
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
                onPressed: () => context.read<CameraCubit>().switchCamera(),
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

/// Bottom panel showing real-time face-pose metrics, eye tracking, and distance.
/// Subscribes to [FaceDetectionCubit] so only this panel rebuilds on new data.
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
          borderRadius: BorderRadius.circular(24.r),
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

            // 1. Eye Tracking
            final leftEye = face.leftEyeOpenProbability ?? 0.0;
            final rightEye = face.rightEyeOpenProbability ?? 0.0;
            final isBlinking = leftEye < 0.3 && rightEye < 0.3;
            final leftEyePct = '${(leftEye * 100).toStringAsFixed(0)}%';
            final rightEyePct = '${(rightEye * 100).toStringAsFixed(0)}%';

            // 2. Smile Detection
            final smile = face.smilingProbability ?? 0.0;
            final smileStr = smile > 0.7 ? "😊 Smiling" : "😐 Neutral";
            final smilePct = '${(smile * 100).toStringAsFixed(0)}%';

            // 3. Head Movement Y (Left/Right)
            final yaw = face.headEulerAngleY ?? 0.0;
            String directionY = "Facing CENTER ✅";
            if (yaw < -20) {
              directionY = "Turning LEFT ⬅️";
            } else if (yaw > 20) {
              directionY = "Turning RIGHT ➡️";
            }

            // 4. Head Movement X (Up/Down)
            final pitch = face.headEulerAngleX ?? 0.0;
            String directionX = "Looking CENTER";
            if (pitch < -15) {
              directionX = "Looking DOWN ⬇️";
            } else if (pitch > 15) {
              directionX = "Looking UP ⬆️";
            }

            // 5. Approach Detection
            final width = face.boundingBox.width;
            String distance = "🟢 PERFECT DISTANCE";
            if (width > 280) {
              distance = "🔴 TOO CLOSE — Move Back";
            } else if (width < 100) {
              distance = "🟡 TOO FAR — Move Closer";
            }

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
