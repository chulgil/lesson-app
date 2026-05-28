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
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../auth/auth_facade.dart';
import '../../../practice/presentation/widgets/note_access_active_banner.dart';
import '../../domain/entities/child_profile.dart';
import '../extensions/parent_home_domain_visuals.dart';
import '../providers/child_profile_provider.dart';
import '../providers/parent_dashboard_state_provider.dart';
import '../widgets/assignment_item.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_card.dart';

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

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(childProfilesProvider(parentId));
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
                    const NoteAccessActiveBanner(),

                    const SizedBox(height: AppSpacing.space4),

                    // ── 1순위: 빠른 통계 (이번주 레슨 / 과제 / 스트릭) ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: _buildQuickStats(),
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // ── 2순위: 다음 레슨 ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: _buildUpcomingLesson(),
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // ── 3순위: 이번 주 연습 스트릭 ────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: _buildPracticeStreak(),
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // ── 4순위: 과제 현황 ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: _buildRecentAssignments(),
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // ── 5순위: 입금 상태 ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: _buildPaymentStatus(),
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
      meta: 'VOL. ${DateTime.now().month} · NO. ${DateTime.now().day}',
      trailing: IconButton(
        onPressed: () => _showChildSelector(context, ref, parentId),
        icon: const Icon(Icons.swap_horiz, color: AppColors.ink, size: 22),
        tooltip: '자녀 전환',
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
          Text('${profile.name}의 레슨', style: NotebookTypography.masthead),
          const SizedBox(height: 6),
          Text(
            '${now.month}月 ${now.day}日  ·  ${profile.instrumentLabel}',
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.child_care_outlined,
              size: 80,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space4),
            // Notebook × Score: 빈 상태 헤드라인 (§7.89 3축) — Playfair sectionTitle.
            Text(
              AppStrings.parentHomeNoChildren,
              style: NotebookTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '자녀를 추가하여 레슨 일정과\n연습 현황을 관리해보세요',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            ElevatedButton.icon(
              onPressed: () {
                context.push('${AppRoutes.addChildProfile}?parentId=$parentId');
              },
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.parentHomeAddChild),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                foregroundColor: AppColors.paper,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space6,
                  vertical: AppSpacing.space3,
                ),
              ),
            ),
          ],
        ),
      ),
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
      builder:
          (sheetContext) => Consumer(
            builder: (context, sheetRef, _) {
              final profilesAsync = sheetRef.watch(
                childProfilesProvider(parentId),
              );

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
                      loading:
                          () => const Padding(
                            padding: EdgeInsets.all(AppSpacing.space4),
                            child: CircularProgressIndicator(),
                          ),
                      error:
                          (_, __) => const Padding(
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
                          children:
                              profiles.map((profile) {
                                final isSelected =
                                    selectedChildId == profile.id;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: profile.profileColor,
                                    child: Text(
                                      profile.initial,
                                      style: const TextStyle(
                                        color: AppColors.paper,
                                      ),
                                    ),
                                  ),
                                  title: Text(profile.name),
                                  subtitle: Text(profile.instrumentLabel),
                                  trailing:
                                      isSelected
                                          ? Icon(
                                            Icons.check,
                                            color: AppColors.paperAccent,
                                          )
                                          : null,
                                  onTap: () {
                                    ref
                                        .read(selectedChildIdProvider.notifier)
                                        .state = profile.id;
                                    ref
                                        .read(
                                          selectedChildProfileProvider.notifier,
                                        )
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
                      Text(
                        profile.name,
                        style: AppTypography.headingMedium.copyWith(
                          color: AppColors.paper,
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
                          '만 ${profile.age}세',
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
                        Text(
                          profile.teacherName!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.paper.withValues(alpha: 0.7),
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

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.calendar_today,
            label: AppStrings.parentHomeWeeklyLesson,
            value: '1회',
            color: AppColors.paperAccent,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: StatCard(
            icon: Icons.assignment_turned_in,
            label: AppStrings.parentHomeAssignmentDone,
            value: '4/5',
            color: AppColors.paperOk,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: StatCard(
            icon: Icons.local_fire_department,
            label: AppStrings.parentHomePracticeStreak,
            value: '12일',
            color: AppColors.paperAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingLesson() {
    return SectionCard(
      romanIndex: 0,
      title: '다음 레슨',
      icon: Icons.event,
      child: ListTile(
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
                '28',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.paperAccent,
                ),
              ),
              Text(
                '토',
                style: AppTypography.caption.copyWith(
                  color: AppColors.paperAccent,
                ),
              ),
            ],
          ),
        ),
        title: const Text(AppStrings.parentHomeRegularLesson),
        subtitle: Text(
          '오후 2:00 - 3:00 • 김선생님',
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
            'D-1',
            style: NotebookTypography.indicatorLabel.copyWith(
              color: AppColors.paperOk,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeStreak() {
    // Practice days this week (Mon-Sun)
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final practiceStatus = [true, true, true, true, true, false, false]; // Demo

    return SectionCard(
      romanIndex: 1,
      title: '이번 주 연습',
      icon: Icons.local_fire_department,
      trailing: Text(
        '5일 연습',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.paperOk,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final day = monday.add(Duration(days: index));
          final practiced = practiceStatus[index];
          final isToday = index == today.weekday - 1;
          final isPast = index < today.weekday - 1;
          final dayLabel = ['월', '화', '수', '목', '금', '토', '일'][index];

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
                  color:
                      practiced
                          ? AppColors.paperOk
                          : isToday
                          ? AppColors.paperAccentSoft
                          : isPast
                          ? AppColors.paperAccentSoft
                          : AppColors.paperDark,
                  border:
                      isToday
                          ? Border.all(color: AppColors.paperAccent, width: 2)
                          : null,
                ),
                child: Center(
                  child:
                      practiced
                          ? const Icon(
                            Icons.check,
                            size: 18,
                            color: AppColors.paper,
                          )
                          : Text(
                            '${day.day}',
                            style: AppTypography.bodySmall.copyWith(
                              color:
                                  isToday
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
  }

  Widget _buildRecentAssignments() {
    return SectionCard(
      romanIndex: 2,
      title: '과제 현황',
      icon: Icons.assignment,
      trailing: null,
      child: Column(
        children: const [
          AssignmentItem(
            title: '스케일 연습',
            dueDate: '내일 마감',
            isCompleted: false,
            priority: 'must',
          ),
          ThinRule(),
          AssignmentItem(
            title: '비브라토 연습',
            dueDate: '완료됨',
            isCompleted: true,
            priority: 'should',
          ),
          ThinRule(),
          AssignmentItem(
            title: '모차르트 소나타 1악장',
            dueDate: '2일 남음',
            isCompleted: false,
            priority: 'must',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus() {
    return SectionCard(
      romanIndex: 3,
      title: '입금 상태',
      icon: Icons.payment,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1월 수강료', style: AppTypography.bodyMedium),
                  Text(
                    '입금 예정일: 12/28',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '300,000원',
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.paperAccent,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paperAccentSoft,
                      borderRadius: BorderRadius.zero,
                    ),
                    // "입금대기(후불)" = 시스템 자동 긴급도 인디케이터 → Tier 4 Pretendard
                    // italic (README §1.1 4계층, §7.127 Gaegu 회피).
                    child: Text(
                      '입금대기(후불)',
                      style: NotebookTypography.indicatorLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          // TODO: payment verification flow — removed NO-OP button
        ],
      ),
    );
  }
}
