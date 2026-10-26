import 'package:flutter/material.dart';

/// Icône vectorielle personnalisée représentant l'empreinte d'un sabot fendu (patte d'ovin / mouton)
/// avec les deux onglons avant symétriques et les deux ergots arrière.
class SheepHoofIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const SheepHoofIcon({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final effectiveSize = size ?? iconTheme.size ?? 24.0;
    final effectiveColor = color ?? iconTheme.color ?? Colors.black;

    return SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: CustomPaint(
        painter: _SheepHoofPainter(color: effectiveColor),
      ),
    );
  }
}

class _SheepHoofPainter extends CustomPainter {
  final Color color;

  const _SheepHoofPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Onglon gauche (sabot fendu - face interne droite, externe incurvée en amande)
    final leftClaw = Path()
      ..moveTo(w * 0.44, h * 0.10)
      ..cubicTo(
        w * 0.24, h * 0.14,
        w * 0.14, h * 0.36,
        w * 0.17, h * 0.56,
      )
      ..cubicTo(
        w * 0.19, h * 0.67,
        w * 0.30, h * 0.72,
        w * 0.40, h * 0.69,
      )
      ..cubicTo(
        w * 0.45, h * 0.67,
        w * 0.46, h * 0.60,
        w * 0.46, h * 0.48,
      )
      ..lineTo(w * 0.46, h * 0.16)
      ..cubicTo(
        w * 0.46, h * 0.11,
        w * 0.45, h * 0.10,
        w * 0.44, h * 0.10,
      )
      ..close();

    // Onglon droit (symétrique)
    final rightClaw = Path()
      ..moveTo(w * 0.56, h * 0.10)
      ..cubicTo(
        w * 0.76, h * 0.14,
        w * 0.86, h * 0.36,
        w * 0.83, h * 0.56,
      )
      ..cubicTo(
        w * 0.81, h * 0.67,
        w * 0.70, h * 0.72,
        w * 0.60, h * 0.69,
      )
      ..cubicTo(
        w * 0.55, h * 0.67,
        w * 0.54, h * 0.60,
        w * 0.54, h * 0.48,
      )
      ..lineTo(w * 0.54, h * 0.16)
      ..cubicTo(
        w * 0.54, h * 0.11,
        w * 0.55, h * 0.10,
        w * 0.56, h * 0.10,
      )
      ..close();

    // Ergot arrière gauche (garde-corps ovin)
    canvas.save();
    canvas.translate(w * 0.31, h * 0.83);
    canvas.rotate(-0.22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: w * 0.15,
        height: h * 0.12,
      ),
      paint,
    );
    canvas.restore();

    // Ergot arrière droit
    canvas.save();
    canvas.translate(w * 0.69, h * 0.83);
    canvas.rotate(0.22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: w * 0.15,
        height: h * 0.12,
      ),
      paint,
    );
    canvas.restore();

    canvas.drawPath(leftClaw, paint);
    canvas.drawPath(rightClaw, paint);
  }

  @override
  bool shouldRepaint(covariant _SheepHoofPainter oldDelegate) =>
      oldDelegate.color != color;
}
