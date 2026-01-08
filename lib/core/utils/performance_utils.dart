// Performance and Animation Utilities for MVGR NexUs
// Provides reusable optimization patterns and premium animations

import 'package:flutter/material.dart';

/// Animated list item that fades and slides in
/// Use in ListView.builder for staggered entrance animations
class AnimatedListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final Duration delay;
  
  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = const Duration(milliseconds: 50),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Tap-animated container with scale effect
class TapScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  const TapScaleWidget({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<TapScaleWidget> createState() => _TapScaleWidgetState();
}

class _TapScaleWidgetState extends State<TapScaleWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Shimmer loading placeholder
class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  /// Factory for text placeholder
  factory ShimmerWidget.text({double width = 120, double height = 16}) =>
      ShimmerWidget(width: width, height: height, borderRadius: 4);

  /// Factory for avatar placeholder
  factory ShimmerWidget.avatar({double size = 48}) =>
      ShimmerWidget(width: size, height: size, borderRadius: size / 2);

  /// Factory for card placeholder
  factory ShimmerWidget.card() =>
      const ShimmerWidget(width: double.infinity, height: 120, borderRadius: 12);

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(1 + 2 * _controller.value, 0),
              colors: isDark
                  ? [
                      const Color(0xFF1A1F2E),
                      const Color(0xFF252B3B),
                      const Color(0xFF1A1F2E),
                    ]
                  : [
                      const Color(0xFFEEEEEE),
                      const Color(0xFFF5F5F5),
                      const Color(0xFFEEEEEE),
                    ],
            ),
          ),
        );
      },
    );
  }
}

/// Optimized ListView builder with cache and performance hints
class OptimizedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double? cacheExtent;
  final Widget? separatorBuilder;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.cacheExtent = 500, // Pre-cache 500px worth of items
    this.separatorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (separatorBuilder != null) {
      return ListView.separated(
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics ?? const BouncingScrollPhysics(),
        cacheExtent: cacheExtent,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        itemCount: items.length,
        separatorBuilder: (_, i) => separatorBuilder!,
        itemBuilder: (context, index) => itemBuilder(context, items[index], index),
      );
    }

    return ListView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const BouncingScrollPhysics(),
      cacheExtent: cacheExtent,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(context, items[index], index),
    );
  }
}

/// Debouncer for search and input optimization
class Debouncer {
  final int milliseconds;
  VoidCallback? _action;
  
  Debouncer({this.milliseconds = 300});

  void run(VoidCallback action) {
    _action = action;
    Future.delayed(Duration(milliseconds: milliseconds), () {
      if (_action == action) {
        action();
      }
    });
  }

  void cancel() {
    _action = null;
  }
}

/// Image loading with fade-in effect and error handling
class OptimizedNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;
  final Widget? placeholder;
  final BorderRadius? borderRadius;

  const OptimizedNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.placeholder,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame != null ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: Theme.of(context).cardColor,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Theme.of(context).disabledColor,
            ),
          ),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}

/// Memoization helper for expensive computations
class Memoizer<T, R> {
  final Map<T, R> _cache = {};
  final R Function(T) _computation;

  Memoizer(this._computation);

  R call(T input) {
    return _cache.putIfAbsent(input, () => _computation(input));
  }

  void clear() => _cache.clear();
}
