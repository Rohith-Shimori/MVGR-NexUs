import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';

/// Reusable empty state widget with customizable illustration
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;
  final String? imagePath; // Optional custom image
  
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
    this.imagePath,
  });

  /// Factory constructors for common cases
  factory EmptyState.noClubs({VoidCallback? onExplore}) => EmptyState(
    icon: Icons.groups_outlined,
    title: 'No clubs yet',
    subtitle: 'Join a club to see it here',
    iconColor: AppColors.clubsColor,
    imagePath: 'lib/assets/images/empty_clubs.png',
    action: onExplore != null ? _ActionButton('Explore Clubs', onExplore) : null,
  );

  factory EmptyState.noEvents({VoidCallback? onExplore}) => EmptyState(
    icon: Icons.event_outlined,
    title: 'No events found',
    subtitle: 'Check back later for upcoming events',
    iconColor: AppColors.eventsColor,
    imagePath: 'lib/assets/images/empty_events.png',
    action: onExplore != null ? _ActionButton('Browse Events', onExplore) : null,
  );

  factory EmptyState.noResults() => const EmptyState(
    icon: Icons.search_off,
    title: 'No results found',
    subtitle: 'Try adjusting your search or filters',
    imagePath: 'lib/assets/images/empty_search.png',
  );

  factory EmptyState.noFavorites() => const EmptyState(
    icon: Icons.favorite_border,
    title: 'No favorites yet',
    subtitle: 'Tap the heart icon to save items',
    iconColor: AppColors.error,
  );

  factory EmptyState.noPosts() => const EmptyState(
    icon: Icons.article_outlined,
    title: 'No posts yet',
    subtitle: 'Be the first to post something!',
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show image if available, fallback to icon
            if (imagePath != null)
              Image.asset(
                imagePath!,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _buildIcon(context),
              )
            else
              _buildIcon(context),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: context.appColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Icon(
      icon,
      size: 64,
      color: iconColor ?? context.appColors.textTertiary,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  
  const _ActionButton(this.label, this.onTap);
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        HapticUtils.lightTap();
        onTap();
      },
      child: Text(label),
    );
  }
}

/// Searchable list mixin - add search functionality to any list screen
mixin SearchableMixin<T> {
  String _searchQuery = '';
  
  String get searchQuery => _searchQuery;
  
  void updateSearch(String query) {
    _searchQuery = query.toLowerCase().trim();
  }
  
  void clearSearch() {
    _searchQuery = '';
  }
  
  /// Override this to define search logic
  bool matchesSearch(T item);
  
  List<T> filterItems(List<T> items) {
    if (_searchQuery.isEmpty) return items;
    return items.where(matchesSearch).toList();
  }
}

/// Undo helper - show undo snackbar with action
class UndoHelper {
  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            HapticUtils.mediumTap();
            onUndo();
          },
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Pull-to-refresh wrapper with haptic feedback
class RefreshableList extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;

  const RefreshableList({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticUtils.pullToRefresh();
        await onRefresh();
      },
      color: color ?? AppColors.primary,
      child: child,
    );
  }
}

/// Favorite button with animation
class FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onToggle;
  final double size;
  final Color? activeColor;

  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.size = 24,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: child,
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          key: ValueKey(isFavorite),
          color: isFavorite 
              ? (activeColor ?? AppColors.error) 
              : context.appColors.textTertiary,
          size: size,
        ),
      ),
      onPressed: () {
        HapticUtils.selection();
        onToggle();
      },
    );
  }
}

/// Search bar widget  
class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const SearchBar({
    super.key,
    required this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

/// Animated skeleton loading box with shimmer effect
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
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
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

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

/// Card skeleton for loading states
class CardSkeleton extends StatelessWidget {
  final double height;
  
  const CardSkeleton({super.key, this.height = 180});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 80, borderRadius: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 18, width: 150),
                const SizedBox(height: 8),
                SkeletonBox(height: 14, width: 100),
                const SizedBox(height: 12),
                SkeletonBox(height: 12, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// List skeleton with multiple card skeletons
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ListSkeleton({super.key, this.itemCount = 3, this.itemHeight = 180});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) => CardSkeleton(height: itemHeight),
    );
  }
}

/// Premium Animated Tab Bar with pill indicator
class AnimatedTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  const AnimatedTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? AppColors.primary;
    final inactive = inactiveColor ?? context.appColors.textTertiary;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isSelected = index == selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticUtils.lightTap();
                onTabChanged(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected ? active : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : inactive,
                    ),
                    child: Text(label),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Responsive layout builder for adaptive designs
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints, ScreenSize screenSize) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = _getScreenSize(constraints.maxWidth);
        return builder(context, constraints, screenSize);
      },
    );
  }

  ScreenSize _getScreenSize(double width) {
    if (width < 600) return ScreenSize.mobile;
    if (width < 900) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }
}

enum ScreenSize { mobile, tablet, desktop }

/// Extension for responsive values
extension ResponsiveExtension on BuildContext {
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    final width = MediaQuery.of(this).size.width;
    if (width >= 900 && desktop != null) return desktop;
    if (width >= 600 && tablet != null) return tablet;
    return mobile;
  }
  
  int get gridColumns => responsive(mobile: 2, tablet: 3, desktop: 4);
  double get horizontalPadding => responsive(mobile: 16.0, tablet: 24.0, desktop: 32.0);
}

/// Premium card with optional hover/press effects
class PremiumCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final bool enableHover;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.backgroundColor,
    this.enableHover = true,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onTap != null
          ? () {
              HapticUtils.lightTap();
              widget.onTap!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: widget.margin,
        padding: widget.padding ?? const EdgeInsets.all(16),
        transform: _isPressed ? Matrix4.diagonal3Values(0.98, 0.98, 1.0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _isPressed
                ? AppColors.primary.withValues(alpha: 0.3)
                : context.appColors.border,
          ),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Scale on tap wrapper for micro-interactions
class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleValue;

  const ScaleOnTap({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleValue = 0.95,
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        HapticUtils.lightTap();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Smooth page indicator for onboarding/carousels
class SmoothPageIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color? activeColor;
  final Color? inactiveColor;
  final double dotSize;
  final double activeDotWidth;

  const SmoothPageIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
    this.activeColor,
    this.inactiveColor,
    this.dotSize = 8,
    this.activeDotWidth = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? activeDotWidth : dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: isActive
                ? (activeColor ?? AppColors.primary)
                : (inactiveColor ?? context.appColors.textTertiary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(dotSize / 2),
          ),
        );
      }),
    );
  }
}

/// Shared Form Field Widget - Reduces duplication across 9+ screens
/// Use this instead of creating private _FormField classes in each screen
class AppFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final int maxLines;
  final Color? focusColor;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const AppFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.maxLines = 1,
    this.focusColor,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFocusColor = focusColor ?? AppColors.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.appColors.textTertiary),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.appColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.appColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: effectiveFocusColor, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.appColors.divider.withValues(alpha: 0.5)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

/// Shared Picker Field Widget - For date/time/dropdown pickers
class AppPickerField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;

  const AppPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appColors.divider),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor ?? context.appColors.textTertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: context.appColors.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

