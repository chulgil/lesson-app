import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../auth/auth_facade.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../gamification/gamification_facade.dart'
    show effectiveStreakProvider;
import '../../../practice/practice_facade.dart';
import '../../../practice/practice_ui_facade.dart';
import '../../../practice_journal/practice_journal.dart';
import '../../../students/students_facade.dart';
import '../../../subscription/subscription_facade.dart';
import '../../domain/entities/child_profile.dart';
import '../extensions/parent_home_domain_visuals.dart';
import '../providers/child_profile_provider.dart';
import '../providers/parent_dashboard_state_provider.dart';
import '../widgets/assignment_item.dart';
import '../widgets/section_card.dart';
import '../../../../core/widgets/stat_card.dart';

/// Parent dashboard tab showing child overview
class ParentDashboardTab extends ConsumerWidget {
  const ParentDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch selected child profile
    final parentId = ref.watch(currentUserIdProvider);
    final selectedProfile = ref.watch(selectedChildProfileProvider);
    final childrenAsync = ref.watch(childProfilesProvider(parentId));

    // Auto-select first child if none selected
    if (selectedProfile == null) {
      childrenAsync.whenData((profiles) {
        if (profiles.isNotEmpty) {
          Future.microtask(() {
            ref
                .read(selectedChildProfileProvider.notifier)
                .select(profiles.first);
            ref.read(selectedChildIdProvider.notifier).state =
                profiles.first.id;
          });
        }
      });
    }

    return ColoredBox(
      color: AppColors.paper,
      child: SafeArea(
        bottom: false,
        child: childrenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(AppStrings.errorOccurred)),
          data: (profiles) {
            if (profiles.isEmpty) {
              return _buildEmptyState(context, parentId);
            }

            final profile = selectedProfile ?? profiles.first;

            final linkedStudentId = profile.linkedStudentId;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(childProfilesProvider(parentId));
                if (linkedStudentId != null) {
                  ref.invalidate(lessonsByStudentProvider(linkedStudentId));
                  ref.invalidate(practiceStreakProvider(linkedStudentId));
                  ref.invalidate(weeklyPracticeItemsProvider(linkedStudentId));
                  ref.invalidate(
                    practiceItemsByStudentProvider(linkedStudentId),
                  );
                  ref.invalidate(studentSubscriptionsProvider(linkedStudentId));
                  ref.invalidate(
                    activeStudentMembershipsProvider(linkedStudentId),
                  );
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Masthead: Playfair eyebrow + 자녀 전환 아이콘 ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: _buildMasthead(context, ref, parentId),
                    ),

                    // ── Programme Title: "오늘의 자녀" + 자녀 이름 ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: _buildProgrammeTitle(context, profile),
                    ),

                    // ── 0순위: 자녀 정보 히어로 카드 ──────────────
                    _buildChildHeader(context, profile),

                    // ── G21/#402: 노트 일시 접근 동의 활성 배너 (조건부) ──
                    // 선택 자녀(linkedStudentId) 스코프 — 타 자녀 배너 노출 방지 (#586)
                    NoteAccessActiveBanner(studentId: profile.linkedStudentId),

                    const SizedBox(height: AppSpacing.space4),

                    // ── 1순위: 빠른 통계 (이번주 레슨 / 과제 / 스트릭) ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: _QuickStatsSection(profile: profile),
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // ── 2순위: 다음 레슨 ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: _UpcomingLessonSection(profile: profile),
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // ── 3순위: 이번 주 연습 스트릭 ────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: _PracticeStreakSection(profile: profile),
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // ── 연습장 카드: 자녀 이달 연습 도장 미리보기 ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: _PracticeJournalSection(profile: profile),
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // ── 4순위: 과제 현황 ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: _RecentAssignmentsSection(profile: profile),
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // ── 5순위: 입금 상태 ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: _PaymentStatusSection(profile: profile),
                    ),

                    const SizedBox(height: AppSpacing.space5),

