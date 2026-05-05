import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:face_imv/domain/face_entity.dart';

class FaceOverlayPainter extends CustomPainter {
  final List<FaceEntity> faces;
  final Size imageSize;
  final int rotation;
  final bool isFrontCamera;
  final double ellipseWidthFactor;
  final double? ellipseHeightFactor;

  final BoxFit fit;
  final bool showLandmarks;

  FaceOverlayPainter({
    required this.faces,
    required this.imageSize,
    required this.rotation,
    this.isFrontCamera = true,
    this.ellipseWidthFactor = 0.75,
    this.ellipseHeightFactor,
    this.fit = BoxFit.cover,
    this.showLandmarks = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the reference ellipse (face guide) first (background layer)
    _drawFaceGuideEllipse(canvas, size);

    // 2. Draw detected faces overlay
    if (faces.isNotEmpty) {
      _drawDetectedFaces(canvas, size);
    }
  }

  // 🎯 FACE GUIDE ELLIPSE (The oval where user should put their face)
  void _drawFaceGuideEllipse(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Calculate ellipse size (typically 70-80% of screen width, aspect ratio 3:4 for face)
    final ellipseWidth = size.width * ellipseWidthFactor;
    final ellipseHeight = ellipseHeightFactor == null
        ? ellipseWidth * 1.25
        : size.height * ellipseHeightFactor!;

    final rect = Rect.fromCenter(
      center: center,
      width: ellipseWidth,
      height: ellipseHeight,
    );

    // Determine state color
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Check conditions
    if (faces.length > 1) {
      guidePaint.color = Colors.redAccent;
      guidePaint.strokeWidth = 4.0;

      // Draw red ellipse
      canvas.drawOval(rect, guidePaint);

      // Error text: "Faqat bitta yuzni ko'rsating" (Show only one face)
      textPainter.text = TextSpan(
        text: "❌ Faqat bitta yuzni ko'rsating",
        style: TextStyle(
          color: Colors.redAccent,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          // 🔧 FIXED: backgroundColor (was backgroundlor)
          backgroundColor: Colors.black54,
        ),
      );
    } else if (faces.isEmpty) {
      // ⚪ WAITING STATE (Gray dotted line)
      guidePaint.color = Colors.white54;
      guidePaint.strokeWidth = 2.0;
      // Draw dotted effect
      guidePaint.style = PaintingStyle.stroke;

      canvas.drawOval(rect, guidePaint);

      // Instruction text
      textPainter.text = TextSpan(
        text: "Yuzingizni oval ichiga joylashtiring",
        style: TextStyle(
          color: Colors.white70,
          fontSize: 16,
          backgroundColor: Colors.black45,
        ),
      );
    } else {
      // One face detected - check positioning
      final face = faces.first;
      final faceRect = _scaleRect(face.boundingBox, size);

      // Check if face is inside the ellipse guide
      final isCentered = _isFaceCenteredInEllipse(
        faceRect,
        center,
        ellipseWidth,
        ellipseHeight,
      );
      // 🔧 FIXED: face.boundingBox (was face.bougBox)
      final isTooSmall =
          face.boundingBox.width < imageSize.width * 0.15; // Too far
      final isTooBig =
          face.boundingBox.width > imageSize.width * 0.85; // Too close

      if (isTooSmall) {
        // 🟡 TOO FAR - "Come closer"
        guidePaint.color = Colors.amber;
        guidePaint.strokeWidth = 3.0;
        canvas.drawOval(rect, guidePaint);

        // Animated-like effect (pulsing suggestion)
        final pulsePaint = Paint()
          ..color = Colors.amber.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawOval(rect, pulsePaint);

        textPainter.text = TextSpan(
          text: "📱 Yuzingizni yaqinroq qiling",
          style: TextStyle(
            color: Colors.amber,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black54,
          ),
        );
      } else if (isTooBig) {
        // 🟠 TOO CLOSE - "Move back"
        guidePaint.color = Colors.orange;
        guidePaint.strokeWidth = 3.0;
        canvas.drawOval(rect, guidePaint);

        // 🔧 FIXED: text: (was xt:)
        textPainter.text = TextSpan(
          text: "↩️ Ozroq uzoqroq turing",
          style: TextStyle(
            color: Colors.orange,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black54,
          ),
        );
      } else if (isCentered) {
        // 🟢 PERFECT POSITION
        guidePaint.color = Colors.greenAccent;
        guidePaint.strokeWidth = 4.0;
        canvas.drawOval(rect, guidePaint);

        // Success text
        textPainter.text = TextSpan(
          text: "✅ Ajoyib! Turganingizda qoling",
          style: TextStyle(
            color: Colors.greenAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black54,
          ),
        );
      } else {
        // 🟡 NOT CENTERED
        guidePaint.color = Colors.yellow;
        guidePaint.strokeWidth = 2.5;
        canvas.drawOval(rect, guidePaint);

        // 🔧 FIXED: joylashtiring (was jlashtiring)
        textPainter.text = TextSpan(
          text: "🎯 Yuzingizni markazga joylashtiring",
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 16,
            backgroundColor: Colors.black54,
          ),
        );
      }
    }

    // Draw text at bottom of ellipse
    textPainter.layout();
    final textTop = math.min(
      center.dy + ellipseHeight / 2 + 20,
      size.height - textPainter.height - 8,
    );
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, textTop),
    );

    // Draw corner markers on ellipse (decorative)
    _drawCornerMarkers(canvas, rect, guidePaint.color);
  }

  // Check if face bounding box is centered in the ellipse
  bool _isFaceCenteredInEllipse(
    Rect faceRect,
    Offset center,
    double ellipseW,
    double ellipseH,
  ) {
    final faceCenter = faceRect.center;
    final distance = (faceCenter - center).distance;

    // Allow 20% tolerance from center
    final maxDistance = math.min(ellipseW, ellipseH) * 0.2;

    // Also check if face size matches ellipse reasonably (70-100% of ellipse)
    final faceRatio = faceRect.width / ellipseW;

    // 🔧 FIXED: distance (was ance)
    return distance < maxDistance && faceRatio > 0.6 && faceRatio < 1.1;
  }

  void _drawCornerMarkers(Canvas canvas, Rect rect, Color color) {
    final markerPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final cornerLength = 25.0;

    // Top-left
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + Offset(cornerLength, 0),
      markerPaint,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + Offset(0, cornerLength),
      markerPaint,
    );

    // Top-right
    canvas.drawLine(
      rect.topRight,
      rect.topRight + Offset(-cornerLength, 0),
      markerPaint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + Offset(0, cornerLength),
      markerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + Offset(cornerLength, 0),
      markerPaint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + Offset(0, -cornerLength),
      // 🔧 FIXED: markerPaint (was erPaint)
      markerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + Offset(-cornerLength, 0),
      markerPaint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + Offset(0, -cornerLength),
      markerPaint,
    );
  }

  // Draw the actual detected face boxes
  void _drawDetectedFaces(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final face in faces) {
      final rect = _scaleRect(face.boundingBox, size);

      // Color based on face quality
      if (faces.length > 1) {
        paint.color = Colors.red; // Multiple faces = red
      } else {
        paint.color = Colors.greenAccent; // Single good face = green
      }

      // canvas.drawRect(rect, paint); // Removed bounding box as requested

      // Draw landmarks with a subtle glow
      if (showLandmarks) {
        final dotPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;

        final glowPaint = Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

        for (final landmark in face.landmarks.values) {
          final offset = _scaleOffset(landmark, size);
          canvas.drawCircle(offset, 4, glowPaint);
          canvas.drawCircle(offset, 2, dotPaint);
        }
      }
    }
  }

  Rect _scaleRect(Rect rect, Size widgetSize) {
    // Calculate scale factors based on requested fit
    final double scaleX = widgetSize.width / imageSize.width;
    final double scaleY = widgetSize.height / imageSize.height;
    final scale = fit == BoxFit.cover 
        ? math.max(scaleX, scaleY) 
        : math.min(scaleX, scaleY);

    final offsetX = (widgetSize.width - imageSize.width * scale) / 2;
    final offsetY = (widgetSize.height - imageSize.height * scale) / 2;

    final left = rect.left * scale + offsetX;
    final top = rect.top * scale + offsetY;
    final right = rect.right * scale + offsetX;
    final bottom = rect.bottom * scale + offsetY;

    if (!isFrontCamera) {
      return Rect.fromLTRB(left, top, right, bottom);
    }

    // Mirror the overlay so it matches the front camera preview.
    return Rect.fromLTRB(
      widgetSize.width - right,
      top,
      widgetSize.width - left,
      bottom,
    );
  }

  Offset _scaleOffset(Offset offset, Size widgetSize) {
    final double scaleX = widgetSize.width / imageSize.width;
    final double scaleY = widgetSize.height / imageSize.height;
    final scale = fit == BoxFit.cover 
        ? math.max(scaleX, scaleY) 
        : math.min(scaleX, scaleY);

    final offsetX = (widgetSize.width - imageSize.width * scale) / 2;
    final offsetY = (widgetSize.height - imageSize.height * scale) / 2;
    final dx = offset.dx * scale + offsetX;
    final dy = offset.dy * scale + offsetY;

    if (!isFrontCamera) {
      return Offset(dx, dy);
    }

    return Offset(widgetSize.width - dx, dy);
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.rotation != rotation ||
        oldDelegate.isFrontCamera != isFrontCamera ||
        oldDelegate.ellipseWidthFactor != ellipseWidthFactor ||
        oldDelegate.ellipseHeightFactor != ellipseHeightFactor;
  }
}
