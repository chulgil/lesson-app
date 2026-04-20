import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../domain/entities/child_profile.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../providers/child_profile_provider.dart';
import '../widgets/assignment_item.dart';
import '../widgets/section_card.dart';
import '../widgets/stat_card.dart';

/// Selected child provider for parent dashboard
final selectedChildIdProvider = StateProvider<String?>((ref) => null);

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('학부모 홈'),
        centerTitle: true,
        actions: [
          // Child selector button
          IconButton(
            onPressed: () => _showChildSelector(context, ref, parentId),
            icon: const Icon(Icons.swap_horiz),
            tooltip: '자녀 전환',
          ),
        ],
      ),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
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
                  // Child info header
                  _buildChildHeader(context, profile),

                  const SizedBox(height: AppSpacing.space4),

                  // Quick stats
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: _buildQuickStats(),
                  ),

                  const SizedBox(height: AppSpacing.space6),

                  // Upcoming lesson
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: _buildUpcomingLesson(),
                  ),

                  const SizedBox(height: AppSpacing.space6),

                  // Practice streak
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: _buildPracticeStreak(),
                  ),

                  const SizedBox(height: AppSpacing.space6),

                  // Recent assignments
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: _buildRecentAssignments(),
                  ),

                  const SizedBox(height: AppSpacing.space6),

                  // Payment status
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: _buildPaymentStatus(),
                  ),

                  const SizedBox(height: AppSpacing.space8),
                ],
              ),
            ),
          );
        },
      ),
    );
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
              color: AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text('등록된 자녀가 없습니다', style: AppTypography.headingSmall),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '자녀를 추가하여 레슨 일정과\n연습 현황을 관리해보세요',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            ElevatedButton.icon(
              onPressed: () {
                context.push('${AppRoutes.addChildProfile}?parentId=$parentId');
              },
              icon: const Icon(Icons.add),
              label: const Text('자녀 추가하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                    Text('자녀 선택', style: AppTypography.headingMedium),
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
                            child: Text('오류가 발생했습니다.'),
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
                                  color: AppColors.textTertiaryLight,
                                ),
                                const SizedBox(height: AppSpacing.space2),
                                Text(
                                  '등록된 자녀가 없습니다',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondaryLight,
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
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  title: Text(profile.name),
                                  subtitle: Text(profile.instrumentLabel),
                                  trailing:
                                      isSelected
                                          ? Icon(
                                            Icons.check,
                                            color: AppColors.primary,
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
                      label: const Text('자녀 추가'),
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
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                profile.initial,
                style: AppTypography.headingLarge.copyWith(color: Colors.white),
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
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMedium,
                          ),
                        ),
                        child: Text(
                          '만 ${profile.age}세',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusLarge,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          profile.instrumentIcon,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${profile.instrumentLabel} • ${profile.levelLabel}',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profile.teacherName != null) ...[
                    const SizedBox(height: AppSpacing.space1),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profile.teacherName!,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white70,
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
            label: '이번주 레슨',
            value: '1회',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: StatCard(
            icon: Icons.assignment_turned_in,
            label: '과제 완료',
            value: '4/5',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: StatCard(
            icon: Icons.local_fire_department,
            label: '연습 스트릭',
            value: '12일',
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingLesson() {
    return SectionCard(
      title: '다음 레슨',
      icon: Icons.event,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '28',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text(
                '토',
                style: AppTypography.caption.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
        title: const Text('정규 레슨'),
        subtitle: Text(
          '오후 2:00 - 3:00 • 김선생님',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space1,
          ),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Text(
            'D-1',
            style: AppTypography.caption.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
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
      title: '이번 주 연습',
      icon: Icons.local_fire_department,
      trailing: Text(
        '5일 연습',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.success,
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
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      practiced
                          ? AppColors.success
                          : isToday
                          ? AppColors.primaryLight
                          : isPast
                          ? AppColors.errorLight
                          : AppColors.surfaceSecondaryLight,
                  shape: BoxShape.circle,
                  border:
                      isToday
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                ),
                child: Center(
                  child:
                      practiced
                          ? const Icon(
                            Icons.check,
                            size: 18,
                            color: Colors.white,
                          )
                          : Text(
                            '${day.day}',
                            style: AppTypography.bodySmall.copyWith(
                              color:
                                  isToday
                                      ? AppColors.primary
                                      : AppColors.textSecondaryLight,
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
      title: '과제 현황',
      icon: Icons.assignment,
      trailing: TextButton(onPressed: () {}, child: const Text('전체보기')),
      child: Column(
        children: const [
          AssignmentItem(
            title: '스케일 연습',
            dueDate: '내일 마감',
            isCompleted: false,
            priority: 'must',
          ),
          Divider(height: 1),
          AssignmentItem(
            title: '비브라토 연습',
            dueDate: '완료됨',
            isCompleted: true,
            priority: 'should',
          ),
          Divider(height: 1),
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
      title: '결제 현황',
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
                    '결제 기한: 12/28',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
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
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                    child: Text(
                      '미결제',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () {}, child: const Text('결제하기')),
          ),
        ],
      ),
    );
  }
}
