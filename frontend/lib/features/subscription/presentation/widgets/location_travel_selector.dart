import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../students/students_facade.dart';

/// Location type option with icon and label for ChoiceChip display.
class _LocationOption {
  final LocationType type;
  final IconData icon;
  final String label;

  const _LocationOption({
    required this.type,
    required this.icon,
    required this.label,
  });
}

/// 학원 레슨: 학원, 온라인만
const _academyLocationOptions = [
  _LocationOption(
    type: LocationType.academyRoom,
    icon: Icons.school,
    label: AppStrings.academy,
  ),
  _LocationOption(
    type: LocationType.online,
    icon: Icons.videocam,
    label: AppStrings.locationOnlineLabel,
  ),
];

/// 개인 레슨: 학생집, 외부 스튜디오, 선생님 집, 온라인
const _privateLocationOptions = [
  _LocationOption(
    type: LocationType.studentHome,
    icon: Icons.home,
    label: AppStrings.locationStudentHomeLabel,
  ),
  _LocationOption(
    type: LocationType.externalPlace,
    icon: Icons.music_note,
    label: AppStrings.locationExternalPlaceLabel,
  ),
  _LocationOption(
    type: LocationType.teacherStudio,
    icon: Icons.person,
    label: AppStrings.locationTeacherHomeLabel,
  ),
  _LocationOption(
    type: LocationType.online,
    icon: Icons.videocam,
    label: AppStrings.locationOnlineLabel,
  ),
];

/// Widget for selecting lesson location type and travel time for a membership.
///
/// Like choosing a delivery method for a package: the teacher picks where
/// the lesson happens, and travel time is automatically suggested or manually set.
class LocationTravelSelector extends ConsumerStatefulWidget {
  final String membershipId;
  final String studentId;
  final String? currentLocationId;
  final int currentTravelTime;
  final ValueChanged<String?> onLocationChanged;
  final ValueChanged<int> onTravelTimeChanged;

  /// Optional callback notifying the parent of the selected [LocationType].
  /// Useful when the parent needs to compare types (e.g. warning dialog).
  final ValueChanged<LocationType?>? onLocationTypeChanged;

  /// true = 학원 레슨 (학원, 온라인만), false = 개인 레슨 (학생집, 외부, 선생님집, 온라인)
  final bool isAcademy;

  /// Optional: API-suggested travel time in minutes (e.g. from Kakao Maps).
  final int? suggestedTravelTimeMinutes;

  /// Optional: source label for the suggestion (e.g. '카카오').
  final String? suggestionSource;

  /// Optional: base lesson fee in KRW for surcharge calculation.
  final int? baseLessonFee;

  /// Optional: lesson duration in minutes for surcharge calculation.
  final int? lessonDurationMinutes;

  /// Optional: pre-select a location type (e.g. from student's lesson request preference).
  /// Used as a default when [currentLocationId] is null or yields no type.
  final LocationType? initialLocationType;

  const LocationTravelSelector({
    super.key,
    required this.membershipId,
    required this.studentId,
    this.currentLocationId,
    required this.currentTravelTime,
    required this.onLocationChanged,
    required this.onTravelTimeChanged,
    this.isAcademy = false,
    this.suggestedTravelTimeMinutes,
    this.suggestionSource,
    this.baseLessonFee,
    this.lessonDurationMinutes,
    this.initialLocationType,
    this.onLocationTypeChanged,
  });

  @override
  ConsumerState<LocationTravelSelector> createState() =>
      _LocationTravelSelectorState();
}

