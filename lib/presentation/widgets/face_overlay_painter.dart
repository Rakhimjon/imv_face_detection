import 'package:flutter/material.dart';
import 'package:face_imv/domain/face_entity.dart';

class FaceOverlayPainter extends CustomPainter {
  final List<FaceEntity> faces;
  final Size imageSize;
  final int rotation;

  FaceOverlayPainter({
    required this.faces,
    required this.imageSize,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.indigoAccent;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.pinkAccent;

    for (final face in faces) {
      // Scale bounding box from image size to widget size
      final rect = _scaleRect(
        rect: face.boundingBox,
        imageSize: imageSize,
        widgetSize: size,
      );

      // Check for blinking
      final leftEye = face.leftEyeOpenProbability ?? 1.0;
      final rightEye = face.rightEyeOpenProbability ?? 1.0;
      final isBlinking = leftEye < 0.3 && rightEye < 0.3;
      
      // Highlight when both eyes are closed below 0.3 threshold (based on specs)
      paint.color = isBlinking ? Colors.redAccent : Colors.green[400]!;

      // Draw bounding box with rounded corners
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        paint,
      );
      
      // Draw contour lines
      final contourPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white54;
      
      for (final contour in face.contours.values) {
        if (contour.isEmpty) continue;
        final path = Path();
        final firstPoint = _scaleOffset(
          offset: contour.first,
          imageSize: imageSize,
          widgetSize: size,
        );
        path.moveTo(firstPoint.dx, firstPoint.dy);
        for (int i = 1; i < contour.length; i++) {
          final point = _scaleOffset(
            offset: contour[i],
            imageSize: imageSize,
            widgetSize: size,
          );
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, contourPaint);
      }

      // Draw landmarks
      for (final landmark in face.landmarks.values) {
        final offset = _scaleOffset(
          offset: landmark,
          imageSize: imageSize,
          widgetSize: size,
        );
        canvas.drawCircle(offset, 3, dotPaint);
      }
    }
  }

  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size widgetSize,
  }) {
    // Note: This logic assumes portrait mode and might need adjustments 
    // for complex rotation/mirroring scenarios (e.g. front camera flip).
    final double scaleX = widgetSize.width / imageSize.height;
    final double scaleY = widgetSize.height / imageSize.width;

    return Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
  }

  Offset _scaleOffset({
    required Offset offset,
    required Size imageSize,
    required Size widgetSize,
  }) {
    final double scaleX = widgetSize.width / imageSize.height;
    final double scaleY = widgetSize.height / imageSize.width;

    return Offset(offset.dx * scaleX, offset.dy * scaleY);
  }

  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) {
    return oldDelegate.faces != faces || oldDelegate.imageSize != imageSize;
  }
}
