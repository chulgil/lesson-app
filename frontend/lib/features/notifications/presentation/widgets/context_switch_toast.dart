import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Toast notification shown after context switch completes.
///
/// Displays a message indicating which context (teacher/owner) was switched to.
/// Auto-dismisses after 3 seconds.
class ContextSwitchToast extends StatefulWidget {
  final String activeContext;

  const ContextSwitchToast({required this.activeContext, super.key});

  @override
  State<ContextSwitchToast> createState() => _ContextSwitchToastState();
}

class _ContextSwitchToastState extends State<ContextSwitchToast> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(const Duration(seconds: 3), _dismissDialog);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    super.dispose();
  }

  void _dismissDialog() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.paper, size: 40),
            const SizedBox(height: AppSpacing.space2),
            Text(
              _getContextSwitchMessage(),
              style: AppTypography.bodyMedium.copyWith(color: AppColors.paper),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getContextSwitchMessage() {
    if (widget.activeContext == 'owner') {
      return AppStrings.contextToggleSwitchedToOwner;
    }
    return AppStrings.contextToggleSwitchedToTeacher;
  }
}
