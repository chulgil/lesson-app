import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Standard bottom sheet drag handle.
///
/// Provides a consistent visual indicator for draggable bottom sheets
/// across the app.
class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({
    super.key,
    this.width = 40,
    this.height = 4,
    this.color,
    this.margin = const EdgeInsets.only(top: 12),
  });

  final double width;
  final double height;
  final Color? color;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? AppColors.inkQuaternary,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

/// Standard bottom sheet container with rounded top corners.
///
/// Wraps content in a white container with standard styling.
class BottomSheetContainer extends StatelessWidget {
  const BottomSheetContainer({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.borderRadius = 20,
  });

  final Widget child;
  final Color backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(borderRadius),
        ),
      ),
      child: child,
    );
  }
}