                    // ── Fine. 페이지 종지부 ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: _buildFineFooter(context),
                    ),

                    const SizedBox(height: AppSpacing.space6),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Masthead — Notebook × Score 상단 헤더.
  /// 좌측: "LESSONAZA" (Playfair eyebrow)
  /// 우측: 자녀 전환 IconButton
  Widget _buildMasthead(BuildContext context, WidgetRef ref, String parentId) {
    return NotebookMasthead(
      eyebrow: 'LESSONAZA',
      // H2 — 로고는 배경으로 물러나고 본문 글자가 먼저 읽히게 한다.
      eyebrowStyle: NotebookTypography.wordmark,
      meta: 'VOL. ${DateTime.now().month} · NO. ${DateTime.now().day}',
      trailing: IconButton(
        onPressed: () => _showChildSelector(context, ref, parentId),
        icon: const Icon(Icons.swap_horiz, color: AppColors.ink, size: 22),
        tooltip: AppStrings.parentHomeSwitchChild,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }

  /// Programme Title — "Parent's Programme" + 자녀 이름 + 날짜·인사.
  Widget _buildProgrammeTitle(BuildContext context, ChildProfile profile) {
    final now = DateTime.now();
    final dayLabel = _englishWeekday(now.weekday);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Programme for $dayLabel',
            style: NotebookTypography.mastheadLabel,
          ),
          const SizedBox(height: 4),
          Text(AppStrings.parentHomeChildLessonsTitleFormat(profile.name), style: NotebookTypography.masthead),
          const SizedBox(height: 6),
          Text(
            // H3 — 한자식 날짜(8月 5日)를 한글 표기로 통일. 날짜는 이 줄에서 1회만.
            '${formatDateMDKorean(now)}  ·  ${profile.instrumentLabel}',
            style: NotebookTypography.mastheadDate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.space3),
          ThinRule(),
        ],
      ),
    );
  }

  /// "Fine." 푸터 — 악보 종지부 + 자녀 프로필 관리 링크.
  Widget _buildFineFooter(BuildContext context) {
    return Column(
      children: [
        const ThinRule(),
        const SizedBox(height: AppSpacing.space3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Fine.', style: NotebookTypography.fine),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  static const _englishWeekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _englishWeekday(int weekday) {
    final idx = (weekday - 1).clamp(0, 6);
    return _englishWeekdays[idx];
  }

  Widget _buildEmptyState(BuildContext context, String parentId) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        EmptyStateWidget(
          icon: Icons.child_care_outlined,
          title: AppStrings.parentHomeNoChildren,
          subtitle: AppStrings.parentHomeNoChildrenDesc,
          actionLabel: AppStrings.parentHomeAddChild,
          actionIcon: Icons.add,
          onAction: () {
            context.push('${AppRoutes.addChildProfile}?parentId=$parentId');
          },
        ),
        const SizedBox(height: AppSpacing.space3),
        // #631 보조 CTA — 초대코드 입력 (EmptyStateWidget 1액션 제약으로 외부 유지).
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.parentInviteCode),
          icon: const Icon(Icons.qr_code, size: 18),
          label: const Text(AppStrings.parentHomeInviteCode),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.paperAccent,
            side: const BorderSide(color: AppColors.paperAccent),
            minimumSize: const Size(0, AppSpacing.buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
          ),
        ),
      ],
    );
  }

  void _showChildSelector(
    BuildContext context,
    WidgetRef ref,
    String parentId,
  ) {
    final selectedChildId = ref.read(selectedChildIdProvider);

    showNotebookModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Consumer(
        builder: (context, sheetRef, _) {
          final profilesAsync = sheetRef.watch(childProfilesProvider(parentId));

          return Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle indicator
                const BottomSheetHandle(
                  margin: EdgeInsets.only(bottom: AppSpacing.space4),
                ),
                // Notebook × Score: 바텀시트 헤더 (§7.27) — Playfair sectionTitle.
                Text(
                  AppStrings.parentHomeChildSelect,
                  style: NotebookTypography.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.space4),
                // Child list from provider
                profilesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.space4),
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, __) => const Padding(
                    padding: EdgeInsets.all(AppSpacing.space4),
                    child: Text(AppStrings.errorOccurred),
                  ),
                  data: (profiles) {
                    if (profiles.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.space4),
                        child: Column(
                          children: [
                            Icon(
                              Icons.child_care_outlined,
                              size: 48,
                              color: AppColors.inkTertiary,
                            ),
                            const SizedBox(height: AppSpacing.space2),
                            Text(
                              AppStrings.parentHomeNoChildren,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: profiles.map((profile) {
                        final isSelected = selectedChildId == profile.id;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: profile.profileColor,
                            child: Text(
                              profile.initial,
                              style: const TextStyle(color: AppColors.paper),
                            ),
                          ),
                          title: Text(profile.name),
                          subtitle: Text(profile.instrumentLabel),
                          trailing: isSelected
                              ? Icon(Icons.check, color: AppColors.paperAccent)
                              : null,
                          onTap: () {
                            ref.read(selectedChildIdProvider.notifier).state =
                                profile.id;
                            ref
                                .read(selectedChildProfileProvider.notifier)
                                .select(profile);
                            Navigator.pop(sheetContext);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.space4),
                // Add child button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.push(
                      '${AppRoutes.addChildProfile}?parentId=$parentId',
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.parentHomeAddChildShort),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChildHeader(BuildContext context, ChildProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            profile.profileColor,
            profile.profileColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.paper.withValues(alpha: 0.2),
              child: Text(
                profile.initial,
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.paper,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.name,
                          style: AppTypography.headingMedium.copyWith(
                            color: AppColors.paper,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paper.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Text(
                          AppStrings.parentHomeAgeFormat(profile.age),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.paper,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          profile.instrumentIcon,
                          size: 14,
                          color: AppColors.paper,
                        ),
                        const SizedBox(width: AppSpacing.space1),
                        Text(
                          '${profile.instrumentLabel} • ${profile.levelLabel}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.paper,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profile.teacherName != null) ...[
                    const SizedBox(height: AppSpacing.space1),
                    Row(
                      children: [
                        // Notebook × Score: 다크 히어로 카드 위 선생님 이름 — Material
                        // Colors.white70 대신 paper 70% alpha 로 Notebook 팔레트 유지.
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppColors.paper.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: AppSpacing.space1),
                        Flexible(
                          child: Text(
                            profile.teacherName!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.paper.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns the nearest future scheduled lesson, or null.
Lesson? _nextScheduledLesson(List<Lesson> lessons) {
  final now = DateTime.now();
  final upcoming =
      lessons
          .where(
            (l) =>
                l.status == LessonStatus.scheduled &&
                !l.isArchived &&
                l.date.isAfter(now.subtract(const Duration(days: 1))),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  return upcoming.isEmpty ? null : upcoming.first;
}

/// Returns active subscriptions (positive remaining) for the student.
List<Subscription> _activeSubscriptions(List<Subscription> subscriptions) {
  return subscriptions
      .where((s) => s.status == SubscriptionStatus.active)
      .toList();
}

/// Empty placeholder for unlinked / no-data sections.
class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
      ),
    );
  }
}

/// 빠른 통계 — 이번주 레슨 / 과제 완료 / 연습 스트릭 (실데이터).
class _QuickStatsSection extends ConsumerWidget {
  const _QuickStatsSection({required this.profile});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId = profile.linkedStudentId;
    if (studentId == null) {
      return const _SectionEmpty(message: AppStrings.parentHomeNotLinked);
    }

    final lessonsAsync = ref.watch(lessonsByStudentProvider(studentId));
    final weeklyItemsAsync = ref.watch(weeklyPracticeItemsProvider(studentId));
    // 표시 숫자는 학생 화면과 같은 SSOT — 학부모가 보는 자녀 스트릭이
    // 학생 본인 화면과 달라지지 않게 (streak_ssot.md §7.1).
    final streakAsync = ref.watch(effectiveStreakProvider(studentId));

    final weeklyLessonCount = lessonsAsync.maybeWhen(
      data: (lessons) {
        final now = DateTime.now();
        final monday = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 7));
        return lessons
            .where(
              (l) =>
                  !l.isArchived &&
                  l.date.isAfter(monday.subtract(const Duration(seconds: 1))) &&
                  l.date.isBefore(sunday),
            )
            .length;
      },
      orElse: () => null,
    );

    final assignmentLabel = weeklyItemsAsync.maybeWhen(
      data: (items) {
        if (items.isEmpty) return '0/0';
        final done = items.where((i) => i.isCompleted).length;
        return '$done/${items.length}';
      },
      orElse: () => null,
    );

    final streakLabel = streakAsync.maybeWhen(
      data: (streak) =>
          AppStrings.parentHomeDaysFormat(streak.effectiveCurrentStreak),
      orElse: () => null,
    );

    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.calendar_today,
            title: AppStrings.parentHomeWeeklyLesson,
            value: weeklyLessonCount == null ? '-' : AppStrings.parentHomeLessonCountFormat(weeklyLessonCount),
            color: AppColors.paperAccent,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: StatCard(
            icon: Icons.assignment_turned_in,
            title: AppStrings.parentHomeAssignmentDone,
            value: assignmentLabel ?? '-',
            color: AppColors.paperOk,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: StatCard(
            icon: Icons.local_fire_department,
            title: AppStrings.parentHomePracticeStreak,
            value: streakLabel ?? '-',
            color: AppColors.paperAccent,
          ),
        ),
      ],
    );
  }
}

/// 다음 레슨 — 가장 가까운 미래 scheduled 레슨 (실데이터).
class _UpcomingLessonSection extends ConsumerWidget {
  const _UpcomingLessonSection({required this.profile});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId = profile.linkedStudentId;
    if (studentId == null) {
      return SectionCard(
        romanIndex: 0,
        title: AppStrings.parentHomeNextLesson,
        icon: Icons.event,
        child: const _SectionEmpty(message: AppStrings.parentHomeNotLinked),
      );
    }

    final lessonsAsync = ref.watch(lessonsByStudentProvider(studentId));

    return SectionCard(
      romanIndex: 0,
      title: AppStrings.parentHomeNextLesson,
      icon: Icons.event,
      child: lessonsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.space3),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) =>
            const _SectionEmpty(message: AppStrings.errorOccurred),
        data: (lessons) {
          final next = _nextScheduledLesson(lessons);
          if (next == null) {
            return const _SectionEmpty(
              message: AppStrings.noUpcomingLessons,
            );
          }
          final dDay = DateTime(next.date.year, next.date.month, next.date.day)
              .difference(
                DateTime.now().copyWith(
                  hour: 0,
                  minute: 0,
                  second: 0,
                  millisecond: 0,
                  microsecond: 0,
                ),
              )
              .inDays;
          final teacherName = next.teacherName ?? profile.teacherName;
          final tile = ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.paperAccentSoft.withValues(alpha: 0.3),
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${next.date.day}',
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.paperAccent,
                    ),
                  ),
                  Text(
                    LessonDateUtils.getWeekdayNameKorean(next.date.weekday),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paperAccent,
                    ),
                  ),
                ],
              ),
            ),
            title: const Text(AppStrings.parentHomeRegularLesson),
            subtitle: Text(
              teacherName == null
                  ? next.startTime
                  : '${next.startTime} • $teacherName',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: AppColors.paperDark,
                borderRadius: BorderRadius.zero,
              ),
              // "D-N" = 시스템 자동 임박 인디케이터 → Tier 4 Pretendard italic
              // (README §1.1 4계층, §7.127 Gaegu 회피). paperOk 유지.
              child: Text(
                dDay <= 0 ? 'D-DAY' : 'D-$dDay',
                style: NotebookTypography.indicatorLabel.copyWith(
                  color: AppColors.paperOk,
                ),
              ),
            ),
          );
          // H5 — 다음 레슨은 시간에 민감한 정보라 종이 위에서 먼저 잡혀야 한다.
          // 세피아 앰버로 채우고 테두리를 둘러 다른 섹션과 구분한다.
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.amberLight,
              border: Border.all(color: AppColors.paperTrial),
            ),
            child: tile,
          );
        },
      ),
    );
  }
}

