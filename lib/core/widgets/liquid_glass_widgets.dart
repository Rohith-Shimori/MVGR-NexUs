import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';

/// Liquid Glass Card - Translucent card with refractive border and animated glow
/// 
/// A premium glassmorphism-inspired card with:
/// - Frosted glass blur effect
/// - Animated gradient border
/// - Subtle glow on interaction
/// - Smooth parallax motion (optional)
class LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurAmount;
  final VoidCallback? onTap;
  final bool enableGlow;
  final Color? glowColor;
  final bool enableBorderGradient;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blurAmount = 12,
    this.onTap,
    this.enableGlow = true,
    this.glowColor,
    this.enableBorderGradient = true,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: LiquidCurves.flow),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveGlowColor = widget.glowColor ?? AppColors.liquidGlassGlow;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.enableGlow && _isPressed
                ? [
                    BoxShadow(
                      color: effectiveGlowColor.withValues(alpha: 0.2 * _glowAnimation.value),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ]
                : AppShadows.medium,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blurAmount,
                sigmaY: widget.blurAmount,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: LiquidCurves.flow,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? AppColors.liquidGlassGradientDark
                        : AppColors.liquidGlassGradient,
                  ),
                  border: widget.enableBorderGradient
                      ? Border.all(
                          color: isDark
                              ? AppColors.liquidGlassBorderDark
                              : AppColors.liquidGlassBorder,
                          width: 1.5,
                        )
                      : null,
                ),
                transform: _isPressed
                    ? Matrix4.diagonal3Values(0.98, 0.98, 1.0)
                    : Matrix4.identity(),
                transformAlignment: Alignment.center,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap != null
                        ? () {
                            HapticUtils.lightTap();
                            widget.onTap!();
                          }
                        : null,
                    onTapDown: (_) {
                      setState(() => _isPressed = true);
                      _glowController.forward();
                    },
                    onTapUp: (_) {
                      setState(() => _isPressed = false);
                      _glowController.reverse();
                    },
                    onTapCancel: () {
                      setState(() => _isPressed = false);
                      _glowController.reverse();
                    },
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: Padding(
                      padding: widget.padding ?? const EdgeInsets.all(20),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Liquid Glass Button - Fluid button with ripple effect
class LiquidGlassButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? glowColor;
  final double? width;

  const LiquidGlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.glowColor,
    this.width,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveGlowColor = widget.glowColor ?? AppColors.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: LiquidCurves.flow,
      width: widget.width,
      transform: _isPressed ? Matrix4.diagonal3Values(0.96, 0.96, 1.0) : Matrix4.identity(),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isPressed
            ? []
            : SkeuoShadows.raised(effectiveGlowColor, elevation: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveGlowColor.withValues(alpha: isDark ? 0.4 : 0.8),
                  effectiveGlowColor.withValues(alpha: isDark ? 0.3 : 0.6),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : () {
                  HapticUtils.mediumTap();
                  widget.onPressed?.call();
                },
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) => setState(() => _isPressed = false),
                onTapCancel: () => setState(() => _isPressed = false),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ] else ...[
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          widget.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aurora Background - Animated gradient backdrop for headers/sections
class AuroraBackground extends StatelessWidget {
  final Widget child;
  final double height;
  final List<Color>? colors;
  final bool subtle;

  const AuroraBackground({
    super.key,
    required this.child,
    this.height = 200,
    this.colors,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColors = colors ?? (subtle 
        ? AppColors.auroraGradientSubtle 
        : AppColors.auroraGradient);

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: effectiveColors,
        ),
      ),
      child: child,
    );
  }
}

/// Liquid Glass Text Field - Input field with flowing border animation
class LiquidGlassTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const LiquidGlassTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
  });

  @override
  State<LiquidGlassTextField> createState() => _LiquidGlassTextFieldState();
}

class _LiquidGlassTextFieldState extends State<LiquidGlassTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: LiquidCurves.flow,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isFocused
                  ? AppColors.primary
                  : (isDark ? AppColors.liquidGlassBorderDark : AppColors.liquidGlassBorder),
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: TextFormField(
                controller: widget.controller,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                onChanged: widget.onChanged,
                validator: widget.validator,
                onTap: () => setState(() => _isFocused = true),
                onEditingComplete: () => setState(() => _isFocused = false),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: context.appColors.textTertiary),
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(widget.prefixIcon, color: context.appColors.textSecondary)
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.liquidGlassBaseDark
                      : AppColors.liquidGlassBase,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Glow Icon Button - Luminous icon button with press effect
class GlowIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? glowColor;
  final double size;
  final String? tooltip;

  const GlowIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.glowColor,
    this.size = 24,
    this.tooltip,
  });

  @override
  State<GlowIconButton> createState() => _GlowIconButtonState();
}

class _GlowIconButtonState extends State<GlowIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? context.appColors.textPrimary;
    final effectiveGlowColor = widget.glowColor ?? AppColors.primary;

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: LiquidCurves.flow,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: _isPressed
            ? [
                BoxShadow(
                  color: effectiveGlowColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          HapticUtils.lightTap();
          widget.onPressed?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Icon(
            widget.icon,
            color: _isPressed ? effectiveGlowColor : effectiveColor,
            size: widget.size,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
