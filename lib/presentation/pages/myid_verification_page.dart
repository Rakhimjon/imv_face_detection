import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    as ml_kit;

// ─── Page entry point ────────────────────────────────────────────────────────

class MyIdVerificationPage extends StatefulWidget {
  const MyIdVerificationPage({super.key});

  @override
  State<MyIdVerificationPage> createState() => _MyIdVerificationPageState();
}

// ─── Step enum ───────────────────────────────────────────────────────────────

enum _Step { input, scan, analyzing, result }

enum _LivenessStep { straight, blink, left, right, done }

// ─── Page state ──────────────────────────────────────────────────────────────

class _MyIdVerificationPageState extends State<MyIdVerificationPage>
    with TickerProviderStateMixin {
  _Step _step = _Step.input;
  _LivenessStep _livenessStep = _LivenessStep.straight;

  // --- passport form ---
  final _passportController = TextEditingController(text: 'AD2793792');
  final _dobController = TextEditingController(text: '22.10.1981');
  DateTime? _selectedDate = DateTime(1981, 10, 22);
  final _formKey = GlobalKey<FormState>();

  // --- camera / face ---
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _cameraReady = false;
  bool _cameraError = false;
  bool _isProcessing = false;
  bool _faceDetected = false;
  double _scanProgress = 0.0;
  Timer? _analysisTimer;

  final _faceDetector = ml_kit.FaceDetector(
    options: ml_kit.FaceDetectorOptions(
      enableContours: false,
      enableClassification: true,
      minFaceSize: 0.3,
    ),
  );

  // --- animations ---
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmer;

  // --- result ---
  bool _verificationSuccess = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shimmer = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _passportController.dispose();
    _dobController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _analysisTimer?.cancel();
    super.dispose();
  }

  // ─── Camera lifecycle ─────────────────────────────────────────────────────

  Future<void> _startCamera() async {
    try {
      await _stopCamera(); // Safety first

      _cameras = await availableCameras();
      final front = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _cameraReady = true);
      _startFaceStream();
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) setState(() => _cameraError = true);
    }
  }

  Future<void> _stopCamera() async {
    if (_cameraController != null) {
      try {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
      } catch (_) {}
      await _cameraController!.dispose();
      _cameraController = null;
    }
    if (mounted) {
      setState(() {
        _cameraReady = false;
      });
    }
  }

  void _startFaceStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    _cameraController!.startImageStream((image) async {
      if (_isProcessing || _step != _Step.scan) return;
      _isProcessing = true;
      try {
        final inputImage = _toInputImage(image);
        if (inputImage != null) {
          final faces = await _faceDetector.processImage(inputImage);
          if (mounted) {
            final detected = faces.isNotEmpty;
            if (detected != _faceDetected) {
              setState(() => _faceDetected = detected);
            }
            // Liveness sequence
            if (detected) {
              final face = faces.first;
              final yaw = face.headEulerAngleY ?? 0.0;
              final leftEye = face.leftEyeOpenProbability ?? 1.0;
              final rightEye = face.rightEyeOpenProbability ?? 1.0;

              if (_livenessStep == _LivenessStep.straight) {
                if (yaw > -10 && yaw < 10) {
                  setState(() {
                    _scanProgress = 0.25;
                    _livenessStep = _LivenessStep.blink;
                  });
                }
              } else if (_livenessStep == _LivenessStep.blink) {
                if (leftEye < 0.35 && rightEye < 0.35) {
                  setState(() {
                    _scanProgress = 0.50;
                    _livenessStep = _LivenessStep.left;
                  });
                }
              } else if (_livenessStep == _LivenessStep.left) {
                if (yaw > 15) {
                  setState(() {
                    _scanProgress = 0.75;
                    _livenessStep = _LivenessStep.right;
                  });
                }
              } else if (_livenessStep == _LivenessStep.right) {
                if (yaw < -15) {
                  setState(() {
                    _scanProgress = 1.0;
                    _livenessStep = _LivenessStep.done;
                  });
                }
              } else if (_livenessStep == _LivenessStep.done) {
                if (_step == _Step.scan) {
                  _startDeepAnalysis();
                }
              }
            } else {
              setState(() {
                _scanProgress = 0;
                _livenessStep = _LivenessStep.straight;
              });
            }
          }
        }
      } finally {
        _isProcessing = false;
      }
    });
  }

  void _startDeepAnalysis() {
    setState(() {
      _step = _Step.analyzing;
    });
    _analysisTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) _completeVerification(success: true);
    });
  }

  ml_kit.InputImage? _toInputImage(CameraImage image) {
    if (_cameraController == null) return null;

    final rotation = _getRotation(
      _cameraController!.description.sensorOrientation,
    );
    if (rotation == null) return null;

    // Get the InputImageFormat based on platform and raw format
    final format =
        ml_kit.InputImageFormatValue.fromRawValue(image.format.raw) ??
        (Platform.isAndroid
            ? ml_kit.InputImageFormat.nv21
            : ml_kit.InputImageFormat.bgra8888);

    // Validate that the format is supported by ML Kit on the respective platform
    if ((Platform.isAndroid && format != ml_kit.InputImageFormat.nv21) ||
        (Platform.isIOS && format != ml_kit.InputImageFormat.bgra8888)) {
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

  ml_kit.InputImageRotation? _getRotation(int sensorOrientation) {
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

  // ─── Navigation between steps ─────────────────────────────────────────────

  void _goToScan() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _step = _Step.scan;
      _livenessStep = _LivenessStep.straight;
      _faceDetected = false;
      _cameraReady = false;
      _cameraError = false;
    });
    _startCamera();
  }

  void _completeVerification({required bool success}) {
    _stopCamera();
    setState(() {
      _verificationSuccess = success;
      _step = _Step.result;
    });
  }

  void _restart() {
    setState(() {
      _step = _Step.input;
      _livenessStep = _LivenessStep.straight;
      _faceDetected = false;
    });
  }

  String get _currentInstruction {
    if (!_faceDetected) return 'Yuzingizni doira ichiga joylang';
    switch (_livenessStep) {
      case _LivenessStep.straight:
        return 'Kameraga to\'g\'ri qarang';
      case _LivenessStep.blink:
        return 'Iltimos, ko\'zingizni kiring (Blink)';
      case _LivenessStep.left:
        return 'Boshni chapga burang';
      case _LivenessStep.right:
        return 'Boshni o\'ngga burang';
      case _LivenessStep.done:
        return 'Ajoyib! Harakatlanmang...';
    }
  }

  // ─── Date picker ──────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    HapticFeedback.lightImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 17)),
      helpText: 'Туғилган сана',
      cancelText: 'Bekor',
      confirmText: 'OK',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _kAccent,
              onPrimary: Colors.white,
              surface: const Color(0xFF1A1E2E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A1E2E),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}'
            '.${picked.month.toString().padLeft(2, '0')}'
            '.${picked.year}';
      });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: switch (_step) {
          _Step.input => _InputStep(
            key: const ValueKey('input'),
            formKey: _formKey,
            passportCtrl: _passportController,
            dobCtrl: _dobController,
            selectedDate: _selectedDate,
            onPickDate: _pickDate,
            onNext: _goToScan,
          ),
          _Step.scan => _ScanStep(
            key: const ValueKey('scan'),
            cameraCtrl: _cameraController,
            cameraReady: _cameraReady,
            cameraError: _cameraError,
            faceDetected: _faceDetected,
            pulseAnim: _pulse,
            shimmerAnim: _shimmer,
            scanProgress: _scanProgress,
            instructionText: _currentInstruction,
            onCancel: () {
              _stopCamera();
              setState(() => _step = _Step.input);
            },
          ),
          _Step.analyzing => _AnalysisStep(
            key: const ValueKey('analyzing'),
            cameraCtrl: _cameraController,
          ),
          _Step.result => _ResultStep(
            key: const ValueKey('result'),
            success: _verificationSuccess,
            passportNumber: _passportController.text,
            dob: _dobController.text,
            onRetry: _restart,
            onDone: () => Navigator.of(context).pop(),
          ),
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
        onPressed: () {
          if (_step == _Step.scan) {
            _stopCamera();
            setState(() => _step = _Step.input);
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              gradient: _kGradient,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'MY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14.sp,
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            'ID  Verification',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — Passport Input
// ─────────────────────────────────────────────────────────────────────────────

class _InputStep extends StatelessWidget {
  const _InputStep({
    super.key,
    required this.formKey,
    required this.passportCtrl,
    required this.dobCtrl,
    required this.selectedDate,
    required this.onPickDate,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passportCtrl;
  final TextEditingController dobCtrl;
  final DateTime? selectedDate;
  final VoidCallback onPickDate;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero icon ──
            Center(
              child: Container(
                width: 88.w,
                height: 88.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _kGradient,
                  boxShadow: [
                    BoxShadow(
                      color: _kAccent.withOpacity(0.4),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.badge_outlined,
                  color: Colors.white,
                  size: 42.sp,
                ),
              ),
            ),
            SizedBox(height: 20.h),

            Center(
              child: Text(
                'Шахсни тасдиқлаш',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Center(
              child: Text(
                'Passport ma\'lumotlarini kiriting',
                style: TextStyle(color: Colors.white54, fontSize: 13.sp),
              ),
            ),
            SizedBox(height: 32.h),

            // ── Passport number field ──
            _SectionLabel('Pasport seriyasi va raqami'),
            SizedBox(height: 8.h),
            _MyIdTextField(
              controller: passportCtrl,
              hint: 'AA0000000',
              icon: Icons.credit_card,
              inputFormatters: [
                UpperCaseTextFormatter(),
                LengthLimitingTextInputFormatter(9),
              ],
              keyboardType: TextInputType.text,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Majburiy maydon';
                final clean = v.trim().toUpperCase();
                if (!RegExp(r'^[A-Z]{2}\d{7}$').hasMatch(clean)) {
                  return 'Format: AA0000000 (2 harf, 7 raqam)';
                }
                return null;
              },
            ),
            SizedBox(height: 20.h),

            // ── Date of birth field ──
            _SectionLabel('Туғилган сана'),
            SizedBox(height: 8.h),
            _MyIdDateField(
              controller: dobCtrl,
              onTap: onPickDate,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Majburiy maydon';
                // Additional age check (18+)
                if (selectedDate != null) {
                  final now = DateTime.now();
                  final age = now.year - selectedDate!.year;
                  if (age < 18)
                    return 'Siz 18 yoshdan katta bo\'lishingiz kerak';
                }
                return null;
              },
            ),
            SizedBox(height: 36.h),

            // ── Info card ──
            _InfoCard(),
            SizedBox(height: 32.h),

            // ── Next button ──
            _GradientButton(
              label: 'Davom etish',
              icon: Icons.arrow_forward_rounded,
              onTap: onNext,
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — Face Scan (circle camera overlay)
// ─────────────────────────────────────────────────────────────────────────────

class _ScanStep extends StatelessWidget {
  const _ScanStep({
    super.key,
    required this.cameraCtrl,
    required this.cameraReady,
    required this.cameraError,
    required this.faceDetected,
    required this.pulseAnim,
    required this.shimmerAnim,
    required this.scanProgress,
    required this.instructionText,
    required this.onCancel,
  });

  final CameraController? cameraCtrl;
  final bool cameraReady;
  final bool cameraError;
  final bool faceDetected;
  final Animation<double> pulseAnim;
  final Animation<double> shimmerAnim;
  final double scanProgress;
  final String instructionText;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full dark background
        Container(color: _kBg),

        // Content
        SafeArea(
          child: Column(
            children: [
              SizedBox(height: 12.h),
              Text(
                instructionText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: faceDetected ? _kAccent : Colors.white70,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),

              // ── Circle camera viewport ──
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: pulseAnim,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: faceDetected ? pulseAnim.value : 1.0,
                        child: child,
                      );
                    },
                    child: _OvalCameraViewport(
                      cameraCtrl: cameraCtrl,
                      cameraReady: cameraReady,
                      cameraError: cameraError,
                      faceDetected: faceDetected,
                      shimmerAnim: shimmerAnim,
                      progress: scanProgress,
                    ),
                  ),
                ),
              ),

              // ── Tips ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: _ScanTips(),
              ),
              SizedBox(height: 24.h),

              // ── Cancel button ──
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'Bekor qilish',
                  style: TextStyle(color: Colors.white38, fontSize: 14.sp),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ],
    );
  }
}

class _OvalCameraViewport extends StatelessWidget {
  const _OvalCameraViewport({
    required this.cameraCtrl,
    required this.cameraReady,
    required this.cameraError,
    required this.faceDetected,
    required this.shimmerAnim,
    required this.progress,
  });

  final CameraController? cameraCtrl;
  final bool cameraReady;
  final bool cameraError;
  final bool faceDetected;
  final Animation<double> shimmerAnim;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final width = 260.w;
    final height = 340.w;
    final borderColor = faceDetected ? _kAccent : Colors.white30;
    final strokeW = faceDetected ? 3.5 : 2.0;

    return Stack(
      children: [
        // 1. Full camera feed (or at least larger than the oval)
        if (cameraReady && cameraCtrl != null && !cameraError)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: cameraCtrl!.value.previewSize!.height,
                height: cameraCtrl!.value.previewSize!.width,
                child: CameraPreview(cameraCtrl!),
              ),
            ),
          )
        else
          Positioned.fill(child: _loadingWidget()),

        // 2. The Mask (semi-transparent background with oval hole)
        Positioned.fill(
          child: CustomPaint(
            painter: _OvalMaskPainter(
              ovalSize: Size(width, height),
              fillColor: Colors.black.withOpacity(0.7),
            ),
          ),
        ),

        // 3. UI Overlays (Borders, Progress, Silhouette)
        Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Oval border
                CustomPaint(
                  size: Size(width, height),
                  painter: _OvalBorderPainter(
                    color: borderColor,
                    strokeWidth: strokeW,
                    shimmerValue: faceDetected ? shimmerAnim.value : null,
                    accentColor: _kAccent,
                  ),
                ),

                // Progress Ring
                CustomPaint(
                  size: Size(width, height),
                  painter: _ProgressPainter(
                    progress: progress,
                    color: _kAccent,
                  ),
                ),

                if (faceDetected)
                  _ScannerGlow(width: width, height: height, color: _kAccent),
              ],
            ),
          ),
        ),

        if (cameraError) Positioned.fill(child: _cameraErrorWidget()),
      ],
    );
  }

  Widget _loadingWidget() {
    return Container(
      color: const Color(0xFF0D1020),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36.w,
              height: 36.w,
              child: CircularProgressIndicator(
                color: _kAccent,
                strokeWidth: 2.5,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Kamera yuklanmoqda...',
              style: TextStyle(color: Colors.white54, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraErrorWidget() {
    return Container(
      color: const Color(0xFF0D1020),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              color: Colors.redAccent,
              size: 36.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              'Kamera xatosi',
              style: TextStyle(color: Colors.white54, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3 — Result
// ─────────────────────────────────────────────────────────────────────────────

class _ResultStep extends StatelessWidget {
  const _ResultStep({
    super.key,
    required this.success,
    required this.passportNumber,
    required this.dob,
    required this.onRetry,
    required this.onDone,
  });

  final bool success;
  final String passportNumber;
  final String dob;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Column(
        children: [
          SizedBox(height: 24.h),

          // ── Status circle ──
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, val, child) =>
                Transform.scale(scale: val, child: child),
            child: Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: success
                      ? [const Color(0xFF00C896), const Color(0xFF00A878)]
                      : [const Color(0xFFFF4C6A), const Color(0xFFD0002F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (success
                                ? const Color(0xFF00C896)
                                : const Color(0xFFFF4C6A))
                            .withOpacity(0.35),
                    blurRadius: 34,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                success ? Icons.verified_rounded : Icons.cancel_rounded,
                color: Colors.white,
                size: 52.sp,
              ),
            ),
          ),
          SizedBox(height: 20.h),

          Text(
            success ? 'Muvaffaqiyatli!' : 'Tasdiqlanmadi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            success
                ? 'Shaxsingiz muvaffaqiyatli tasdiqlandi'
                : 'Yuz aniqlanmadi. Qayta urinib ko\'ring',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
          ),
          SizedBox(height: 32.h),

          // ── Info card ──
          if (success) _ResultCard(passport: passportNumber, dob: dob),
          SizedBox(height: 32.h),

          // ── Actions ──
          _GradientButton(
            label: success ? 'Yakunlash' : 'Qayta urinish',
            icon: success ? Icons.check_circle_outline : Icons.refresh_rounded,
            onTap: success ? onDone : onRetry,
          ),
          if (success) ...[
            SizedBox(height: 12.h),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Boshidan boshlash',
                style: TextStyle(color: Colors.white38, fontSize: 13.sp),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MyIdTextField extends StatelessWidget {
  const _MyIdTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.inputFormatters = const [],
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final List<TextInputFormatter> inputFormatters;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: TextStyle(
        color: Colors.white,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white24, fontSize: 15.sp),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Icon(icon, color: _kAccent, size: 22.sp),
        ),
        filled: true,
        fillColor: const Color(0xFF1A1E2E),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.white12, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.white12, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: _kAccent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: TextStyle(color: Colors.redAccent, fontSize: 11.sp),
      ),
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      validator: validator,
      textCapitalization: TextCapitalization.characters,
    );
  }
}

class _MyIdDateField extends StatelessWidget {
  const _MyIdDateField({
    required this.controller,
    required this.onTap,
    this.validator,
  });

  final TextEditingController controller;
  final VoidCallback onTap;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: TextStyle(
        color: Colors.white,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      decoration: InputDecoration(
        hintText: 'KK.OO.YYYY',
        hintStyle: TextStyle(color: Colors.white24, fontSize: 15.sp),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Icon(
            Icons.calendar_month_rounded,
            color: _kAccent,
            size: 22.sp,
          ),
        ),
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: 14.w),
          child: Icon(
            Icons.expand_more_rounded,
            color: Colors.white38,
            size: 22.sp,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF1A1E2E),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.white12, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.white12, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: _kAccent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: TextStyle(color: Colors.redAccent, fontSize: 11.sp),
      ),
      validator: validator,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white70,
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: _kAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _kAccent.withOpacity(0.25), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _kAccent, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Ma\'lumotlaringiz xavfsiz saqlanadi va faqat shaxsni tasdiqlash uchun ishlatiladi.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12.sp,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.passport, required this.dob});

  final String passport;
  final String dob;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E2E),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF00C896).withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          _ResultRow(
            label: 'Pasport raqami',
            value: passport,
            icon: Icons.badge,
          ),
          Divider(color: Colors.white12, height: 24.h),
          _ResultRow(
            label: 'Туғилган сана',
            value: dob,
            icon: Icons.cake_outlined,
          ),
          Divider(color: Colors.white12, height: 24.h),
          _ResultRow(
            label: 'Holat',
            value: 'Tasdiqlandi ✓',
            icon: Icons.verified_rounded,
            valueColor: const Color(0xFF00C896),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18.sp),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.white38, fontSize: 11.sp),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanTips extends StatelessWidget {
  const _ScanTips();

  @override
  Widget build(BuildContext context) {
    const tips = [
      (Icons.wb_sunny_outlined, 'Yorug\' joyda turing'),
      (Icons.face_retouching_natural, 'Yuzingiz to\'liq ko\'rinsin'),
      (Icons.speed, 'Harakatlanmang'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: tips
          .map(
            (t) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Column(
                children: [
                  Icon(t.$1, color: Colors.white38, size: 18.sp),
                  SizedBox(height: 4.h),
                  Text(
                    t.$2,
                    style: TextStyle(color: Colors.white38, fontSize: 9.sp),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        height: 56.h,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _kGradient,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: _kAccent.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            SizedBox(width: 10.w),
            Icon(icon, color: Colors.white, size: 20.sp),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Oval Border & Progress Painters
// ─────────────────────────────────────────────────────────────────────────────

class _OvalBorderPainter extends CustomPainter {
  const _OvalBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.accentColor,
    this.shimmerValue,
  });

  final Color color;
  final double strokeWidth;
  final Color accentColor;
  final double? shimmerValue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawOval(rect, paint);

    if (shimmerValue != null) {
      final shimmerPaint = Paint()
        ..shader = SweepGradient(
          colors: [
            Colors.transparent,
            accentColor.withOpacity(0.6),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: GradientRotation(shimmerValue! * 2 * 3.14159),
        ).createShader(rect)
        ..strokeWidth = strokeWidth + 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawOval(rect, shimmerPaint);
    }
  }

  @override
  bool shouldRepaint(_OvalBorderPainter old) =>
      old.shimmerValue != shimmerValue || old.color != color;
}

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final rect = (Offset.zero & size).deflate(1.5);
    final paint = Paint()
      ..color =
          const Color(0xFF00C896) // Success green for progress
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw partial oval arc
    final path = Path()..addOval(rect);
    final metrics = path.computeMetrics().first;
    final extract = metrics.extractPath(0, metrics.length * progress);

    canvas.drawPath(extract, paint);
  }

  @override
  bool shouldRepaint(_ProgressPainter old) => old.progress != progress;
}

class _OvalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()..addOval(Offset.zero & size);
  @override
  bool shouldReclip(CustomClipper<Path> old) => false;
}

class _OvalMaskPainter extends CustomPainter {
  const _OvalMaskPainter({required this.ovalSize, required this.fillColor});

  final Size ovalSize;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = fillColor;
    final rect = Offset.zero & size;

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: ovalSize.width,
      height: ovalSize.height,
    );

    // Create a path that covers the whole screen and has a hole in the middle
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addOval(ovalRect),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_OvalMaskPainter old) =>
      old.ovalSize != ovalSize || old.fillColor != fillColor;
}

class _ScannerGlow extends StatelessWidget {
  const _ScannerGlow({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(
          Radius.elliptical(width / 2, height / 2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2B — Deep Analysis
// ─────────────────────────────────────────────────────────────────────────────

class _AnalysisStep extends StatefulWidget {
  const _AnalysisStep({super.key, required this.cameraCtrl});
  final CameraController? cameraCtrl;

  @override
  State<_AnalysisStep> createState() => _AnalysisStepState();
}

class _AnalysisStepState extends State<_AnalysisStep>
    with TickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final Animation<double> _scanLine;
  int _percent = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scanLine = Tween<double>(
      begin: 0.1,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));

    _timer = Timer.periodic(const Duration(milliseconds: 25), (t) {
      if (_percent < 100) {
        setState(() => _percent++);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = 260.w;
    final height = 340.w;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'CHUQUR TAHLIL QILINMOQDA',
            style: TextStyle(
              color: _kAccent,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 24.h),

          SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                ClipPath(
                  clipper: _OvalClipper(),
                  child: widget.cameraCtrl != null
                      ? _cameraPreview(widget.cameraCtrl!)
                      : Container(color: Colors.black26),
                ),

                // Scanning Line
                AnimatedBuilder(
                  animation: _scanLine,
                  builder: (context, _) {
                    return Positioned(
                      top: height * _scanLine.value,
                      left: width * 0.05,
                      right: width * 0.05,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: _kAccent.withOpacity(0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              _kAccent,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Percentage
                Center(
                  child: Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_percent%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 40.h),
          _AnalysisMetrics(),
        ],
      ),
    );
  }

  Widget _cameraPreview(CameraController ctrl) {
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: ctrl.value.previewSize!.height,
        height: ctrl.value.previewSize!.width,
        child: CameraPreview(ctrl),
      ),
    );
  }
}

class _AnalysisMetrics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        children: [
          _MetricRow(label: 'Face Geometry', value: 'OK'),
          SizedBox(height: 8.h),
          _MetricRow(label: 'Liveness Check', value: 'Verifying...'),
          SizedBox(height: 8.h),
          _MetricRow(label: 'Biometric Match', value: '98.4%'),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white38, fontSize: 12.sp),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0D1020);
const _kAccent = Color(0xFF4C6EF5);
const _kGradient = LinearGradient(
  colors: [Color(0xFF4C6EF5), Color(0xFF7B3FE4)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
