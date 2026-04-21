import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription.dart';

/// Bottom input bar for the subscription detail screen.
///
/// Pixel-exact match with [CurrentRequestBox] layout:
/// - Container: surfaceLight + borderLight top + space3 padding + SafeArea
/// - TextField: bodySmall, radiusMedium, maxLength 200, counterText ''
/// - Buttons: buttonHeightSmall (40), radiusMedium, buttonSmall font
/// - Row: Outlined(일정 변경) + Filled(메시지 전송)
///
/// Hidden when the subscription is expired or depleted.
class SubscriptionBottomInputBar extends StatelessWidget {
  final Subscription subscription;
  final String viewerRole;
  final TextEditingController messageController;
  final VoidCallback? onSendMessage;
  final VoidCallback? onScheduleChange;
  final VoidCallback? onLessonComplete;
  final VoidCallback? onCancel;
  final bool isBulkMode;

  const SubscriptionBottomInputBar({
    super.key,
    required this.subscription,
    required this.viewerRole,
    required this.messageController,
    this.onSendMessage,
    this.onScheduleChange,
    this.onLessonComplete,
    this.onCancel,
    this.isBulkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (subscription.isExpired || subscription.isDepleted) {
      return const SizedBox.shrink();
    }

    // Matches CurrentRequestBox.build() container exactly
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space3,
        AppSpacing.space3,
        AppSpacing.space3,
        MediaQuery.of(context).padding.bottom + AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Message input — matches CurrentRequestBox TextField exactly
          TextField(
            controller: messageController,
            maxLines: 8,
            minLines: 1,
            maxLength: 200,
            style: AppTypography.bodySmall,
            decoration: InputDecoration(
              hintText: AppStrings.subscriptionMessageHint,
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                borderSide: BorderSide(color: AppColors.inkQuaternary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                borderSide: BorderSide(color: AppColors.inkQuaternary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),

          // Action buttons — matches CurrentRequestBox Row exactly
          Row(
            children: [
              // Schedule change (outlined) — secondary action
              Expanded(
                child: SizedBox(
                  height: AppSpacing.buttonHeightSmall,
                  child: OutlinedButton(
                    onPressed: onScheduleChange,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.inkQuaternary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                      ),
                    ),
                    child: Text(
                      AppStrings.scheduleChangeButton,
                      style: AppTypography.buttonSmall.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),

              // Send message (filled primary) — primary action
              Expanded(
                child: SizedBox(
                  height: AppSpacing.buttonHeightSmall,
                  child: ElevatedButton(
                    onPressed: onSendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.paperAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                      ),
                    ),
                    child: Text(
                      AppStrings.subscriptionSendMessage,
                      style: AppTypography.buttonSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
