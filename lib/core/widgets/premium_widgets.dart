import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';

/// Premium glassmorphism card - Enhanced with liquid glass features
/// 
/// Supports both classic glassmorphism and enhanced liquid glass mode.
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool enableLiquidEffect;
  final bool enableGlow;
  final Color? glowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderRadius,
    this.onTap,
    this.enableLiquidEffect = false,
    this.enableGlow = false,
    this.glowColor,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderRadius = widget.borderRadius ?? AppRadius.borderMd;
    final effectiveGlowColor = widget.glowColor ?? AppColors.primary;
    
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
        curve: Curves.easeOut,
        margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        transform: _isPressed ? Matrix4.diagonal3Values(0.98, 0.98, 1.0) : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          boxShadow: [
            if (widget.enableGlow && _isPressed)
              BoxShadow(
                color: effectiveGlowColor.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: _isPressed ? 0.05 : 0.1),
              blurRadius: _isPressed ? 10 : 20,
              offset: Offset(0, _isPressed ? 5 : 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: effectiveBorderRadius,
          child: BackdropFilter(
            filter: widget.enableLiquidEffect
                ? ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: effectiveBorderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? (widget.enableLiquidEffect
                          ? AppColors.liquidGlassGradientDark
                          : [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.05),
                            ])
                      : (widget.enableLiquidEffect
                          ? AppColors.liquidGlassGradient
                          : [
                              Colors.white.withValues(alpha: 0.8),
                              Colors.white.withValues(alpha: 0.6),
                            ]),
                ),
                border: Border.all(
                  color: isDark
                      ? (widget.enableLiquidEffect 
                          ? AppColors.liquidGlassBorderDark 
                          : Colors.white.withValues(alpha: 0.1))
                      : (widget.enableLiquidEffect 
                          ? AppColors.liquidGlassBorder 
                          : Colors.white.withValues(alpha: 0.5)),
                  width: widget.enableLiquidEffect ? 1.5 : 1.0,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: effectiveBorderRadius,
                child: Padding(
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Gradient button with premium feel
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color>? colors;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.colors,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? AppColors.primaryGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: AppRadius.borderMd,
        boxShadow: [
          BoxShadow(
            color: (colors?.first ?? AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppRadius.borderMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ] else ...[
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
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
    );
  }
}

/// Premium feature card with gradient accent
class PremiumFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final int? badge;
  final VoidCallback? onTap;

  const PremiumFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.medium,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderLg,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppRadius.borderMd,
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null && badge! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: AppRadius.borderCircular,
                    ),
                    child: Text(
                      badge! > 99 ? '99+' : '$badge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).disabledColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Action chip with icon
class ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final Color? activeColor;

  const ActionChip({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.primary;
    
    return Material(
      color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: AppRadius.borderCircular,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderCircular,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderCircular,
            border: Border.all(
              color: isActive ? color : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? color : Theme.of(context).disabledColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? color : null,
                  fontWeight: isActive ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stats row for profiles and details
class StatsRow extends StatelessWidget {
  final List<StatItem> items;

  const StatsRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.map((item) => _StatWidget(item: item)).toList(),
    );
  }
}

class StatItem {
  final String label;
  final String value;
  final IconData? icon;

  const StatItem({required this.label, required this.value, this.icon});
}

class _StatWidget extends StatelessWidget {
  final StatItem item;

  const _StatWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (item.icon != null) ...[
          Icon(item.icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 4),
        ],
        Text(
          item.value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          item.label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Floating action sheet
class FloatingActionSheet extends StatelessWidget {
  final List<FloatingAction> actions;

  const FloatingActionSheet({super.key, required this.actions});

  static Future<T?> show<T>(BuildContext context, List<FloatingAction> actions) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FloatingActionSheet(actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.borderLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...actions.map((action) => ListTile(
            leading: Icon(action.icon, color: action.color ?? AppColors.primary),
            title: Text(action.label),
            subtitle: action.subtitle != null ? Text(action.subtitle!) : null,
            onTap: () {
              Navigator.pop(context);
              action.onTap();
            },
          )),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class FloatingAction {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  const FloatingAction({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.color,
  });
}

/// Pull to refresh wrapper
class RefreshableList extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const RefreshableList({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: child,
    );
  }
}

/// Empty state with illustration
class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              GradientButton(
                text: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
