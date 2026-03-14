import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';

/// Skeuomorphic Button - Raised tactile button with press animation
/// 
/// Features:
/// - 3D raised appearance with layered shadows
/// - Smooth press animation (button "pushes down")
/// - Gradient highlight for realistic lighting
/// - Haptic feedback on press
class SkeuoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final bool outlined;

  const SkeuoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.icon,
    this.isLoading = false,
    this.width,
    this.outlined = false,
  });

  @override
  State<SkeuoButton> createState() => _SkeuoButtonState();
}

class _SkeuoButtonState extends State<SkeuoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.color ?? AppColors.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading) {
          HapticUtils.mediumTap();
          widget.onPressed?.call();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        width: widget.width,
        transform: _isPressed 
            ? Matrix4.translationValues(0, 2, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: widget.outlined
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    baseColor,
                    Color.lerp(baseColor, Colors.black, 0.15)!,
                  ],
                ),
          border: widget.outlined
              ? Border.all(color: baseColor, width: 2)
              : null,
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ]
              : [
                  // Top highlight
                  BoxShadow(
                    color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.3),
                    offset: const Offset(0, -1),
                    blurRadius: 0,
                  ),
                  // Main shadow
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                  // Ambient shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(0, 6),
                    blurRadius: 12,
                  ),
                ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      widget.outlined ? baseColor : Colors.white,
                    ),
                  ),
                ),
              ] else ...[
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: widget.outlined ? baseColor : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.outlined ? baseColor : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeuomorphic Card - Raised container with depth layers
class SkeuoCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;

  const SkeuoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.borderRadius = 16,
  });

  @override
  State<SkeuoCard> createState() => _SkeuoCardState();
}

class _SkeuoCardState extends State<SkeuoCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = widget.color ?? Theme.of(context).cardColor;

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              HapticUtils.lightTap();
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: widget.padding ?? const EdgeInsets.all(20),
        transform: _isPressed 
            ? Matrix4.translationValues(0, 2, 0) 
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ]
              : [
                  // Top edge highlight
                  BoxShadow(
                    color: Colors.white.withValues(alpha: isDark ? 0.02 : 0.8),
                    offset: const Offset(0, -1),
                    blurRadius: 0,
                  ),
                  // Primary shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                  // Secondary ambient shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Skeuomorphic Toggle - Tactile on/off switch
class SkeuoToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final double scale;

  const SkeuoToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.scale = 1.0,
  });

  @override
  State<SkeuoToggle> createState() => _SkeuoToggleState();
}

class _SkeuoToggleState extends State<SkeuoToggle> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = widget.activeColor ?? AppColors.primary;
    
    final trackWidth = 52.0 * widget.scale;
    final trackHeight = 30.0 * widget.scale;
    final thumbSize = 24.0 * widget.scale;
    final thumbMargin = 3.0 * widget.scale;

    return GestureDetector(
      onTap: () {
        HapticUtils.selection();
        widget.onChanged(!widget.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: LiquidCurves.flow,
        width: trackWidth,
        height: trackHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(trackHeight / 2),
          color: widget.value 
              ? activeColor 
              : (isDark ? AppColors.cardDark : Colors.grey.shade300),
          boxShadow: [
            // Inset shadow for track
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.value ? 0.2 : 0.15),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Thumb
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: LiquidCurves.flow,
              left: widget.value ? trackWidth - thumbSize - thumbMargin : thumbMargin,
              top: thumbMargin,
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeuomorphic Icon Button - Raised icon button with depth
class SkeuoIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;

  const SkeuoIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 24,
    this.tooltip,
  });

  @override
  State<SkeuoIconButton> createState() => _SkeuoIconButtonState();
}

class _SkeuoIconButtonState extends State<SkeuoIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ?? Theme.of(context).cardColor;
    final iconColor = widget.color ?? context.appColors.textPrimary;

    final button = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticUtils.lightTap();
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        transform: _isPressed 
            ? Matrix4.translationValues(0, 1, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: isDark ? 0.02 : 0.5),
                    offset: const Offset(0, -1),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.1),
                    offset: const Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Icon(
          widget.icon,
          color: iconColor,
          size: widget.size,
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
