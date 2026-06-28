import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/core/widgets/notebook/thin_rule.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
import '../../../auth/auth_facade.dart';
import '../../../relationship/domain/entities/relationship_status.dart';
import '../../../relationship/domain/entities/teacher_student_relation.dart';
import '../../../relationship/relationship_facade.dart';
import '../../../search/search_facade.dart' show teacherProvider;
import '../../domain/entities/manual_teacher.dart';
import '../extensions/manual_teacher_visuals.dart';
import '../providers/manual_teacher_provider.dart';

/// Screen showing the student's connected teachers
class MyTeachersScreen extends ConsumerWidget {
  const MyTeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId = ref.watch(currentUserIdProvider);
    final relationsAsync = ref.watch(studentRelationshipsProvider(studentId));
    final manualTeachersAsync = ref.watch(manualTeacherNotifierProvider);

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.studentHomeMyTeachers,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App teachers section
            _buildAppTeachersSection(context, ref, relationsAsync),

            const SizedBox(height: AppSpacing.space8),

            // Manual teachers section
            _buildManualTeachersSection(context, manualTeachersAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildAppTeachersSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TeacherStudentRelation>> relationsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified, size: 18, color: AppColors.paperAccent),
            const SizedBox(width: AppSpacing.space2),
            // Notebook × Score: 카테고리 섹션 제목은 Playfair sectionTitle
            // (§7.17). '앱 선생님' 은 정적 그룹 헤더.
            Text(
              '앱 선생님',
              style: NotebookTypography.sectionTitle.copyWith(
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          '앱을 통해 연결된 선생님',
          style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(height: AppSpacing.space3),
        relationsAsync.when(
          data: (relations) {
            if (relations.isEmpty) {
              return _buildAppTeachersEmpty(context);
            }
            final sorted = [...relations]
              ..sort((a, b) {
                final aActive = a.status == RelationshipStatus.active ? 0 : 1;
                final bActive = b.status == RelationshipStatus.active ? 0 : 1;
                if (aActive != bActive) return aActive.compareTo(bActive);
                return (b.lastLessonAt ?? b.createdAt).compareTo(
                  a.lastLessonAt ?? a.createdAt,
                );
              });
            return Column(
              children: sorted
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                      child: _AppTeacherCard(relation: r),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.space8),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Text(
              AppStrings.studentHomeDataLoadError,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppTeachersEmpty(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: SizedBox(
        height: 220,
        child: EmptyStateWidget(
          icon: Icons.school_outlined,
          title: AppStrings.studentHomeAppTeacherEmpty,
          subtitle: AppStrings.studentHomeSearchTeacherHint,
          actionLabel: AppStrings.studentHomeFindTeacher,
          actionIcon: Icons.search,
          onAction: () => context.push(AppRoutes.teacherSearch),
        ),
      ),
    );
  }

  Widget _buildManualTeachersSection(
    BuildContext context,
    AsyncValue<List<ManualTeacher>> manualTeachersAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_add_outlined, size: 18, color: AppColors.ink),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              // Notebook × Score: 카테고리 섹션 제목은 Playfair sectionTitle
              // (§7.17). '직접 등록한 선생님' 은 정적 그룹 헤더.,
              child: Text(
                AppStrings.studentHomeManualTeacherSection,
                style: NotebookTypography.sectionTitle.copyWith(
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          AppStrings.studentHomeManualTeacherHint,
          style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(height: AppSpacing.space3),
        manualTeachersAsync.when(
          data: (teachers) {
            if (teachers.isEmpty) {
              return _buildManualTeachersEmpty(context);
            }
            return Column(
              children: [
                ...teachers.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                    child: _ManualTeacherCard(teacher: t),
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                _buildAddManualTeacherButton(context),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.space8),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Text(
              AppStrings.studentHomeDataLoadError,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualTeachersEmpty(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: SizedBox(
        height: 200,
        child: EmptyStateWidget(
          icon: Icons.person_add_outlined,
          title: AppStrings.studentHomeManualTeacherEmpty,
          actionLabel: AppStrings.studentHomeManualTeacherRegister,
          actionIcon: Icons.add,
          onAction: () => context.push(AppRoutes.addManualTeacher),
        ),
      ),
    );
  }

  Widget _buildAddManualTeacherButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.push(AppRoutes.addManualTeacher),
        icon: const Icon(Icons.add, size: 18),
        label: const Text(AppStrings.studentHomeManualTeacherRegister),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: BorderSide(color: AppColors.inkQuaternary),
        ),
      ),
    );
  }
}

// ============================================================
// App Teacher Card
// ============================================================

class _AppTeacherCard extends ConsumerWidget {
  final TeacherStudentRelation relation;

  const _AppTeacherCard({required this.relation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = relation.status == RelationshipStatus.active;
    final teacherAsync = ref.watch(teacherProvider(relation.teacherId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(
          color: isActive ? AppColors.ink : AppColors.inkQuaternary,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.teacherDetail.replaceFirst(':id', relation.teacherId),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isActive
                          ? AppColors.ink
                          : AppColors.paperDark,
                      child: Icon(
                        Icons.person,
                        size: 28,
                        color: isActive
                            ? AppColors.paper
                            : AppColors.inkTertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  teacherAsync.maybeWhen(
                                    data: (t) =>
                                        t?.name ??
                                        AppStrings.myTeachersUnknownTeacher,
                                    orElse: () =>
                                        AppStrings.myTeachersUnknownTeacher,
                                  ),
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.space2),
                              _buildStatusBadge(),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            teacherAsync.when(
                              data: (t) => (t == null || t.instruments.isEmpty)
                                  ? AppStrings.myTeachersInstrumentUnset
                                  : t.instrumentsText,
                              loading: () =>
                                  AppStrings.myTeachersInstrumentLoading,
                              error: (_, __) =>
                                  AppStrings.myTeachersInstrumentUnset,
                            ),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.inkTertiary),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                const ThinRule(),
                const SizedBox(height: AppSpacing.space3),
                Row(
                  children: [
                    _buildStat(
                      Icons.school_outlined,
                      '총 레슨',
                      '${relation.totalLessonCount}회',
                    ),
                    const SizedBox(width: AppSpacing.space6),
                    if (relation.lastLessonAt != null)
                      _buildStat(
                        Icons.calendar_today_outlined,
                        '마지막 레슨',
                        _formatRelativeDate(relation.lastLessonAt!),
                      ),
                    const SizedBox(width: AppSpacing.space6),
                    _buildStat(
                      Icons.access_time_outlined,
                      '레슨 기간',
                      _formatDuration(relation.createdAt),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final label = relation.status.displayName;
    final color = switch (relation.status) {
      RelationshipStatus.active => AppColors.paperOk,
      RelationshipStatus.expired => AppColors.inkTertiary,
      RelationshipStatus.trialBooked => AppColors.paperAccent,
      RelationshipStatus.past => AppColors.inkTertiary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1)),
      child: Text(
        label,
        style: AppTypography.captionSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.inkTertiary),
            const SizedBox(width: AppSpacing.space1),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatRelativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return '오늘';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}주 전';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}개월 전';
    return '${diff.inDays ~/ 365}년 전';
  }

  String _formatDuration(DateTime startDate) {
    final months = DateTime.now().difference(startDate).inDays ~/ 30;
    if (months < 1) return '1개월 미만';
    if (months < 12) return '$months개월';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (remainingMonths == 0) return '$years년';
    return '$years년 $remainingMonths개월';
  }
}

// ============================================================
// Manual Teacher Card
// ============================================================

class _ManualTeacherCard extends ConsumerWidget {
  final ManualTeacher teacher;

  const _ManualTeacherCard({required this.teacher});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppRoutes.addManualTeacher, extra: teacher),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Row(
              children: [
                // Avatar with profile color
                CircleAvatar(
                  radius: 24,
                  backgroundColor: teacher.profileColor.withValues(alpha: 0.15),
                  child: Text(
                    teacher.initial,
                    style: AppTypography.headingMedium.copyWith(
                      color: teacher.profileColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),

                // Teacher info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.name,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Row(
                        children: [
                          if (teacher.instrument != null) ...[
                            Icon(
                              Icons.music_note,
                              size: 14,
                              color: AppColors.inkTertiary,
                            ),
                            const SizedBox(width: AppSpacing.space1),
                            Text(
                              teacher.instrument!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          ],
                          if (teacher.instrument != null &&
                              teacher.phone != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space2,
                              ),
                              child: Text(
                                '|',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.inkTertiary,
                                ),
                              ),
                            ),
                          if (teacher.phone != null) ...[
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppColors.inkTertiary,
                            ),
                            const SizedBox(width: AppSpacing.space1),
                            Text(
                              teacher.phone!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          ],
                          if (teacher.instrument == null &&
                              teacher.phone == null)
                            Text(
                              '직접 등록',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.inkTertiary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // C6: 행 관리 액션(편집·삭제) = 우→좌 스와이프 (trailing 메뉴 대체).
    return SwipeActionTile(
      actions: [
        SwipeAction(
          label: AppStrings.studentHomeEditAction,
          icon: Icons.edit_outlined,
          onPressed: () =>
              context.push(AppRoutes.addManualTeacher, extra: teacher),
        ),
        SwipeAction(
          label: AppStrings.delete,
          icon: Icons.delete_outline,
          tone: SwipeActionTone.destructive,
          onPressed: () => _confirmDelete(context, ref),
        ),
      ],
      child: card,
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showNotebookDialog(
      context: context,
      titleWidget: const Text(AppStrings.studentHomeDeleteTeacher),
      content: Text('${teacher.name} 선생님을 삭제하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              await ref
                  .read(manualTeacherNotifierProvider.notifier)
                  .delete(teacher.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${teacher.name} 선생님이 삭제되었습니다'),
                    backgroundColor: AppColors.paperOk,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      AppStrings.studentHomeDeleteFailedRetry,
                    ),
                    backgroundColor: AppColors.paperAccent,
                  ),
                );
              }
            }
          },
          child: Text(
            '삭제',
            style: const TextStyle(color: AppColors.paperAccent),
          ),
        ),
      ],
    );
  }
}
