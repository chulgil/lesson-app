import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/name_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';

/// Bottom sheet for editing travel/break time between lessons.
class TravelTimeEditSheet extends StatefulWidget {
  final int currentMinutes;
  final int globalBreakTime;
  final String? fromStudentName;
  final String? toStudentName;
  final String? fromLocation;
  final String? toLocation;

  /// Callback when saved. Returns (minutes, applyGlobally).
  final void Function(int minutes, bool applyGlobally) onSave;

  const TravelTimeEditSheet({
    super.key,
    required this.currentMinutes,
    required this.globalBreakTime,
    this.fromStudentName,
    this.toStudentName,
    this.fromLocation,
    this.toLocation,
    required this.onSave,
  });

  @override
  State<TravelTimeEditSheet> createState() => _TravelTimeEditSheetState();
}

class _TravelTimeEditSheetState extends State<TravelTimeEditSheet> {
  late int _minutes;
  bool _applyGlobally = false;

  static const _presetMinutes = [0, 5, 10, 15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _minutes = widget.currentMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          8,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: BottomSheetHandle()),
            const SizedBox(height: 16),
            // Title
            Text(
              '이동시간 설정',
              style: AppTypography.headingSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            // Location context
            _buildLocationContext(),
            const SizedBox(height: 20),
            // Time selector
            _buildTimeSelector(),
            const SizedBox(height: 20),
            // Apply scope
            _buildApplyScope(),
            const SizedBox(height: 24),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationContext() {
    final from = widget.fromStudentName != null
        ? NameUtils.givenName(widget.fromStudentName!)
        : '이전 레슨';
    final to = widget.toStudentName != null
        ? NameUtils.givenName(widget.toStudentName!)
        : '다음 레슨';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        children: [
          _buildLocationRow(
            Icons.circle,
            from,
            widget.fromLocation,
            AppColors.scheduleBreakIcon,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Container(
              width: 2,
              height: 20,
              color: AppColors.scheduleBreakBorder,
            ),
          ),
          _buildLocationRow(
            Icons.location_on,
            to,
            widget.toLocation,
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    IconData icon,
    String name,
    String? location,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (location != null)
                Text(
                  location,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이동시간',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetMinutes.map((minutes) {
            final isSelected = _minutes == minutes;
            return ChoiceChip(
              label: Text(minutes == 0 ? '없음' : '$minutes분'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _minutes = minutes);
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildApplyScope() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '적용 범위',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RadioListTile<bool>(
          value: false,
          groupValue: _applyGlobally,
          onChanged: (v) => setState(() => _applyGlobally = v!),
          title: const Text('이 레슨만 적용'),
          subtitle: Text(
            '이 레슨 뒤에만 ${_minutes}분 이동시간을 설정합니다',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
        ),
        RadioListTile<bool>(
          value: true,
          groupValue: _applyGlobally,
          onChanged: (v) => setState(() => _applyGlobally = v!),
          title: const Text('기본 쉬는시간으로 저장'),
          subtitle: Text(
            '모든 레슨 사이에 ${_minutes}분을 기본값으로 적용합니다',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  void _onSave() {
    widget.onSave(_minutes, _applyGlobally);
    Navigator.of(context).pop();
  }
}
