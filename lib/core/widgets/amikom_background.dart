import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable atmospheric background decorator featuring Amikom's signature ambient
/// radial glow and technopreneur hexagon geometric watermarks.
class AmikomBackground extends StatelessWidget {
  final Widget child;
  final bool showHexagons;

  const AmikomBackground({
    super.key,
    required this.child,
    this.showHexagons = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base Background Color
        Positioned.fill(
          child: Container(
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          ),
        ),

        // Ambient Top-Right Radial Purple Glow
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? AppColors.amikomPurple : AppColors.amikomPurpleLight)
                      .withValues(alpha: isDark ? 0.22 : 0.09),
                  Colors.transparent,
                ],
                radius: 0.75,
              ),
            ),
          ),
        ),

        // Ambient Bottom-Left Radial Gold Glow
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.amikomGold.withValues(alpha: isDark ? 0.12 : 0.05),
                  Colors.transparent,
                ],
                radius: 0.75,
              ),
            ),
          ),
        ),

        // Technopreneur Geometric Hexagon Watermark
        if (showHexagons) ...[
          Positioned(
            top: 60,
            right: 16,
            child: CustomPaint(
              size: const Size(120, 120),
              painter: _HexagonWatermarkPainter(
                color: (isDark ? AppColors.amikomPurpleLight : AppColors.amikomPurple)
                    .withValues(alpha: isDark ? 0.07 : 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 140,
            left: 20,
            child: CustomPaint(
              size: const Size(80, 80),
              painter: _HexagonWatermarkPainter(
                color: AppColors.amikomGold.withValues(alpha: isDark ? 0.06 : 0.03),
              ),
            ),
          ),
        ],

        // Foreground Content
        Positioned.fill(child: child),
      ],
    );
  }
}

class _HexagonWatermarkPainter extends CustomPainter {
  final Color color;

  _HexagonWatermarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    _drawHexagon(canvas, center, radius, paint);
    _drawHexagon(canvas, center, radius * 0.65, paint);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexagonWatermarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
