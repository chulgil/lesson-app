import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../../../../features/settings/presentation/providers/teacher_settings_provider.dart';
import '../providers/unified_lesson_request_providers.dart';
import '../widgets/decline_bottom_sheet.dart';
import '../widgets/request_list_item.dart';
import '../widgets/unified_approval_bottom_sheet.dart';

/// Screen for teachers to view and respond to lesson requests.
///
/// v4.0: Unified requests only (legacy removed).
class LessonRequestsScreen extends ConsumerWidget {
  final String teacherId;

  const LessonRequestsScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(teacherUnifiedRequestsProvider(teacherId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: requestsAsync.when(
          loading: () => const Text(AppStrings.lessonRequestTitle),
          error: (_, __) => const Text(AppStrings.lessonRequestTitle),
          data: (requests) {
            final pendingCount = requests
                .where((r) => r.status == UnifiedRequestStatus.pending)
                .length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.lessonRequestTitle),
                if (pendingCount > 0)
                  Text(
                    AppStrings.lessonRequestPending(pendingCount),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: AppSpacing.iconXL, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text(AppStrings.requestLoadError,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondaryLight)),
              const SizedBox(height: AppSpacing.space4),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Text(
                AppStrings.noHistory,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondaryLight),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
            itemCount: requests.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: AppSpacing.space4),
            itemBuilder: (context, index) {
              final request = requests[index];
              return RequestListItem(
                request: request,
                studentName: AppStrings.student,
                onTap: () => context.push(
                  AppRoutes.requestDetail
                      .replaceFirst(':id', request.id),
                  extra: {'viewerRole': 'teacher'},
                ),
              );
            },
          );
        },
      ),
    );
  }
}
