import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/entities.dart';
import '../providers/practice_goal_provider.dart';
import '../widgets/goal/goal_setting_chips.dart';

/// Screen for setting practice goals
class PracticeGoalSettingScreen extends ConsumerStatefulWidget {
  final String studentId;

  const PracticeGoalSettingScreen({
    super.key,
    required this.studentId,
  });

  @override
  ConsumerState<PracticeGoalSettingScreen> createState() =>
      _PracticeGoalSettingScreenState();
}

class _PracticeGoalSettingScreenState
    extends ConsumerState<PracticeGoalSettingScreen> {
  // Daily goals
  int? _dailyTimeMinutes;
  int? _dailySectionCount;

  // Weekly goals
  int? _weeklyTimeMinutes;
  int? _weeklyDayCount;

  bool _isLoading = true;
  bool _hasChanges = false;
  PracticeGoal? _existingGoal;

  @override
  void initState() {
    super.initState();
    _loadExistingGoal();
  }

  Future<void> _loadExistingGoal() async {
    final goal = await ref.read(practiceGoalProvider(widget.studentId).future);
    if (goal != null && mounted) {
      setState(() {
        _existingGoal = goal;
        _dailyTimeMinutes = goal.dailyTimeMinutes;
        _dailySectionCount = goal.dailySectionCount;
        _weeklyTimeMinutes = goal.weeklyTimeMinutes;
        _weeklyDayCount = goal.weeklyDayCount;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateDailyTime(int? value) {
    setState(() {
      _dailyTimeMinutes = value;
      _hasChanges = true;
    });
  }

  void _updateDailySection(int? value) {
    setState(() {
      _dailySectionCount = value;
      _hasChanges = true;
    });
  }

  void _updateWeeklyTime(int? value) {
    setState(() {
      _weeklyTimeMinutes = value;
      _hasChanges = true;
    });
  }

  void _updateWeeklyDay(int? value) {
    setState(() {
      _weeklyDayCount = value;
      _hasChanges = true;
    });
  }

  Future<void> _saveGoal() async {
    final goal = PracticeGoal(
      id: _existingGoal?.id ?? const Uuid().v4(),
      studentId: widget.studentId,
      dailyTimeMinutes: _dailyTimeMinutes,
      dailySectionCount: _dailySectionCount,
      weeklyTimeMinutes: _weeklyTimeMinutes,
      weeklyDayCount: _weeklyDayCount,
      isActive: true,
      createdAt: _existingGoal?.createdAt ?? DateTime.now(),
      updatedAt: _existingGoal != null ? DateTime.now() : null,
    );

    await ref.read(practiceGoalCrudProvider.notifier).saveGoal(goal);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연습 목표가 저장되었습니다')),
      );
      context.pop();
    }
  }

  bool get _hasAnyGoal =>
      _dailyTimeMinutes != null ||
      _dailySectionCount != null ||
      _weeklyTimeMinutes != null ||
      _weeklyDayCount != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('연습 목표 설정'),
        actions: [
          if (_hasChanges && _hasAnyGoal)
            TextButton(
              onPressed: _saveGoal,
              child: Text(
                '저장',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space3),
                    decoration: BoxDecoration(
                      color: AppColors.info.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      border: Border.all(color: AppColors.info.withAlpha(50)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.info, size: 20),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Text(
                            '목표를 설정하면 목표 달성 시에만 스트릭이 유지됩니다',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space6),

                  // Daily goals section
                  _buildSectionHeader(
                    icon: Icons.today,
                    title: '일일 목표',
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  GoalSettingChips(
                    label: '연습 시간',
                    icon: Icons.timer,
                    options: const [15, 30, 45, 60],
                    unit: '분',
                    selectedValue: _dailyTimeMinutes,
                    onChanged: _updateDailyTime,
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  GoalSettingChips(
                    label: '완료 섹션 수',
                    icon: Icons.check_box,
                    options: const [1, 2, 3, 5],
                    unit: '개',
                    selectedValue: _dailySectionCount,
                    onChanged: _updateDailySection,
                  ),
                  const SizedBox(height: AppSpacing.space6),

                  // Weekly goals section
                  _buildSectionHeader(
                    icon: Icons.date_range,
                    title: '주간 목표',
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  GoalSettingChips(
                    label: '총 연습 시간',
                    icon: Icons.timer,
                    options: const [60, 120, 180, 300],
                    unit: '분',
                    selectedValue: _weeklyTimeMinutes,
                    onChanged: _updateWeeklyTime,
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  GoalSettingChips(
                    label: '연습 일수',
                    icon: Icons.calendar_today,
                    options: const [3, 4, 5, 7],
                    unit: '일',
                    selectedValue: _weeklyDayCount,
                    onChanged: _updateWeeklyDay,
                  ),
                  const SizedBox(height: AppSpacing.space6),

                  // Summary
                  if (_hasAnyGoal) ...[
                    _buildSummary(),
                    const SizedBox(height: AppSpacing.space6),
                  ],

                  // Reset button
                  if (_existingGoal != null && _hasAnyGoal)
                    Center(
                      child: TextButton.icon(
                        onPressed: _showResetConfirmation,
                        icon: Icon(Icons.refresh, color: AppColors.error),
                        label: Text(
                          '목표 초기화',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.space4),
                ],
              ),
            ),
      bottomNavigationBar: _hasChanges
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: FilledButton(
                  onPressed: _hasAnyGoal ? _saveGoal : null,
                  child: const Text('저장'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: AppSpacing.space2),
        Text(
          title,
          style: AppTypography.headingSmall,
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '목표 요약',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          if (_dailyTimeMinutes != null || _dailySectionCount != null) ...[
            Text(
              '일일 목표',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (_dailyTimeMinutes != null)
                  _buildSummaryChip('⏱️ ${_formatMinutes(_dailyTimeMinutes!)}'),
                if (_dailyTimeMinutes != null && _dailySectionCount != null)
                  const SizedBox(width: AppSpacing.space2),
                if (_dailySectionCount != null)
                  _buildSummaryChip('✅ $_dailySectionCount개 섹션'),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
          ],

          if (_weeklyTimeMinutes != null || _weeklyDayCount != null) ...[
            Text(
              '주간 목표',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (_weeklyTimeMinutes != null)
                  _buildSummaryChip('⏱️ ${_formatMinutes(_weeklyTimeMinutes!)}'),
                if (_weeklyTimeMinutes != null && _weeklyDayCount != null)
                  const SizedBox(width: AppSpacing.space2),
                if (_weeklyDayCount != null)
                  _buildSummaryChip('📅 $_weeklyDayCount일'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '$hours시간 $mins분' : '$hours시간';
    }
    return '$minutes분';
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('목표 초기화'),
        content: const Text('모든 목표 설정을 초기화할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _dailyTimeMinutes = null;
                _dailySectionCount = null;
                _weeklyTimeMinutes = null;
                _weeklyDayCount = null;
                _hasChanges = true;
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }
}
