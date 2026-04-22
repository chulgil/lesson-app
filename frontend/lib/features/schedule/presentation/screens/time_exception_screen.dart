import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../domain/entities/teacher_availability.dart';
import '../providers/teacher_availability_providers.dart';

/// Screen for managing time exceptions (holidays, vacations, additional slots)
class TimeExceptionScreen extends ConsumerStatefulWidget {
  const TimeExceptionScreen({super.key});

  @override
  ConsumerState<TimeExceptionScreen> createState() =>
      _TimeExceptionScreenState();
}

class _TimeExceptionScreenState extends ConsumerState<TimeExceptionScreen> {
  @override
  Widget build(BuildContext context) {
    final teacherId = ref.watch(currentUserIdProvider);
    final availabilityAsync = ref.watch(teacherAvailabilityProvider(teacherId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('휴무 및 예외 설정'),
        backgroundColor: AppColors.paperDark,
        elevation: 0,
      ),
      backgroundColor: AppColors.paperDark,
      body: availabilityAsync.when(
        data: (availability) => _buildContent(availability),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExceptionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('휴무 추가'),
      ),
    );
  }

  Widget _buildContent(TeacherAvailability? availability) {
    if (availability == null) {
      return _buildEmptyState();
    }

    final exceptions = availability.exceptions;
    if (exceptions.isEmpty) {
      return _buildEmptyState();
    }

    // Sort by date
    final sortedExceptions = List<TimeException>.from(exceptions)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    // Separate upcoming and past
    final now = DateTime.now();
    final upcoming =
        sortedExceptions
            .where(
              (e) => e.endDate.isAfter(now.subtract(const Duration(days: 1))),
            )
            .toList();
    final past =
        sortedExceptions
            .where(
              (e) => e.endDate.isBefore(now.subtract(const Duration(days: 1))),
            )
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          _buildInfoCard(),

          const SizedBox(height: AppSpacing.space6),

          // Upcoming exceptions
          if (upcoming.isNotEmpty) ...[
            Text('예정된 휴무', style: AppTypography.headingSmall),
            const SizedBox(height: AppSpacing.space3),
            ...upcoming.map((e) => _buildExceptionCard(e)),
          ],

          // Past exceptions
          if (past.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space6),
            Text(
              '지난 휴무',
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            ...past.map((e) => _buildExceptionCard(e, isPast: true)),
          ],

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 24, color: AppColors.ink),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '휴무 설정 안내',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '휴무일로 설정된 날짜는 학생들에게 예약 가능 시간으로 표시되지 않습니다.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExceptionCard(TimeException exception, {bool isPast = false}) {
    final icon = _getExceptionIcon(exception.type);
    final color =
        isPast ? AppColors.inkTertiary : _getExceptionColor(exception.type);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        title: Text(
          _formatDateRange(exception.startDate, exception.endDate),
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isPast ? AppColors.inkTertiary : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exception.type.displayName,
              style: AppTypography.bodySmall.copyWith(
                color: isPast ? AppColors.inkTertiary : color,
              ),
            ),
            if (exception.reason != null && exception.reason!.isNotEmpty)
              Text(
                exception.reason!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
          ],
        ),
        trailing:
            isPast
                ? null
                : IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.inkSecondary,
                  onPressed: () => _confirmDelete(exception),
                ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 64, color: AppColors.inkTertiary),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '설정된 휴무가 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '아래 버튼을 눌러 휴무일을 추가하세요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final teacherId = ref.read(currentUserIdProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.paperAccent,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '데이터를 불러올 수 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          TextButton(
            onPressed: () {
              ref.invalidate(teacherAvailabilityProvider(teacherId));
            },
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }

  IconData _getExceptionIcon(ExceptionType type) {
    switch (type) {
      case ExceptionType.holiday:
        return Icons.event_busy;
      case ExceptionType.vacation:
        return Icons.beach_access;
      case ExceptionType.additionalSlot:
        return Icons.add_circle_outline;
    }
  }

  Color _getExceptionColor(ExceptionType type) {
    switch (type) {
      case ExceptionType.holiday:
        return AppColors.paperAccent;
      case ExceptionType.vacation:
        return AppColors.paperAccent;
      case ExceptionType.additionalSlot:
        return AppColors.paperOk;
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startStr = formatDateMDWithDayParens(start);
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return startStr;
    }
    final endStr = formatDateMDWithDayParens(end);
    return '$startStr ~ $endStr';
  }

  Future<void> _showAddExceptionDialog() async {
    final result = await showModalBottomSheet<TimeException>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddExceptionBottomSheet(),
    );

    if (result != null && mounted) {
      final teacherId = ref.read(currentUserIdProvider);
      await ref
          .read(teacherAvailabilityNotifierProvider(teacherId).notifier)
          .addException(result);
    }
  }

  Future<void> _confirmDelete(TimeException exception) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('휴무 삭제'),
            content: Text(
              '${_formatDateRange(exception.startDate, exception.endDate)} 휴무를 삭제하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.paperAccent,
                ),
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final teacherId = ref.read(currentUserIdProvider);
      await ref
          .read(teacherAvailabilityNotifierProvider(teacherId).notifier)
          .removeException(exception.id);
    }
  }
}

/// Bottom sheet for adding a new exception
class _AddExceptionBottomSheet extends StatefulWidget {
  const _AddExceptionBottomSheet();

  @override
  State<_AddExceptionBottomSheet> createState() =>
      _AddExceptionBottomSheetState();
}

class _AddExceptionBottomSheetState extends State<_AddExceptionBottomSheet> {
  ExceptionType _selectedType = ExceptionType.holiday;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                const Center(child: BottomSheetHandle(margin: EdgeInsets.zero)),

                const SizedBox(height: AppSpacing.space5),

                // Title
                Text('휴무 추가', style: AppTypography.headingMedium),

                const SizedBox(height: AppSpacing.space6),

                // Type selection
                Text(
                  '유형',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                _buildTypeSelector(),

                const SizedBox(height: AppSpacing.space5),

                // Date selection
                Text(
                  '기간',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Row(
                  children: [
                    Expanded(child: _buildDatePicker('시작일', _startDate, true)),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.space2,
                      ),
                      child: Text('~'),
                    ),
                    Expanded(child: _buildDatePicker('종료일', _endDate, false)),
                  ],
                ),

                const SizedBox(height: AppSpacing.space5),

                // Reason
                Text(
                  '사유 (선택)',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    hintText: '휴무 사유를 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMedium,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space4,
                      vertical: AppSpacing.space3,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.space6),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.space3,
                          ),
                        ),
                        child: const Text(AppStrings.cancel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.space3,
                          ),
                        ),
                        child: const Text('추가'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: AppSpacing.space2,
      children:
          ExceptionType.values
              .where((t) => t != ExceptionType.additionalSlot)
              .map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                  selectedColor: AppColors.paperAccent.withValues(alpha: 0.2),
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color:
                        isSelected
                            ? AppColors.paperAccent
                            : AppColors.inkSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              })
              .toList(),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, bool isStart) {
    return InkWell(
      onTap: () => _selectDate(isStart),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inkQuaternary),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: AppColors.inkSecondary),
            const SizedBox(width: AppSpacing.space2),
            Text(formatDateMDKorean(date), style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = isStart ? DateTime.now() : _startDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    final exception = TimeException(
      id: const Uuid().v4(),
      type: _selectedType,
      startDate: _startDate,
      endDate: _endDate,
      reason: _reasonController.text.isEmpty ? null : _reasonController.text,
      createdAt: DateTime.now(),
    );
    Navigator.of(context).pop(exception);
  }
}
