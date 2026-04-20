import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../domain/entities/child_profile.dart';
import '../../../../features/parent_home/presentation/providers/user_profile_provider.dart';
import '../widgets/profile_switcher.dart';

/// Dashboard for unconnected children (practice/metronome only)
///
/// Features available:
/// - Practice recording (time-based)
/// - Metronome
///
/// Features NOT available:
/// - Repertoire (requires teacher)
/// - Lesson scheduling (requires teacher)
/// - Assignments (requires teacher)
class UnconnectedChildDashboard extends ConsumerWidget {
  const UnconnectedChildDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChild = ref.watch(activeChildProfileProvider);

    if (activeChild == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DebugWrapper(
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          title: const ProfileSwitcher(),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showFindTeacherDialog(context),
              tooltip: '선생님 찾기',
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChildHeader(activeChild),
                const SizedBox(height: AppSpacing.space6),
                _buildFeatureCards(context, activeChild),
                const SizedBox(height: AppSpacing.space6),
                _buildTeacherConnectionBanner(context),
                const SizedBox(height: AppSpacing.space6),
                _buildPracticeHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildHeader(ChildProfile child) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: child.profileColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          child: Center(
            child: Text(
              child.initial,
              style: AppTypography.headingLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: child.profileColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    child.name,
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: child.connectionStatus.color.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          child.connectionStatus.icon,
                          size: 12,
                          color: child.connectionStatus.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          child.connectionStatus.label,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w500,
                            color: child.connectionStatus.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${child.instrumentLabel} · ${child.levelLabel}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCards(BuildContext context, ChildProfile child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘의 연습',
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                title: '연습 기록',
                subtitle: '시간 기반 연습',
                icon: Icons.timer,
                color: AppColors.primary,
                onTap: () => _startPractice(context, child),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
          ],
        ),
      ],
    );
  }

  Widget _buildTeacherConnectionBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.space2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: const Icon(
                  Icons.school,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '선생님과 연결하세요',
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '레퍼토리, 레슨 예약, 숙제 확인이 가능해집니다',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showFindTeacherDialog(context),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('선생님 찾기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _enterInviteCode(context),
                  icon: const Icon(Icons.qr_code, size: 18),
                  label: const Text('초대코드 입력'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '이번 주 연습',
              style: AppTypography.headingMedium.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to practice history
              },
              child: const Text('전체보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        _buildWeeklyPracticeGrid(),
      ],
    );
  }

  Widget _buildWeeklyPracticeGrid() {
    // Get the current week dates
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        final isToday =
            date.day == now.day &&
            date.month == now.month &&
            date.year == now.year;
        final isPast = date.isBefore(DateTime(now.year, now.month, now.day));

        // TODO: Replace with actual practice data from repository
        // Using index-based stub to avoid dead_code warning until data is connected
        final hasPractice = index < 0; // Will be: practiceData[date] != null

        return Column(
          children: [
            Text(
              weekDays[index],
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    isToday
                        ? AppColors.primary
                        : hasPractice
                        ? AppColors.success.withValues(alpha: 0.1)
                        : isPast
                        ? AppColors.surfaceSecondaryLight
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border:
                    isToday
                        ? null
                        : Border.all(
                          color:
                              hasPractice
                                  ? AppColors.success
                                  : AppColors.borderLight,
                          width: hasPractice ? 2 : 1,
                        ),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color:
                        isToday
                            ? Colors.white
                            : hasPractice
                            ? AppColors.success
                            : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _startPractice(BuildContext context, ChildProfile child) {
    // TODO: Navigate to time-based practice screen for unconnected child
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${child.name}의 연습을 시작합니다'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showFindTeacherDialog(BuildContext context) {
    // TODO: Navigate to teacher search
    context.push(AppRoutes.teacherSearch);
  }

  void _enterInviteCode(BuildContext context) {
    // TODO: Show invite code input dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('초대코드 입력'),
            content: const TextField(
              decoration: InputDecoration(
                hintText: '선생님에게 받은 코드를 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Process invite code
                  Navigator.pop(context);
                },
                child: const Text('연결'),
              ),
            ],
          ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              title,
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
