import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A frosted glass SliverAppBar with blur effect and gradient border.
///
/// Provides a premium translucent app bar that blurs the content
/// scrolling underneath, with a subtle gradient border at the bottom.
class FrostedSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final double expandedHeight;
  final Widget? flexibleSpace;
  final bool pinned;
  final bool floating;
  final PreferredSizeWidget? bottom;

  const FrostedSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.expandedHeight = 0,
    this.flexibleSpace,
    this.pinned = true,
    this.floating = false,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.75);

    return SliverAppBar(
      expandedHeight: expandedHeight > 0 ? expandedHeight : null,
      pinned: pinned,
      floating: floating,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: flexibleSpace ?? FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 52, bottom: 16),
        title: Text(
          title,
          style: TextStyle(
            color: context.appColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        background: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
