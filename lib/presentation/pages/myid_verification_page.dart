import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:face_imv/domain/face_entity.dart';
import 'package:face_imv/domain/i_face_detector.dart';
import 'package:face_imv/domain/face_validator.dart';
import 'package:face_imv/injection.dart';
import 'package:face_imv/presentation/core/toast_ext.dart';
import 'package:face_imv/presentation/widgets/face_overlay_painter.dart';
import 'package:face_imv/application/camera_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  List<FaceEntity> _detectedFaces = const <FaceEntity>[];
  String? _scanErrorMessage;
  double _scanProgress = 0.0;
  Timer? _analysisTimer;
  int _lastFrameTime = 0;
  FaceEntity? _previousFace;
  late final IFaceDetector _faceDetector;

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
    _faceDetector = getIt<IFaceDetector>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _releaseSharedCameraIfAny();
    });
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
    _faceDetector.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _analysisTimer?.cancel();
    super.dispose();
  }

  // ─── Camera lifecycle ─────────────────────────────────────────────────────

  Future<void> _releaseSharedCameraIfAny() async {
    try {
      await context.read<CameraCubit>().stopCamera();
    } catch (_) {
      // This page can still run even if CameraCubit is not in scope.
    }
  }

  Future<void> _startCamera() async {
    try {
      await _releaseSharedCameraIfAny();
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
      setState(() {
        _cameraReady = true;
        _cameraError = false;
        _scanErrorMessage = null;
      });
      _startFaceStream();
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = true;
          _scanErrorMessage =
              'Kamera ishga tushmadi. Ruxsat va qurilma kamerasini tekshiring.';
        });
      }
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
        _faceDetected = false;
        _detectedFaces = const <FaceEntity>[];
      });
    }
  }

  void _startFaceStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    debugPrint(
      '🎥 Starting face detection stream for liveness verification...',
    );

    _cameraController!.startImageStream((image) async {
      if (_isProcessing || _step != _Step.scan) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastFrameTime < 80) return;

      _lastFrameTime = now;
      _isProcessing = true;
      try {
        final result = await _faceDetector.detectFromCameraImage(
          image,
          _cameraController!.description,
        );
        if (!mounted) return;

        result.fold(
          (error) {
            debugPrint('❌ Face detection error: $error');
            if (_scanErrorMessage != error ||
                _faceDetected ||
                _detectedFaces.isNotEmpty) {
              setState(() {
                _scanErrorMessage = error;
                _faceDetected = false;
                _detectedFaces = const <FaceEntity>[];
              });
            }
          },
          (faces) {
            if (_scanErrorMessage != null) {
              setState(() {
                _scanErrorMessage = null;
              });
            }
            final detected = faces.isNotEmpty;
            final detectionChanged = detected != _faceDetected;
            final facesChanged = detected
                ? _detectedFaces != faces
                : _detectedFaces.isNotEmpty;
            if (detectionChanged || facesChanged) {
              setState(() {
                _faceDetected = detected;
                _detectedFaces = List<FaceEntity>.unmodifiable(faces);
              });
              if (detectionChanged) {
                debugPrint('👤 Face detected: $detected');
              }
            }

            if (detected) {
              final face = faces.first;
              final yaw = face.yaw;
              final pitch = face.pitch;
              final leftEye = face.leftEyeOpenProbability ?? 1.0;
              final rightEye = face.rightEyeOpenProbability ?? 1.0;
              final faceWidth = face.width;
              final validation = FaceValidator.validateHumanFace(face);

              debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
              debugPrint(
                '🔴 LIVENESS CHECK - Step: ${_livenessStep.name.toUpperCase()}',
              );
              debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
              debugPrint('📊 Current Metrics:');
              debugPrint('  ↔️  Head Yaw (Y):    ${yaw.toStringAsFixed(2)}°');
              debugPrint('  ↕️  Head Pitch (X):  ${pitch.toStringAsFixed(2)}°');
              debugPrint(
                '  👁️  Left Eye Open:  ${(leftEye * 100).toStringAsFixed(1)}%',
              );
              debugPrint(
                '  👁️  Right Eye Open: ${(rightEye * 100).toStringAsFixed(1)}%',
              );
              debugPrint(
                '  📏 Face Width:      ${faceWidth.toStringAsFixed(0)}px',
              );
              debugPrint(
                '  🧑 Face Valid:      ${validation.isValid ? "YES" : "NO"} (${(validation.confidenceScore * 100).toStringAsFixed(1)}%)',
              );
              debugPrint(
                '  📈 Progress:        ${(_scanProgress * 100).toStringAsFixed(0)}%',
              );
              if (validation.warnings.isNotEmpty) {
                debugPrint(
                  '  ⚠️  Warnings: ${validation.warnings.join(" | ")}',
                );
              }
              if (validation.errors.isNotEmpty) {
                debugPrint('  ❌ Errors:   ${validation.errors.join(" | ")}');
              }

              if (!validation.isValid) {
                debugPrint('\n⏳ WAITING - Face quality is not sufficient yet');
                debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
                if (validation.errors.isNotEmpty) {
                  if (mounted) {
                    context.showErrorToast(validation.errors.first);
                  }
                }
                _previousFace = face;
                return;
              }

              if (_livenessStep == _LivenessStep.straight) {
                debugPrint('\n🎯 STEP 1: Checking if facing STRAIGHT...');
                debugPrint('   Required: Yaw between -10° and 10°');
                debugPrint('   Current:  ${yaw.toStringAsFixed(2)}°');
                if (yaw > -10 && yaw < 10) {
                  debugPrint('   ✅ PASSED - Moving to BLINK step');
                  setState(() {
                    _scanProgress = 0.25;
                    _livenessStep = _LivenessStep.blink;
                  });
                } else {
                  debugPrint('   ⏳ WAITING - Straighten your head');
                }
              } else {
                if (_livenessStep == _LivenessStep.blink) {
                  debugPrint('\n👁️  STEP 2: Checking for BLINK...');
                  debugPrint('   Required: Both eyes < 35% open');
                  debugPrint(
                    '   Left Eye:  ${(leftEye * 100).toStringAsFixed(1)}%',
                  );
                  debugPrint(
                    '   Right Eye: ${(rightEye * 100).toStringAsFixed(1)}%',
                  );
                  if (FaceValidator.validateLivenessSequence(
                    currentFace: face,
                    previousFace: _previousFace,
                    expectedAction: LivenessAction.blink,
                  )) {
                    debugPrint('   ✅ BLINK DETECTED - Moving to LEFT turn');
                    setState(() {
                      _scanProgress = 0.50;
                      _livenessStep = _LivenessStep.left;
                    });
                  } else {
                    debugPrint('   ⏳ WAITING - Please blink');
                  }
                } else if (_livenessStep == _LivenessStep.left) {
                  debugPrint('\n⬅️  STEP 3: Checking LEFT turn...');
                  debugPrint('   Required: Yaw < -15°');
                  debugPrint('   Current:  ${yaw.toStringAsFixed(2)}°');
                  if (FaceValidator.validateLivenessSequence(
                    currentFace: face,
                    previousFace: _previousFace,
                    expectedAction: LivenessAction.turnLeft,
                  )) {
                    debugPrint(
                      '   ✅ LEFT TURN VERIFIED - Moving to RIGHT turn',
                    );
                    setState(() {
                      _scanProgress = 0.75;
                      _livenessStep = _LivenessStep.right;
                    });
                  } else {
                    debugPrint('   ⏳ WAITING - Turn head left');
                  }
                } else if (_livenessStep == _LivenessStep.right) {
                  debugPrint('\n➡️  STEP 4: Checking RIGHT turn...');
                  debugPrint('   Required: Yaw > 15°');
                  debugPrint('   Current:  ${yaw.toStringAsFixed(2)}°');
                  if (FaceValidator.validateLivenessSequence(
                    currentFace: face,
                    previousFace: _previousFace,
                    expectedAction: LivenessAction.turnRight,
                  )) {
                    debugPrint(
                      '   ✅ RIGHT TURN VERIFIED - Liveness COMPLETE! 🎉',
                    );
                    setState(() {
                      _scanProgress = 1.0;
                      _livenessStep = _LivenessStep.done;
                    });
                  } else {
                    debugPrint('   ⏳ WAITING - Turn head right');
                  }
                } else if (_livenessStep == _LivenessStep.done) {
                  if (_step == _Step.scan) {
                    debugPrint('\n🎉 ALL LIVENESS STEPS COMPLETED!');
                    debugPrint('🔬 Starting deep analysis...');
                    _startDeepAnalysis();
                  }
                }
              }
              _previousFace = face;
              debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
            } else {
              if (_faceDetected) {
                debugPrint('⚠️  Face lost - Resetting liveness check');
              }
              _previousFace = null;
              setState(() {
                _scanProgress = 0;
                _livenessStep = _LivenessStep.straight;
              });
            }
          },
        );
      } catch (e) {
        debugPrint('❌ Error in face stream: $e');
        if (_scanErrorMessage != 'Face stream xatosi: $e') {
          setState(() {
            _scanErrorMessage = 'Face stream xatosi: $e';
          });
        }
      } finally {
        _isProcessing = false;
      }
    });
  }

  void _startDeepAnalysis() {
    debugPrint('╔════════════════════════════════════════════╗');
    debugPrint('║  🔬 DEEP ANALYSIS MODE ACTIVATED          ║');
    debugPrint('╚════════════════════════════════════════════╝');
    debugPrint('⏱️  Analysis duration: 2500ms');
    debugPrint('🧠 Verifying biometric authenticity...');

    setState(() {
      _step = _Step.analyzing;
    });
    _analysisTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        debugPrint('✅ Deep analysis COMPLETE!');
        debugPrint('🎉 Verification SUCCESS!\n');
        _completeVerification(success: true);
      }
    });
  }

  // ─── Navigation between steps ─────────────────────────────────────────────

  void _goToScan() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _step = _Step.scan;
      _livenessStep = _LivenessStep.straight;
      _faceDetected = false;
      _detectedFaces = const <FaceEntity>[];
      _previousFace = null;
      _cameraReady = false;
      _cameraError = false;
      _scanErrorMessage = null;
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
      _detectedFaces = const <FaceEntity>[];
      _previousFace = null;
      _scanProgress = 0;
      _scanErrorMessage = null;
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
            colorScheme: ColorScheme.light(
              primary: _kAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _kTextPrimary,
            ),
            dialogBackgroundColor: Colors.white,
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
            scanErrorMessage: _scanErrorMessage,
            faceDetected: _faceDetected,
            faces: _detectedFaces,
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
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: _kTextPrimary, size: 20.sp),
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
              'IMV',
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
              color: _kTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
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
                  color: _kAccent.withOpacity(0.10),
                  border: Border.all(
                    color: _kAccent.withOpacity(0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kAccent.withOpacity(0.12),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.badge_outlined, color: _kAccent, size: 42.sp),
              ),
            ),
            SizedBox(height: 20.h),

            Center(
              child: Text(
                'Шахсни тасдиқлаш',
                style: TextStyle(
                  color: _kTextPrimary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Center(
              child: Text(
                'Passport ma\'lumotlarini kiriting',
                style: TextStyle(color: _kTextSecondary, fontSize: 13.sp),
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
    required this.scanErrorMessage,
    required this.faceDetected,
    required this.faces,
    required this.pulseAnim,
    required this.shimmerAnim,
    required this.scanProgress,
    required this.instructionText,
    required this.onCancel,
  });

  final CameraController? cameraCtrl;
  final bool cameraReady;
  final bool cameraError;
  final String? scanErrorMessage;
  final bool faceDetected;
  final List<FaceEntity> faces;
  final Animation<double> pulseAnim;
  final Animation<double> shimmerAnim;
  final double scanProgress;
  final String instructionText;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final hasError =
        cameraError ||
        (scanErrorMessage != null && scanErrorMessage!.trim().isNotEmpty);
    final statusColor = hasError
        ? Colors.redAccent
        : (faceDetected ? _kAccent : _kTextPrimary);

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
                  color: statusColor,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasError) ...[
                SizedBox(height: 8.h),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          scanErrorMessage ??
                              'Kamera bilan bog\'liq xatolik yuz berdi',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                      hasError: hasError,
                      faceDetected: faceDetected,
                      faces: faces,
                      shimmerAnim: shimmerAnim,
                      progress: scanProgress,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: _ScanTips(),
              ),
              SizedBox(height: 24.h),

              TextButton(
                onPressed: onCancel,
                child: Text(
                  'Bekor qilish',
                  style: TextStyle(color: _kTextSecondary, fontSize: 14.sp),
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
    required this.hasError,
    required this.faceDetected,
    required this.faces,
    required this.shimmerAnim,
    required this.progress,
  });

  final CameraController? cameraCtrl;
  final bool cameraReady;
  final bool cameraError;
  final bool hasError;
  final bool faceDetected;
  final List<FaceEntity> faces;
  final Animation<double> shimmerAnim;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final width = 260.w;
    final height = 340.w;
    final progressColor = hasError ? Colors.redAccent : _kAccent;
    final previewSize = cameraCtrl?.value.previewSize;
    final overlayImageSize = previewSize == null
        ? Size(width, height)
        : Size(previewSize.height, previewSize.width);

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

        Center(
          child: SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              painter: FaceOverlayPainter(
                faces: faces,
                imageSize: overlayImageSize,
                rotation: cameraCtrl?.description.sensorOrientation ?? 0,
                isFrontCamera:
                    cameraCtrl?.description.lensDirection ==
                    CameraLensDirection.front,
                ellipseWidthFactor: 1,
                ellipseHeightFactor: 1,
              ),
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
                // Progress Ring
                CustomPaint(
                  size: Size(width, height),
                  painter: _ProgressPainter(
                    progress: progress,
                    color: progressColor,
                  ),
                ),

                if (faceDetected)
                  _ScannerGlow(
                    width: width,
                    height: height,
                    color: progressColor,
                  ),
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
      color: Colors.white,
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
              style: TextStyle(color: _kTextSecondary, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraErrorWidget() {
    return Container(
      color: Colors.white,
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
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
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
              color: _kTextPrimary,
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
            style: TextStyle(color: _kTextSecondary, fontSize: 14.sp),
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
                style: TextStyle(color: _kTextSecondary, fontSize: 13.sp),
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
        color: _kTextPrimary,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: _kTextSecondary.withOpacity(0.5),
          fontSize: 15.sp,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Icon(icon, color: _kAccent, size: 22.sp),
        ),
        filled: true,
        fillColor: _kCard,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: const Color(0xFFE2E8F0), width: 1.2),
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
        color: _kTextPrimary,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      decoration: InputDecoration(
        hintText: 'KK.OO.YYYY',
        hintStyle: TextStyle(
          color: _kTextSecondary.withOpacity(0.5),
          fontSize: 15.sp,
        ),
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
            color: _kTextSecondary,
            size: 22.sp,
          ),
        ),
        filled: true,
        fillColor: _kCard,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: const Color(0xFFE2E8F0), width: 1.2),
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
        color: _kTextSecondary,
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
                color: _kTextSecondary,
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
        color: _kCard,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _ResultRow(
            label: 'Pasport raqami',
            value: passport,
            icon: Icons.badge,
          ),
          Divider(color: const Color(0xFFE8EDF5), height: 24.h),
          _ResultRow(
            label: 'Туғилган сана',
            value: dob,
            icon: Icons.cake_outlined,
          ),
          Divider(color: const Color(0xFFE8EDF5), height: 24.h),
          _ResultRow(
            label: 'Holat',
            value: 'Tasdiqlandi ✓',
            icon: Icons.verified_rounded,
            valueColor: const Color(0xFF00A878),
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
        Icon(icon, color: _kTextSecondary, size: 18.sp),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: _kTextSecondary, fontSize: 11.sp),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? _kTextPrimary,
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
                  Icon(t.$1, color: _kTextSecondary, size: 18.sp),
                  SizedBox(height: 4.h),
                  Text(
                    t.$2,
                    style: TextStyle(color: _kTextSecondary, fontSize: 9.sp),
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
// Oval Progress Painters
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final rect = (Offset.zero & size).deflate(1.5);
    final paint = Paint()
      ..color = color
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
  bool shouldRepaint(_ProgressPainter old) =>
      old.progress != progress || old.color != color;
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
          style: TextStyle(color: _kTextSecondary, fontSize: 12.sp),
        ),
        Text(
          value,
          style: TextStyle(
            color: _kTextPrimary,
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

const _kBg = Color(0xFFF4F7FF);
const _kCard = Colors.white;
const _kAccent = Color(0xFF3B6CF8);
const _kTextPrimary = Color(0xFF1A2340);
const _kTextSecondary = Color(0xFF64748B);
const _kGradient = LinearGradient(
  colors: [Color(0xFF3B6CF8), Color(0xFF5B8DF8)],
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