class _LocationTravelSelectorState
    extends ConsumerState<LocationTravelSelector> {
  LocationType? _selectedType;
  final _externalAddressController = TextEditingController();
  final _travelTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Derive initial type from currentLocationId, then fall back to
    // initialLocationType (e.g. student's preferred location from request).
    _selectedType = _inferTypeFromLocationId(widget.currentLocationId) ??
        widget.initialLocationType;
    // Initialise travel time text field
    final initial = widget.currentTravelTime;
    _travelTimeController.text = initial > 0 ? initial.toString() : '';
  }

  @override
  void dispose() {
    _externalAddressController.dispose();
    _travelTimeController.dispose();
    super.dispose();
  }

  /// Infer location type from a location ID pattern.
  /// In a real implementation, this would look up the location entity.
  LocationType? _inferTypeFromLocationId(String? locationId) {
    if (locationId == null) return null;
    if (locationId.contains('student_home')) return LocationType.studentHome;
    if (locationId.contains('academy')) return LocationType.academyRoom;
    if (locationId.contains('external')) return LocationType.externalPlace;
    if (locationId.contains('teacher')) return LocationType.teacherStudio;
    if (locationId.contains('online')) return LocationType.online;
    return null;
  }

  /// Generate a synthetic location ID from the selected type.
  String _locationIdFromType(LocationType type) {
    switch (type) {
      case LocationType.studentHome:
        return 'student_home_${widget.studentId}';
      case LocationType.academyRoom:
        return 'academy_default';
      case LocationType.externalPlace:
        return 'external_${widget.membershipId}';
      case LocationType.teacherStudio:
        return 'teacher_studio_default';
      case LocationType.online:
        return 'online_default';
    }
  }

  void _onTypeSelected(LocationType type) {
    setState(() {
      _selectedType = type;
    });

    // Generate location ID and notify parent
    widget.onLocationChanged(_locationIdFromType(type));

    // Notify parent of type change (used for warning dialog in ChangeLocationSheet)
    widget.onLocationTypeChanged?.call(type);

    // Auto-set travel time to 0 for online and teacher studio
    if (type == LocationType.online || type == LocationType.teacherStudio) {
      widget.onTravelTimeChanged(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 폼 섹션 제목은 Playfair sectionTitle
        // 로 통일 (§7.17).
        Text(
          AppStrings.lessonLocationLabel,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          AppStrings.lessonLocationDescription,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Location type chips
        _buildLocationChips(),

        // Address display based on selection
        if (_selectedType != null) ...[
          const SizedBox(height: AppSpacing.space3),
          _buildAddressSection(),
        ],

        // Travel time dropdown (hidden for online)
        if (_selectedType != null && _selectedType != LocationType.online) ...[
          const SizedBox(height: AppSpacing.space4),
          _buildTravelTimeSection(),
        ],
      ],
    );
  }

  Widget _buildLocationChips() {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children:
          (widget.isAcademy ? _academyLocationOptions : _privateLocationOptions).map((option) {
            final isSelected = _selectedType == option.type;
            return ChoiceChip(
              avatar: Icon(
                option.icon,
                size: 18,
                color: isSelected ? AppColors.paper : AppColors.inkSecondary,
              ),
              label: Text(option.label),
              selected: isSelected,
              onSelected: (_) => _onTypeSelected(option.type),
              selectedColor: AppColors.paperAccent,
              backgroundColor: AppColors.paper,
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.paper : AppColors.ink,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color:
                    isSelected
                        ? AppColors.paperAccent
                        : AppColors.inkQuaternary,
              ),
              shape: RoundedRectangleBorder(),
            );
          }).toList(),
    );
  }

  Widget _buildAddressSection() {
    switch (_selectedType!) {
      case LocationType.studentHome:
        return _buildStudentHomeAddress();
      case LocationType.academyRoom:
        return _buildReadOnlyAddress(
          icon: Icons.school,
          text: AppStrings.locationAcademyAddressAuto,
        );
      case LocationType.externalPlace:
        return _buildExternalAddressField();
      case LocationType.teacherStudio:
        return _buildReadOnlyAddress(
          icon: Icons.person,
          text: AppStrings.locationTeacherStudioAddressAuto,
        );
      case LocationType.online:
        return _buildReadOnlyAddress(
          icon: Icons.videocam,
          text: AppStrings.locationOnlineNoTravel,
        );
    }
  }

  Widget _buildStudentHomeAddress() {
    final studentAsync = ref.watch(studentProvider(widget.studentId));

    return studentAsync.when(
      data: (student) {
        final address = student?.fullAddress;
        if (address == null || address.isEmpty) {
          return _buildReadOnlyAddress(
            icon: Icons.home,
            text: AppStrings.locationStudentAddressEmpty,
            isWarning: true,
          );
        }
        return _buildReadOnlyAddress(icon: Icons.home, text: address);
      },
      loading:
          () => _buildReadOnlyAddress(
            icon: Icons.home,
            text: AppStrings.locationAddressLoading,
          ),
      error:
          (_, __) => _buildReadOnlyAddress(
            icon: Icons.home,
            text: AppStrings.locationAddressFetchFailed,
            isWarning: true,
          ),
    );
  }

  Widget _buildReadOnlyAddress({
    required IconData icon,
    required String text,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: isWarning ? AppColors.paperAccentSoft : AppColors.paperDark,
        border: Border.all(
          color: isWarning ? AppColors.paperAccent : AppColors.inkQuaternary,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppSpacing.iconSM,
            color: isWarning ? AppColors.paperAccent : AppColors.inkSecondary,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color:
                    isWarning ? AppColors.paperAccent : AppColors.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalAddressField() {
    return TextFormField(
      controller: _externalAddressController,
      decoration: InputDecoration(
        labelText: AppStrings.locationExternalAddressLabel,
        hintText: AppStrings.locationExternalAddressHint,
        prefixIcon: const Icon(Icons.music_note, size: AppSpacing.iconSM),
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.inkQuaternary),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.paperAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
      ),
      style: AppTypography.bodySmall,
    );
  }

  Widget _buildTravelTimeSection() {
    // Travel time is locked to 0 for teacher studio (student travels to teacher)
    final isLocked = _selectedType == LocationType.teacherStudio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 폼 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
        Text(
          AppStrings.travelTimeLabel,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: _travelTimeController,
          enabled: !isLocked,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: '0',
            suffixText: AppStrings.travelTimeMinutesSuffix,
            suffixStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.paperAccent),
            ),
            disabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space3,
            ),
          ),
          onChanged: (raw) {
            final parsed = int.tryParse(raw) ?? 0;
            widget.onTravelTimeChanged(parsed);
          },
        ),

        // API suggestion hint
        if (!isLocked &&
            widget.suggestedTravelTimeMinutes != null &&
            widget.suggestionSource != null) ...[
          const SizedBox(height: AppSpacing.space1),
          GestureDetector(
            onTap: () {
              final suggested = widget.suggestedTravelTimeMinutes!;
              _travelTimeController.text = suggested.toString();
              widget.onTravelTimeChanged(suggested);
            },
            child: Text(
              AppStrings.travelTimeSuggestion(
                widget.suggestedTravelTimeMinutes!,
                widget.suggestionSource!,
              ),
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.space1),
        Text(
          AppStrings.travelTimeDescription,
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),

        // Surcharge reference display
        if (!isLocked) ...[
          const SizedBox(height: AppSpacing.space2),
          _buildSurchargeReference(),
        ],
      ],
    );
  }

  /// Calculates and displays the approximate surcharge for travel time.
  ///
  /// Formula: surcharge = ceil((baseFee / (duration / 60)) * (travelTime / 60) / 1000) * 1000
  Widget _buildSurchargeReference() {
    final baseFee = widget.baseLessonFee;
    final duration = widget.lessonDurationMinutes;
    final travelTime =
        int.tryParse(_travelTimeController.text) ?? widget.currentTravelTime;

    if (baseFee == null || duration == null || duration == 0 || travelTime <= 0) {
      return const SizedBox.shrink();
    }

    final hourlyRate = baseFee / (duration / 60.0);
    final travelCost = hourlyRate * (travelTime / 60.0);
    final surcharge = max(1000, (travelCost / 1000).ceil() * 1000);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          const Text('💡', style: AppTypography.bodyMedium),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.travelSurchargeReference(surcharge),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  AppStrings.travelSurchargeDescription,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
