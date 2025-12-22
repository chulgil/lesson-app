import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/practice_repertoire.dart';
import '../../../../providers/practice_repertoire/practice_repertoire_crud_provider.dart';

/// Repertoire detail screen with date settings and aggregated stats
class RepertoireDetailScreen extends ConsumerStatefulWidget {
  final String repertoireId;
  final String studentId;

  const RepertoireDetailScreen({
    super.key,
    required this.repertoireId,
    required this.studentId,
  });

  @override
  ConsumerState<RepertoireDetailScreen> createState() =>
      _RepertoireDetailScreenState();
}

class _RepertoireDetailScreenState
    extends ConsumerState<RepertoireDetailScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final repertoireAsync = ref.watch(repertoireProvider(widget.repertoireId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('레퍼토리 상세'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveChanges,
              child: const Text('저장'),
            ),
        ],
      ),
      body: repertoireAsync.when(
        data: (repertoire) {
          if (repertoire == null) {
            return const Center(child: Text('레퍼토리를 찾을 수 없습니다'));
          }
          _startDate ??= repertoire.startDate;
          _endDate ??= repertoire.endDate;
          return _buildContent(repertoire);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류: $error')),
      ),
    );
  }

  Widget _buildContent(PracticeRepertoire repertoire) {
    // Calculate aggregated stats
    final stats = _calculateStats(repertoire);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Repertoire Name
          Text(
            repertoire.name,
            style: AppTypography.headingLarge,
          ),
          if (repertoire.description != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              repertoire.description!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.space6),

          // Date Range Section
          _buildDateRangeSection(),

          const SizedBox(height: AppSpacing.space6),

          // Stats Cards
          _buildStatsSection(stats),

          const SizedBox(height: AppSpacing.space6),

          // Sections List
          _buildSectionsSection(repertoire),
        ],
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space2),
              Text('연습 기간', style: AppTypography.headingSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),

          // Start Date
          _buildDateRow(
            label: '시작일',
            date: _startDate,
            onTap: () => _selectDate(isStartDate: true),
          ),

          const SizedBox(height: AppSpacing.space3),

          // End Date
          _buildDateRow(
            label: '종료일',
            date: _endDate,
            placeholder: '설정 안함 (계속 진행)',
            onTap: () => _selectDate(isStartDate: false),
            canClear: _endDate != null,
            onClear: () {
              setState(() {
                _endDate = null;
                _hasChanges = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow({
    required String label,
    required DateTime? date,
    String? placeholder,
    required VoidCallback onTap,
    bool canClear = false,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondaryLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const Spacer(),
            Text(
              date != null
                  ? '${date.year}년 ${date.month}월 ${date.day}일'
                  : placeholder ?? '선택',
              style: AppTypography.bodyMedium.copyWith(
                color: date != null
                    ? AppColors.textPrimaryLight
                    : AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            if (canClear)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.textSecondaryLight,
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondaryLight,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(_RepertoireStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('연습 통계', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.repeat,
                label: '총 연습 횟수',
                value: '${stats.totalPracticeCount}회',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer,
                label: '총 연습 시간',
                value: _formatDuration(stats.totalPracticeSeconds),
                color: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.mic,
                label: '총 녹음',
                value: '${stats.totalRecordings}개',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: _buildStatCard(
                icon: Icons.library_music,
                label: '섹션 수',
                value: '${stats.sectionCount}개',
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.space2),
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsSection(PracticeRepertoire repertoire) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('섹션 목록', style: AppTypography.headingSmall),
            TextButton.icon(
              onPressed: () {
                context.push(
                  '${AppRoutes.addSection}?repertoireId=${widget.repertoireId}&studentId=${widget.studentId}',
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('추가'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        if (repertoire.sections.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.space6),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.library_music_outlined,
                    size: 48,
                    color: AppColors.textTertiaryLight,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    '섹션이 없습니다',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    '연습할 구간을 추가해보세요',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...repertoire.sections.map((section) => _SectionListTile(
                section: section,
                repertoireId: widget.repertoireId,
                studentId: widget.studentId,
              )),
      ],
    );
  }

  void _selectDate({required bool isStartDate}) {
    final initialDate =
        (isStartDate ? _startDate : _endDate) ?? DateTime.now();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('취소'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    isStartDate ? '시작일 선택' : '종료일 선택',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text('확인'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: initialDate,
                  mode: CupertinoDatePickerMode.date,
                  minimumDate: isStartDate ? null : _startDate,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      if (isStartDate) {
                        _startDate = newDate;
                        // Adjust end date if needed
                        if (_endDate != null && _endDate!.isBefore(newDate)) {
                          _endDate = newDate;
                        }
                      } else {
                        _endDate = newDate;
                      }
                      _hasChanges = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final repertoire =
        ref.read(repertoireProvider(widget.repertoireId)).valueOrNull;
    if (repertoire == null) return;

    final updatedRepertoire = PracticeRepertoire(
      id: repertoire.id,
      studentId: repertoire.studentId,
      name: repertoire.name,
      description: repertoire.description,
      startDate: _startDate ?? DateTime.now(),
      endDate: _endDate,
      createdAt: repertoire.createdAt,
      sections: repertoire.sections,
    );

    await ref
        .read(repertoireCrudProvider.notifier)
        .updateRepertoire(updatedRepertoire);

    setState(() {
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장되었습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  _RepertoireStats _calculateStats(PracticeRepertoire repertoire) {
    int totalPracticeCount = 0;
    int totalPracticeSeconds = 0;
    int totalRecordings = 0;

    for (final section in repertoire.sections) {
      totalPracticeCount += section.practiceCount;
      totalPracticeSeconds += section.totalPracticeSeconds;
      totalRecordings += section.recordings.length;
    }

    return _RepertoireStats(
      totalPracticeCount: totalPracticeCount,
      totalPracticeSeconds: totalPracticeSeconds,
      totalRecordings: totalRecordings,
      sectionCount: repertoire.sections.length,
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds초';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes분';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '$hours시간 $minutes분' : '$hours시간';
    }
  }
}

class _RepertoireStats {
  final int totalPracticeCount;
  final int totalPracticeSeconds;
  final int totalRecordings;
  final int sectionCount;

  _RepertoireStats({
    required this.totalPracticeCount,
    required this.totalPracticeSeconds,
    required this.totalRecordings,
    required this.sectionCount,
  });
}

/// Section list tile for repertoire detail
class _SectionListTile extends StatelessWidget {
  final PracticeSection section;
  final String repertoireId;
  final String studentId;

  const _SectionListTile({
    required this.section,
    required this.repertoireId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: InkWell(
        onTap: () {
          context.push(
            '${AppRoutes.sectionDetail.replaceFirst(':id', section.id)}'
            '?repertoireId=$repertoireId&studentId=$studentId',
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space3),
          child: Row(
            children: [
              // Section info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.pieceName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      section.measureRangeText,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Stats
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Practice count
                  _buildMiniStat(
                    icon: Icons.repeat,
                    value: '${section.practiceCount}',
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  // Recordings
                  _buildMiniStat(
                    icon: Icons.mic,
                    value: '${section.recordings.length}',
                  ),
                ],
              ),

              const SizedBox(width: AppSpacing.space2),
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiaryLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondaryLight),
          const SizedBox(width: 2),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
