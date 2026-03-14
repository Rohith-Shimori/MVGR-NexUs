import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A premium circular loading indicator with a sweeping gradient arc
/// and subtle glow effect.
///
/// Use in place of `CircularProgressIndicator` for button loading states
/// and inline spinners.
class PremiumLoadingIndicator extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final List<Color>? gradientColors;

  const PremiumLoadingIndicator({
    super.key,
    this.size = 24,
    this.strokeWidth = 2.5,
    this.color,
    this.gradientColors,
  });

  /// Small variant for use in buttons
  const PremiumLoadingIndicator.small({
    super.key,
    this.size = 18,
    this.strokeWidth = 2,
    this.color = Colors.white,
    this.gradientColors,
  });

  @override
  State<PremiumLoadingIndicator> createState() => _PremiumLoadingIndicatorState();
}

class _PremiumLoadingIndicatorState extends State<PremiumLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final colors = widget.gradientColors ?? [
      baseColor,
      baseColor.withValues(alpha: 0.3),
      baseColor.withValues(alpha: 0.05),
    ];

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _GradientArcPainter(
              progress: _controller.value,
              colors: colors,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _GradientArcPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final double strokeWidth;

  _GradientArcPainter({
    required this.progress,
    required this.colors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final startAngle = 2 * math.pi * progress - math.pi / 2;
    const sweepAngle = 1.5 * math.pi; // 270 degrees

    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: colors,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    // Subtle glow at the leading edge
    final glowPaint = Paint()
      ..color = colors.first.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawArc(rect, startAngle, 0.15, false, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _GradientArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
