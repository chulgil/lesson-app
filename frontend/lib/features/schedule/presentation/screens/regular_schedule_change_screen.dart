import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/lesson_schedule_change.dart';

/// Result from the regular schedule change screen.
typedef RegularScheduleChangeResult = ({
  int dayOfWeek,
  String time,
  String message,
});

/// Parameters for navigating to this screen.
class RegularScheduleChangeParams {
  final String currentScheduleLabel;
  final int? currentDayOfWeek;
  final String? currentTime;

  const RegularScheduleChangeParams({
    required this.currentScheduleLabel,
    this.currentDayOfWeek,
    this.currentTime,
  });
}

/// Screen for changing the regular (recurring) lesson schedule.
///
/// Allows selecting a new day of week and time for all future lessons.
class RegularScheduleChangeScreen extends StatefulWidget {
  final RegularScheduleChangeParams params;

  const RegularScheduleChangeScreen({super.key, required this.params});

  @override
  State<RegularScheduleChangeScreen> createState() =>
      _RegularScheduleChangeScreenState();
}

class _RegularScheduleChangeScreenState
    extends State<RegularScheduleChangeScreen> {
  late int _selectedDayOfWeek;
  late int _selectedHour;
  late int _selectedMinute;
  final _messageController = TextEditingController();

  static const _days = ['월', '화', '수', '목', '금', '토', '일'];
  static const _hours = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21];
  static const _minutes = [0, 30];

  RegularScheduleChangeParams get params => widget.params;

  @override
  void initState() {
    super.initState();
    _selectedDayOfWeek = params.currentDayOfWeek ?? 0;
    // Parse current time or default to 14:00
    if (params.currentTime != null && params.currentTime!.contains(':')) {
      final parts = params.currentTime!.split(':');
      _selectedHour = int.tryParse(parts[0]) ?? 14;
      _selectedMinute = int.tryParse(parts[1]) ?? 0;
    } else {
      _selectedHour = 14;
      _selectedMinute = 0;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  bool get _hasChanged {
    if (params.currentDayOfWeek == null || params.currentTime == null) {
      return true;
    }
    final currentTimeStr =
        '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';
    return _selectedDayOfWeek != params.currentDayOfWeek ||
        currentTimeStr != params.currentTime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.scheduleChangeRegularTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current schedule display
                    _buildCurrentSchedule(),
                    const SizedBox(height: AppSpacing.space6),

                    // New schedule selection
                    Text(
                      AppStrings.scheduleChangeNewSchedule,
                      style: AppTypography.headingSmall,
                    ),
                    const SizedBox(height: AppSpacing.space4),

                    // Day of week selector
                    _buildDaySelector(),
                    const SizedBox(height: AppSpacing.space4),

                    // Time selector
                    _buildTimeSelector(),
                    const SizedBox(height: AppSpacing.space6),

                    // Message input
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: AppStrings.messageHint,
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Submit button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasChanged ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(AppSpacing.buttonHeight),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                  ),
                  child: Text(
                    AppStrings.scheduleChangePropose,
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSchedule() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.scheduleMutedBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.scheduleChangeCurrentSchedule,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            params.currentScheduleLabel,
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children: List.generate(7, (index) {
        final isSelected = _selectedDayOfWeek == index;
        return ChoiceChip(
          label: Text(_days[index]),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedDayOfWeek = index),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: AppTypography.bodyMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
        );
      }),
    );
  }

  Widget _buildTimeSelector() {
    return Row(
      children: [
        // Hour
        Expanded(
          child: _buildDropdown<int>(
            value: _selectedHour,
            items: _hours,
            labelBuilder: (h) => '${h.toString().padLeft(2, '0')}시',
            onChanged: (v) => setState(() => _selectedHour = v),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        // Minute
        Expanded(
          child: _buildDropdown<int>(
            value: _selectedMinute,
            items: _minutes,
            labelBuilder: (m) => '${m.toString().padLeft(2, '0')}분',
            onChanged: (v) => setState(() => _selectedMinute = v),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      labelBuilder(item),
                      style: AppTypography.bodyMedium,
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  void _submit() {
    final timeStr =
        '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';
    final message = _messageController.text.trim();

    Navigator.pop<RegularScheduleChangeResult>(
      context,
      (
        dayOfWeek: _selectedDayOfWeek,
        time: timeStr,
        message: message,
      ),
    );
  }
}
