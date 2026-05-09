import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../providers/unified_lesson_request_providers.dart';
import '../widgets/request_list_item.dart';

/// Screen for teachers to view and respond to lesson requests.
///
/// v4.0: Unified requests only (legacy removed).
class LessonRequestsScreen extends ConsumerWidget {
  final String teacherId;

  const LessonRequestsScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(teacherUnifiedRequestsProvider(teacherId));

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: const NotebookDetailAppBar(
        title: AppStrings.lessonRequestTitle,
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, __) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: AppSpacing.iconXL,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    AppStrings.requestLoadError,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text(AppStrings.goBack),
                  ),
                ],
              ),
            ),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Text(
                AppStrings.noHistory,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.space3,
            ),
            itemCount: requests.length,
            separatorBuilder:
                (_, __) => const SizedBox(height: AppSpacing.space2),
            itemBuilder: (context, index) {
              final request = requests[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.inkQuaternary),
                ),
                child: RequestListItem(
                  request: request,
                  studentName: AppStrings.student,
                  onTap:
                      () => context.push(
                        AppRoutes.requestDetail.replaceFirst(':id', request.id),
                        extra: {'viewerRole': 'teacher'},
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
