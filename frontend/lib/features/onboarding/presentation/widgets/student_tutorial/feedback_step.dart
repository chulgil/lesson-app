import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_strings.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

class FeedbackStep extends StatefulWidget {
  final bool completed;
  final VoidCallback onComplete;

  const FeedbackStep({
    super.key,
    required this.completed,
    required this.onComplete,
  });

  @override
  State<FeedbackStep> createState() => _FeedbackStepState();
}

class _FeedbackStepState extends State<FeedbackStep> {
  late bool _isExpanded;
  late bool _hasCompletedOnce;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.completed;
    _hasCompletedOnce = widget.completed;
  }

  void _toggleCard() {
    setState(() {
      _isExpanded = !_isExpanded;

      // Call onComplete only on first expansion
      if (!_hasCompletedOnce && _isExpanded) {
        _hasCompletedOnce = true;
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Guidance text
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          child: Text(
            AppStrings.feedbackStepGuide,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.space2),

        // Feedback card
        GestureDetector(
          key: const ValueKey('student_tutorial_feedback_card'),
          onTap: _toggleCard,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: AppSpacing.space3),
              decoration: BoxDecoration(
                color: _isExpanded ? AppColors.paperDark : AppColors.paper,
                border: Border.all(color: AppColors.inkQuaternary),
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card header (always visible)
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.space3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '박지선 선생님 · 6월 1일',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.inkSecondary,
                                ),
                              ),
                              SizedBox(height: AppSpacing.space1),
                              Text(
                                _isExpanded
                                    ? '오늘 G major 스케일 연습이 많이 좋아졌어요. 손목 힘이 안정적이고 음정도 정확합니다.'
                                    : '스케일 연습이 많이 좋아졌어요…',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.ink,
                                ),
                                maxLines: _isExpanded ? null : 1,
                                overflow:
                                    _isExpanded
                                        ? TextOverflow.visible
                                        : TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppSpacing.space2),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.inkTertiary,
                        ),
                      ],
                    ),
                  ),

                  // Expanded content
                  if (_isExpanded) ...[
                    Container(height: 0.5, color: AppColors.inkQuaternary),
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.space3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Assignment section
                          Text(
                            '다음 시간까지 과제',
                            style: AppTypography.button.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.space1),
                          Container(
                            padding: EdgeInsets.all(AppSpacing.space2),
                            decoration: BoxDecoration(
                              color: AppColors.paperAccentSoft,
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Text(
                              'D major 스케일 연습',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          SizedBox(height: AppSpacing.space3),

                          // Next lesson section
                          Text(
                            '다음 레슨',
                            style: AppTypography.button.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.space1),
                          Text(
                            '6월 8일 (월) 19:00',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.paperOk,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
