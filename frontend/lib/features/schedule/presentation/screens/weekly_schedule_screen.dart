import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';

/// Legacy-compatible screen for weekly schedule configuration.
///
/// The previous architecture expected this screen path, so this wrapper keeps
/// compatibility with contract tests and existing route references while preserving
/// the current active availability UI surface behavior.
class WeeklyScheduleScreen extends ConsumerWidget {
  final String? teacherId;

  const WeeklyScheduleScreen({super.key, this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (teacherId == null || teacherId!.isEmpty) {
      return NotebookScreenScaffold(
        appBar: const NotebookDetailAppBar(
          title: AppStrings.weeklyScheduleSetting,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space5),
            child: EmptyStateWidget(
              icon: Icons.calendar_today,
              title: AppStrings.weeklyScheduleSetting,
              subtitle: '주간 스케줄 화면은 선생님 계정에서만 연결됩니다.',
            ),
          ),
        ),
      );
    }

    // TODO: 실제 주간 스케줄 관리 화면은 TeacherAvailabilityScreen으로
    // 통합되어 있으나, 호환성을 위해 별도 엔트리포인트를 유지한다.
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.weeklyScheduleSetting,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.space5),
          child: Text(
            '주간 스케줄은 교사 휴무/시간표 관리 화면에서 관리할 수 있습니다.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
        ),
      ),
    );
  }
}