/// 이번 주 연습 — practiceStreak 기반 (실데이터).
class _PracticeStreakSection extends ConsumerWidget {
  const _PracticeStreakSection({required this.profile});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId = profile.linkedStudentId;
    if (studentId == null) {
      return SectionCard(
        romanIndex: 1,
        title: AppStrings.parentHomeThisWeekPractice,
        icon: Icons.local_fire_department,
        child: const _SectionEmpty(message: AppStrings.parentHomeNotLinked),
      );
    }

    // 여기는 "어느 요일에 실제로 연습했는가" 를 그리므로 raw SSOT 를 쓴다 —
    // 동결된 날은 연습한 날이 아니라 practiced 로 칠하면 안 된다 (§7).
    final streakAsync = ref.watch(practiceStreakProvider(studentId));
    final today = DateTime.now();
    final monday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));

    return streakAsync.when(
      loading: () => SectionCard(
        romanIndex: 1,
        title: AppStrings.parentHomeThisWeekPractice,
        icon: Icons.local_fire_department,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.space3),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => SectionCard(
        romanIndex: 1,
        title: AppStrings.parentHomeThisWeekPractice,
        icon: Icons.local_fire_department,
        child: const _SectionEmpty(message: AppStrings.errorOccurred),
      ),
      data: (streak) {
        // Derive which weekdays were practiced from streak window.
        // currentStreak counts consecutive days ending at lastPracticeDate.
        final lastDate = streak.lastPracticeDate;
        final practicedDays = <int>{}; // 0=Mon ... 6=Sun
        if (lastDate != null && streak.currentStreak > 0) {
          final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
          for (var i = 0; i < streak.currentStreak; i++) {
            final d = lastDay.subtract(Duration(days: i));
            if (!d.isBefore(monday) &&
                d.isBefore(monday.add(const Duration(days: 7)))) {
              practicedDays.add(d.weekday - 1);
            }
          }
        }

        return SectionCard(
          romanIndex: 1,
          title: AppStrings.parentHomeThisWeekPractice,
          icon: Icons.local_fire_department,
          trailing: Text(
            AppStrings.parentHomePracticedDaysFormat(practicedDays.length),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.paperOk,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = monday.add(Duration(days: index));
              final practiced = practicedDays.contains(index);
              final isToday = index == today.weekday - 1;
              final isPast = index < today.weekday - 1;
              final dayLabel = LessonDateUtils.getWeekdayNameKorean(index + 1);

              return Column(
                children: [
                  Text(
                    dayLabel,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  // §7.132: round → 사각 day cell (Notebook 메타포).
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: practiced
                          ? AppColors.paperOk
                          : isToday
                          ? AppColors.paperAccentSoft
                          : isPast
                          ? AppColors.paperAccentSoft
                          : AppColors.paperDark,
                      border: isToday
                          ? Border.all(color: AppColors.paperAccent, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: practiced
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: AppColors.paper,
                            )
                          : Text(
                              '${day.day}',
                              style: AppTypography.bodySmall.copyWith(
                                color: isToday
                                    ? AppColors.paperAccent
                                    : AppColors.inkSecondary,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}

/// 과제 현황 — 이번 주 연습 항목 (실데이터).
class _RecentAssignmentsSection extends ConsumerWidget {
  const _RecentAssignmentsSection({required this.profile});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId = profile.linkedStudentId;
    if (studentId == null) {
      return SectionCard(
        romanIndex: 2,
        title: AppStrings.parentHomeAssignmentStatus,
        icon: Icons.assignment,
        child: const _SectionEmpty(message: AppStrings.parentHomeNotLinked),
      );
    }

    final itemsAsync = ref.watch(weeklyPracticeItemsProvider(studentId));

    return SectionCard(
      romanIndex: 2,
      title: AppStrings.parentHomeAssignmentStatus,
      icon: Icons.assignment,
      child: itemsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.space3),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) =>
            const _SectionEmpty(message: AppStrings.errorOccurred),
        data: (items) {
          if (items.isEmpty) {
            return const _SectionEmpty(
              message: AppStrings.parentHomeNoAssignment,
            );
          }
          final sorted = [...items]
            ..sort(
              (a, b) => a.priority.sortOrder.compareTo(b.priority.sortOrder),
            );
          final visible = sorted.take(3).toList();
          final children = <Widget>[];
          for (var i = 0; i < visible.length; i++) {
            final item = visible[i];
            children.add(
              AssignmentItem(
                title: item.title,
                dueDate: item.isCompleted
                    ? AppStrings.parentHomeCompletedLabel
                    : _priorityLabel(item.priority),
                isCompleted: item.isCompleted,
                priority: item.priority.name,
              ),
            );
            if (i < visible.length - 1) children.add(const ThinRule());
          }
          return Column(children: children);
        },
      ),
    );
  }

  String _priorityLabel(PracticePriority priority) {
    switch (priority) {
      case PracticePriority.must:
        return AppStrings.parentHomePriorityMust;
      case PracticePriority.should:
        return AppStrings.parentHomePriorityShould;
      case PracticePriority.could:
        return AppStrings.parentHomePriorityCould;
    }
  }
}

/// 수강권 잔여 — 활성 수강권 잔여 회차 (실데이터).
class _PaymentStatusSection extends ConsumerWidget {
  const _PaymentStatusSection({required this.profile});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId = profile.linkedStudentId;
    if (studentId == null) {
      return SectionCard(
        romanIndex: 3,
        title: AppStrings.parentHomeRemainingLesson,
        icon: Icons.confirmation_number_outlined,
        child: const _SectionEmpty(message: AppStrings.parentHomeNotLinked),
      );
    }

    final subscriptionsAsync = ref.watch(
      studentSubscriptionsProvider(studentId),
    );
    // §3.2.4: 학부모 — 자녀의 paymentNotified 제안 표시
    final proposalsAsync = ref.watch(activeStudentProposalsProvider(studentId));

    return SectionCard(
      romanIndex: 3,
      title: AppStrings.parentHomeRemainingLesson,
      icon: Icons.confirmation_number_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Remaining lessons row
          subscriptionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.space3),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) =>
                const _SectionEmpty(message: AppStrings.errorOccurred),
            data: (subscriptions) {
              final active = _activeSubscriptions(subscriptions);
              if (active.isEmpty) {
                return const _SectionEmpty(
                  message: AppStrings.noSubscriptionsRegisteredTitle,
                );
              }
              final totalRemaining = active.fold<int>(
                0,
                (sum, s) => sum + (s.remainingLessons ?? 0),
              );
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.parentHomeRemainingLesson,
                    style: AppTypography.bodyMedium,
                  ),
                  Text(
                    AppStrings.parentHomeLessonCountFormat(totalRemaining),
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.paperAccent,
                    ),
                  ),
                ],
              );
            },
          ),
          // §3.2.4: paymentNotified 대기 제안 — 학부모 가시성
          proposalsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (proposals) {
              final waiting = proposals
                  .where((p) => p.status == ProposalStatus.paymentNotified)
                  .toList();
              if (waiting.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.space3),
                  const ThinRule(),
                  const SizedBox(height: AppSpacing.space3),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.inkSecondary,
                      ),
                      const SizedBox(width: AppSpacing.space1),
                      Text(
                        AppStrings.parentHomePaymentPendingSection,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  ...waiting.map(
                    (p) => _PaymentNotifiedProposalRow(
                      proposal: p,
                      onTap: () => context.push(
                        AppRoutes.proposalDetail.replaceFirst(':id', p.id),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 연습장 카드 섹션 — 선택된 자녀의 이달 연습 도장 미리보기.
///
/// childProfileId 는 ChildProfile.id (앱 내부 프로필 ID). linkedStudentId 가
/// 없어도 도장 카드는 렌더되고 내부적으로 빈 상태를 처리한다.
class _PracticeJournalSection extends StatelessWidget {
  const _PracticeJournalSection({required this.profile});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context) {
    return PracticeJournalCard(
      childProfileId: profile.id,
      role: JournalRole.guardian,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PracticeJournalScreen(
              childProfileId: profile.id,
              role: JournalRole.guardian,
            ),
          ),
        );
      },
    );
  }
}

/// §3.2.4: Single paymentNotified proposal row for parent dashboard.
class _PaymentNotifiedProposalRow extends StatelessWidget {
  const _PaymentNotifiedProposalRow({
    required this.proposal,
    required this.onTap,
  });

  final SubscriptionProposal proposal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.04),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 16,
              color: AppColors.inkSecondary,
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                AppStrings.parentHomePaymentPendingBody,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: AppColors.inkTertiary),
          ],
        ),
      ),
    );
  }
}
