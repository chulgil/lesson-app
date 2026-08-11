import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Transient feedback strip shown above the bottom action bar after an
/// action succeeds/fails/informs (e.g. "저장되었습니다"). The parent screen
/// owns the message/timer state and passes [onDismiss] to clear it.
class RequestDetailEventStrip extends StatelessWidget {
  final String? message;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;

  const RequestDetailEventStrip({
    super.key,
    required this.message,
    required this.color,
    required this.icon,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child:
          message != null
              ? Container(
                key: ValueKey(message),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.space2,
                ),
                color: color.withValues(alpha: 0.12),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        message!,
                        style: AppTypography.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onDismiss,
                      child: Icon(Icons.close, size: 14, color: color),
                    ),
                  ],
                ),
              )
              : const SizedBox.shrink(),
    );
  }
}
