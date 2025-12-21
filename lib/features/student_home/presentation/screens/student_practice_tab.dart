import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Student practice tab with practice log and statistics
class StudentPracticeTab extends StatefulWidget {
  const StudentPracticeTab({super.key});

  @override
  State<StudentPracticeTab> createState() => _StudentPracticeTabState();
}

class _StudentPracticeTabState extends State<StudentPracticeTab> {
  DateTime _selectedMonth = DateTime.now();

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.space4,
              AppSpacing.screenPadding,
              0,
            ),
            child: Text('연습 기록', style: AppTypography.headingLarge),
          ),

          const SizedBox(height: AppSpacing.space4),

          // Monthly stats card
          _buildMonthlyStatsCard(),

          const SizedBox(height: AppSpacing.space6),

          // Practice calendar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: _buildPracticeCalendar(),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Repertoire progress
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: _buildRepertoireProgress(),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Practice log
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: _buildPracticeLog(),
          ),

          const SizedBox(height: AppSpacing.space6),
        ],
      ),
    );
  }

  Widget _buildMonthlyStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        children: [
          // Month selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                DateFormat('yyyy년 M월', 'ko').format(_selectedMonth),
                style: AppTypography.headingMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: _selectedMonth.month == DateTime.now().month &&
                        _selectedMonth.year == DateTime.now().year
                    ? null
                    : _nextMonth,
                icon: Icon(
                  Icons.chevron_right,
                  color: _selectedMonth.month == DateTime.now().month &&
                          _selectedMonth.year == DateTime.now().year
                      ? Colors.white38
                      : Colors.white,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('연습 일수', '18일', Icons.calendar_today),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              _buildStatItem('총 연습 시간', '24시간', Icons.timer_outlined),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              _buildStatItem('달성률', '85%', Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: AppSpacing.space1),
        Text(
          value,
          style: AppTypography.headingSmall.copyWith(
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeCalendar() {
    // Get first day of month and days in month
    final firstDayOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday;

    // Mock practice data (day -> completion percentage)
    final practiceData = _mockPracticeData();
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('연습 캘린더', style: AppTypography.headingSmall),
              Row(
                children: [
                  _buildLegendItem(AppColors.practiceGood, '80%+'),
                  const SizedBox(width: AppSpacing.space2),
                  _buildLegendItem(AppColors.practiceNormal, '50%+'),
                  const SizedBox(width: AppSpacing.space2),
                  _buildLegendItem(AppColors.practicePoor, '연습함'),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          // Day headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['일', '월', '화', '수', '목', '금', '토']
                .map((day) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          day,
                          style: AppTypography.caption.copyWith(
                            color: day == '일'
                                ? AppColors.error
                                : day == '토'
                                    ? AppColors.primary
                                    : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: AppSpacing.space2),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 42, // 6 weeks
            itemBuilder: (context, index) {
              final adjustedIndex = index - firstWeekday + 1;
              if (adjustedIndex < 1 || adjustedIndex > daysInMonth) {
                return const SizedBox();
              }

              final day = adjustedIndex;
              final isToday = today.year == _selectedMonth.year &&
                  today.month == _selectedMonth.month &&
                  today.day == day;
              final isFuture = _selectedMonth.year > today.year ||
                  (_selectedMonth.year == today.year &&
                      _selectedMonth.month > today.month) ||
                  (_selectedMonth.year == today.year &&
                      _selectedMonth.month == today.month &&
                      day > today.day);

              final practice = practiceData[day];
              Color? bgColor;
              if (practice != null && !isFuture) {
                if (practice >= 0.8) {
                  bgColor = AppColors.practiceGood;
                } else if (practice >= 0.5) {
                  bgColor = AppColors.practiceNormal;
                } else if (practice > 0) {
                  bgColor = AppColors.practicePoor;
                }
              }

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: bgColor?.withValues(alpha: 0.3) ??
                      (isFuture ? Colors.transparent : AppColors.surfaceSecondaryLight),
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: AppTypography.bodySmall.copyWith(
                      color: isFuture
                          ? AppColors.textTertiaryLight
                          : isToday
                              ? AppColors.primary
                              : AppColors.textPrimaryLight,
                      fontWeight: isToday ? FontWeight.bold : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiaryLight,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRepertoireProgress() {
    final repertoire = [
      _RepertoireItem(
        title: '바흐 파르티타 2번',
        progress: 0.65,
        currentSection: 'Sarabande',
        totalSections: 5,
        completedSections: 3,
      ),
      _RepertoireItem(
        title: '크로이처 에튀드',
        progress: 0.4,
        currentSection: '3번',
        totalSections: 42,
        completedSections: 2,
      ),
      _RepertoireItem(
        title: 'G Major 스케일',
        progress: 0.9,
        currentSection: '3옥타브',
        totalSections: 3,
        completedSections: 3,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('레퍼토리 진행률', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.space3),
          ...repertoire.map((item) => _buildRepertoireItem(item)),
        ],
      ),
    );
  }

  Widget _buildRepertoireItem(_RepertoireItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(item.progress * 100).toInt()}%',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    backgroundColor: AppColors.surfaceSecondaryLight,
                    valueColor: AlwaysStoppedAnimation(
                      item.progress >= 0.8
                          ? AppColors.practiceGood
                          : item.progress >= 0.5
                              ? AppColors.practiceNormal
                              : AppColors.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '${item.completedSections}/${item.totalSections}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '현재: ${item.currentSection}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeLog() {
    final logs = [
      _PracticeLog(
        date: DateTime.now(),
        duration: 85,
        items: ['스케일 15분', '에튀드 20분', '바흐 50분'],
        completion: 1.0,
      ),
      _PracticeLog(
        date: DateTime.now().subtract(const Duration(days: 1)),
        duration: 60,
        items: ['스케일 15분', '바흐 45분'],
        completion: 0.75,
      ),
      _PracticeLog(
        date: DateTime.now().subtract(const Duration(days: 2)),
        duration: 45,
        items: ['스케일 15분', '에튀드 30분'],
        completion: 0.5,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('최근 연습 기록', style: AppTypography.headingSmall),
            TextButton(
              onPressed: () {},
              child: const Text('전체보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        ...logs.map((log) => _buildPracticeLogItem(log)),
      ],
    );
  }

  Widget _buildPracticeLogItem(_PracticeLog log) {
    final dateFormat = DateFormat('M월 d일 (E)', 'ko');
    final isToday = log.date.day == DateTime.now().day &&
        log.date.month == DateTime.now().month;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          // Completion indicator
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: log.completion >= 0.8
                  ? AppColors.practiceGood.withValues(alpha: 0.2)
                  : log.completion >= 0.5
                      ? AppColors.practiceNormal.withValues(alpha: 0.2)
                      : AppColors.practicePoor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${(log.completion * 100).toInt()}%',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: log.completion >= 0.8
                      ? AppColors.practiceGood
                      : log.completion >= 0.5
                          ? AppColors.practiceNormal
                          : AppColors.practicePoor,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.space3),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isToday ? '오늘' : dateFormat.format(log.date),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.textTertiaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${log.duration}분',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  log.items.join(' • '),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.space2),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textTertiaryLight,
          ),
        ],
      ),
    );
  }
}

class _RepertoireItem {
  final String title;
  final double progress;
  final String currentSection;
  final int totalSections;
  final int completedSections;

  _RepertoireItem({
    required this.title,
    required this.progress,
    required this.currentSection,
    required this.totalSections,
    required this.completedSections,
  });
}

class _PracticeLog {
  final DateTime date;
  final int duration;
  final List<String> items;
  final double completion;

  _PracticeLog({
    required this.date,
    required this.duration,
    required this.items,
    required this.completion,
  });
}

Map<int, double> _mockPracticeData() {
  final today = DateTime.now().day;
  return {
    1: 0.8,
    2: 1.0,
    3: 0.6,
    4: 0.0,
    5: 0.9,
    6: 0.7,
    7: 0.5,
    8: 0.8,
    9: 1.0,
    10: 0.3,
    11: 0.0,
    12: 0.9,
    13: 0.8,
    14: 0.6,
    15: 0.7,
    16: 1.0,
    17: 0.8,
    18: 0.9,
    if (today >= 19) 19: 0.75,
    if (today >= 20) 20: 0.5,
    if (today >= 21) 21: 1.0,
  };
}
