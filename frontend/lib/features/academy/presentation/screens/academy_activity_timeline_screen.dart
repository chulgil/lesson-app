import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/academy_activity_log.dart';
import '../providers/academy_activity_provider.dart';

class AcademyActivityTimelineScreen extends ConsumerWidget {
  const AcademyActivityTimelineScreen({
    required this.academyId,
    required this.actorMemberId,
    this.actorName = '',
    super.key,
  });

  final String academyId;
  final String actorMemberId;
  final String actorName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(
      academyActivityLogsProvider(academyId, actorMemberId),
    );

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.academyActivityTimeline,
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Text(
                AppStrings.noActivityFound,
                style: AppTypography.bodyMedium,
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(AppSpacing.space3),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return AcademyActivityTimelineItem(log: logs[index]);
            },
          );
        },
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return Center(
            child: Text(
              AppStrings.errorLoadingActivity,
              style: AppTypography.bodyMedium,
            ),
          );
        },
      ),
    );
  }
}

class AcademyActivityTimelineItem extends StatelessWidget {
  const AcademyActivityTimelineItem({required this.log, super.key});

  final AcademyActivityLog log;

  bool get _isRecentlyChanged {
    final now = DateTime.now();
    final diff = now.difference(log.createdAt);
    return diff.inHours < 12;
  }

  Color _getActionTypeColor() {
    return switch (log.actionType) {
      'lesson_created' => AppColors.profileBlue,
      'subscription_issued' => AppColors.profileGreen,
      'student_enrolled' => AppColors.profilePurple,
      'lesson_completed' => AppColors.amber,
      'payment_confirmed' => AppColors.profileGreen,
      'schedule_changed' => AppColors.profileOrange,
      'note_added' => AppColors.profileIndigo,
      'lesson_request_accepted' => AppColors.profileTeal,
      'makeup_recorded' => AppColors.profilePink,
      _ => AppColors.scheduleMutedAccent,
    };
  }

  String _getActionTypeLabel() {
    return switch (log.actionType) {
      'lesson_created' => AppStrings.activityTypeLessonCreated,
      'subscription_issued' => AppStrings.activityTypeSubscriptionIssued,
      'student_enrolled' => AppStrings.activityTypeStudentEnrolled,
      'lesson_completed' => AppStrings.activityTypeLessonCompleted,
      'payment_confirmed' => AppStrings.activityTypePaymentConfirmed,
      'schedule_changed' => AppStrings.activityTypeScheduleChanged,
      'note_added' => AppStrings.activityTypeNoteAdded,
      'lesson_request_accepted' => AppStrings.activityTypeLessonRequestAccepted,
      'makeup_recorded' => AppStrings.activityTypeMakeupRecorded,
      _ => AppStrings.activityTypeUnknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getActionTypeColor();
    const dotSize = 12.0;
    const lineHeight = 40.0;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot column
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Dot with border for highlight
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: typeColor,
                    shape: BoxShape.circle,
                    border:
                        _isRecentlyChanged
                            ? Border.all(
                              color: typeColor.withValues(alpha: 0.5),
                              width: 4,
                            )
                            : null,
                  ),
                ),
                // Vertical line (except for last item)
                SizedBox(
                  height: lineHeight,
                  child: Center(
                    child: Container(
                      width: 2,
                      color: AppColors.scheduleMutedAccent.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content card column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card with activity details
                Container(
                  padding: EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color:
                        _isRecentlyChanged
                            ? AppColors.amberLight
                            : AppColors.paper,
                    border: Border.all(
                      color:
                          _isRecentlyChanged
                              ? AppColors.amber
                              : AppColors.scheduleMutedAccent.withValues(
                                alpha: 0.2,
                              ),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: type label + timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Action type badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.space2,
                              vertical: AppSpacing.space1,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                            ),
                            child: Text(
                              _getActionTypeLabel(),
                              style: AppTypography.caption.copyWith(
                                color: typeColor,
                              ),
                            ),
                          ),
                          // Timestamp
                          Text(
                            formatRelativeTime(log.createdAt),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.scheduleMutedAccent,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.space2),
                      // Description
                      Text(log.description, style: AppTypography.bodyMedium),
                      SizedBox(height: AppSpacing.space2),
                      // Footer: actor name + exact timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            log.actorName,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.scheduleMutedAccent,
                            ),
                          ),
                          Text(
                            formatDateTimeDotPadded(log.createdAt),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.scheduleMutedAccent,
                            ),
                          ),
                        ],
                      ),
                      // Recent activity badge
                      if (_isRecentlyChanged)
                        Padding(
                          padding: EdgeInsets.only(top: AppSpacing.space2),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.space2,
                              vertical: AppSpacing.space1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.1),
                            ),
                            child: Text(
                              AppStrings.recentlyChanged,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
