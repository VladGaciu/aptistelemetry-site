import 'package:flutter/material.dart';

class ReticlePainter extends CustomPainter {
  final Offset? centroid;
  final Offset referencePoint;

  ReticlePainter({this.centroid, required this.referencePoint});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint refPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    final Paint beamPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint linePaint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 1. Draw static reference point (Blue dot)
    canvas.drawCircle(referencePoint, 6.0, refPaint);
    canvas.drawCircle(referencePoint, 12.0, beamPaint);

    // 2. Draw live beam centroid if detected
    if (centroid != null) {
      canvas.drawCircle(centroid!, 8.0, beamPaint);
      
      // Draw error vector line connecting reference to live centroid
      canvas.drawLine(referencePoint, centroid!, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ReticlePainter oldDelegate) {
    return oldDelegate.centroid != centroid || oldDelegate.referencePoint != referencePoint;
  }
}