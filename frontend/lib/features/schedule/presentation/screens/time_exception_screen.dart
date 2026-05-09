import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../auth/auth_facade.dart';
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

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: NotebookDetailAppBar(
        title: AppStrings.timeExceptionTitle,
        actions: const [DetailAppBarAction.add],
        onAction: (action) {
          if (action == DetailAppBarAction.add) _showAddExceptionDialog();
        },
      ),
      body: availabilityAsync.when(
        data: (availability) => _buildContent(availability),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error),
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
            // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
            Text(
              AppStrings.upcomingExceptions,
              style: NotebookTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space3),
            ...upcoming.map((e) => _buildExceptionCard(e)),
          ],

          // Past exceptions
          if (past.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space6),
            // Notebook × Score: 과거 섹션 제목도 Playfair sectionTitle 로 통일, 차분한 톤은
            // inkSecondary copyWith 로 보존 (§7.17, color override 변형).
            Text(
              AppStrings.pastExceptions,
              style: NotebookTypography.sectionTitle.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            ...past.map((e) => _buildExceptionCard(e, isPast: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.08),
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
                  AppStrings.exceptionInfoTitle,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  AppStrings.exceptionInfoBody,
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
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1)),
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
            AppStrings.noExceptionsSet,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.addExceptionHint,
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
            AppStrings.cannotLoadData,
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
    final result = await showNotebookBottomSheet<TimeException>(
      context: context,
      isScrollControlled: true,
      padding: EdgeInsets.zero,
      showHandle: false,
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
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.deleteExceptionTitle,
      content: Text(
        AppStrings.deleteExceptionConfirm(
          _formatDateRange(exception.startDate, exception.endDate),
        ),
      ),
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
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
      decoration: const BoxDecoration(color: AppColors.paper),
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

                // Notebook × Score: 바텀시트 헤더 (§7.27) — Playfair sectionTitle.
                Text(
                  AppStrings.addTimeException,
                  style: NotebookTypography.sectionTitle,
                ),

                const SizedBox(height: AppSpacing.space6),

                // Type selection
                Text(
                  AppStrings.typeLabel,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                _buildTypeSelector(),

                const SizedBox(height: AppSpacing.space5),

                // Date selection
                Text(
                  AppStrings.period,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        AppStrings.startDateLabel,
                        _startDate,
                        true,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.space2,
                      ),
                      child: Text('~'),
                    ),
                    Expanded(
                      child: _buildDatePicker(
                        AppStrings.endDateLabel,
                        _endDate,
                        false,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.space5),

                // Reason
                Text(
                  AppStrings.reasonOptionalLabel,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    hintText: AppStrings.reasonHint,
                    border: OutlineInputBorder(),
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
                        child: const Text(AppStrings.addAction),
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
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inkQuaternary),
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
