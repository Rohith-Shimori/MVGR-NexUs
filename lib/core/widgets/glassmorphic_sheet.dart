import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shows a modal bottom sheet with a glassmorphic frosted background.
///
/// This replaces the standard `showModalBottomSheet` with a premium
/// frosted glass effect including blur backdrop, gradient handle bar,
/// and smooth rounded corners.
Future<T?> showGlassModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool enableDrag = true,
  double? height,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (ctx) => _GlassSheetWrapper(
      height: height,
      child: builder(ctx),
    ),
  );
}

class _GlassSheetWrapper extends StatelessWidget {
  final Widget child;
  final double? height;

  const _GlassSheetWrapper({required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark
        ? Colors.black.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.85);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.3);

    Widget content = ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: borderColor, width: 1.5),
              left: BorderSide(color: borderColor, width: 0.5),
              right: BorderSide(color: borderColor, width: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.appColors.textTertiary.withValues(alpha: 0.3),
                        context.appColors.textTertiary.withValues(alpha: 0.6),
                        context.appColors.textTertiary.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Sheet content
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );

    if (height != null) {
      content = SizedBox(height: height, child: content);
    }

    return content;
  }
}
