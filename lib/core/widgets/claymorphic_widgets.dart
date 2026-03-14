import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';

/// Claymorphic Container - Soft pillowy container with inner shadows
/// 
/// Features:
/// - Soft 3D "extruded" appearance
/// - Dual shadows (light and dark) for depth
/// - Smooth rounded corners
/// - Optional press animation
class ClayContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? color;
  final double depth;
  final bool emboss;

  const ClayContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = 20,
    this.color,
    this.depth = 1.0,
    this.emboss = false,
  });

  @override
  State<ClayContainer> createState() => _ClayContainerState();
}

class _ClayContainerState extends State<ClayContainer> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.color ?? (isDark ? AppColors.clayDark : AppColors.clayLight);

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
        duration: const Duration(milliseconds: 150),
        curve: LiquidCurves.flow,
        margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: widget.padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isPressed || widget.emboss
              ? ClayShadows.pressed(isDark)
              : (isDark 
                  ? ClayShadows.dark(intensity: widget.depth)
                  : ClayShadows.light(intensity: widget.depth)),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Clay Button - Extruded button with press-in animation
class ClayButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const ClayButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.color ?? AppColors.primary;
    final bgColor = isDark ? AppColors.clayDark : AppColors.clayLight;

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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isPressed
              ? ClayShadows.pressed(isDark)
              : (isDark 
                  ? ClayShadows.dark()
                  : ClayShadows.light()),
        ),
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
                  valueColor: AlwaysStoppedAnimation(baseColor),
                ),
              ),
            ] else ...[
              if (widget.icon != null) ...[
                Icon(widget.icon, color: baseColor, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: baseColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Clay Chip - Soft badge/tag component
class ClayChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool isSelected;

  const ClayChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = color ?? AppColors.primary;
    final bgColor = isSelected 
        ? accentColor.withValues(alpha: 0.15)
        : (isDark ? AppColors.clayDark : AppColors.clayLight);

    return GestureDetector(
      onTap: () {
        HapticUtils.lightTap();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(50),
          boxShadow: isSelected 
              ? [] 
              : (isDark 
                  ? ClayShadows.dark(intensity: 0.5)
                  : ClayShadows.light(intensity: 0.5)),
          border: isSelected 
              ? Border.all(color: accentColor, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? accentColor : context.appColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? accentColor : context.appColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clay Avatar - Rounded avatar with clay depth
class ClayAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const ClayAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 48,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap != null ? () {
        HapticUtils.lightTap();
        onTap!();
      } : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          boxShadow: isDark 
              ? ClayShadows.dark(intensity: 0.8)
              : ClayShadows.light(intensity: 0.8),
        ),
        child: ClipOval(
          child: imageUrl != null
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _buildInitials(bgColor),
                )
              : _buildInitials(bgColor),
        ),
      ),
    );
  }

  Widget _buildInitials(Color bgColor) {
    return Container(
      color: bgColor.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initials ?? '?',
        style: TextStyle(
          color: bgColor,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

/// Clay Icon Container - Soft 3D icon wrapper
class ClayIconContainer extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final VoidCallback? onTap;

  const ClayIconContainer({
    super.key,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.size = 48,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? (isDark ? AppColors.clayDark : AppColors.clayLight);
    final color = iconColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap != null ? () {
        HapticUtils.lightTap();
        onTap!();
      } : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: isDark 
              ? ClayShadows.dark(intensity: 0.7)
              : ClayShadows.light(intensity: 0.7),
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// Clay Progress Indicator - Soft 3D progress bar
class ClayProgressIndicator extends StatelessWidget {
  final double progress;
  final Color? progressColor;
  final double height;

  const ClayProgressIndicator({
    super.key,
    required this.progress,
    this.progressColor,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.clayDark : AppColors.clayLight;
    final fillColor = progressColor ?? AppColors.primary;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: ClayShadows.pressed(isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: [
                BoxShadow(
                  color: fillColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
