/// Shimmer Loading Widget
/// Reusable skeleton loading for data-fetching screens
library;

import 'package:flutter/material.dart';

/// A shimmer box that animates to indicate loading state
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.withValues(alpha: 0.12);
    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.grey.withValues(alpha: 0.04);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}

/// A shimmer list showing multiple loading rows
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;
  final EdgeInsets padding;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72,
    this.spacing = 12,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(itemCount, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index < itemCount - 1 ? spacing : 0),
            child: Row(
              children: [
                ShimmerBox(
                  width: itemHeight - 16,
                  height: itemHeight - 16,
                  borderRadius: 14,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        height: 14,
                        width: 160,
                        borderRadius: 6,
                      ),
                      const SizedBox(height: 8),
                      ShimmerBox(
                        height: 10,
                        width: 100,
                        borderRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Shimmer card grid for loading states
class ShimmerCardGrid extends StatelessWidget {
  final int itemCount;
  final double cardHeight;
  final int crossAxisCount;

  const ShimmerCardGrid({
    super.key,
    this.itemCount = 4,
    this.cardHeight = 140,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return ShimmerBox(height: cardHeight, borderRadius: 16);
      },
    );
  }
}
