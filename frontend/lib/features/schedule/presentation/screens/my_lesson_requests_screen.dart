import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/unified_lesson_request_providers.dart';
import '../widgets/request_list_item.dart';

/// Screen for students to view their sent lesson requests.
///
/// v4.0: Uses unified requests only (legacy removed).
class MyLessonRequestsScreen extends ConsumerWidget {
  final String studentId;

  const MyLessonRequestsScreen({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(studentUnifiedRequestsProvider(studentId));
    final teacherNames = ref.watch(teacherNameMapProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: const Text(AppStrings.lessonRequestTitle),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            AppStrings.requestLoadError,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondaryLight),
          ),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Text(
                AppStrings.noHistory,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textTertiaryLight),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.space3,
            ),
            itemCount: requests.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.space2),
            itemBuilder: (context, index) {
              final request = requests[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: RequestListItem(
                  request: request,
                  studentName: AppStrings.student,
                  teacherName: teacherNames[request.teacherId],
                  viewerRole: 'student',
                  onTap: () => context.push(
                    AppRoutes.requestDetail.replaceFirst(':id', request.id),
                    extra: {'viewerRole': 'student'},
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
