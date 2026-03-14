import 'package:flutter/material.dart';

/// A custom tab indicator that renders a rounded pill/capsule shape
/// instead of the default underline.
///
/// Supports optional gradient fill for the indicator.
class AnimatedPillTabIndicator extends Decoration {
  final Color color;
  final double indicatorHeight;
  final double borderRadius;
  final Gradient? gradient;

  const AnimatedPillTabIndicator({
    this.color = Colors.white,
    this.indicatorHeight = 36,
    this.borderRadius = 12,
    this.gradient,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _PillPainter(
      color: color,
      indicatorHeight: indicatorHeight,
      borderRadius: borderRadius,
      gradient: gradient,
    );
  }
}

class _PillPainter extends BoxPainter {
  final Color color;
  final double indicatorHeight;
  final double borderRadius;
  final Gradient? gradient;

  _PillPainter({
    required this.color,
    required this.indicatorHeight,
    required this.borderRadius,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size ?? Size.zero;

    // Center the pill vertically within the tab
    final yOffset = (size.height - indicatorHeight) / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        offset.dx + 4,
        offset.dy + yOffset,
        size.width - 8,
        indicatorHeight,
      ),
      Radius.circular(borderRadius),
    );

    final paint = Paint();
    if (gradient != null) {
      paint.shader = gradient!.createShader(rect.outerRect);
    } else {
      paint.color = color;
    }

    canvas.drawRRect(rect, paint);
  }
}
