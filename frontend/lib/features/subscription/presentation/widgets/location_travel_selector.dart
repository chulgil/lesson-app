import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../students/domain/entities/lesson_location.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';

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

const _locationOptions = [
  _LocationOption(
    type: LocationType.studentHome,
    icon: Icons.home,
    label: '학생 집',
  ),
  _LocationOption(
    type: LocationType.academyRoom,
    icon: Icons.school,
    label: '학원',
  ),
  _LocationOption(
    type: LocationType.externalPlace,
    icon: Icons.music_note,
    label: '외부 스튜디오',
  ),
  _LocationOption(
    type: LocationType.teacherStudio,
    icon: Icons.person,
    label: '선생님 집',
  ),
  _LocationOption(
    type: LocationType.online,
    icon: Icons.videocam,
    label: '온라인',
  ),
];

/// Travel time dropdown values in minutes.
const _travelTimeValues = [0, 10, 20, 30, 45, 60];

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

  const LocationTravelSelector({
    super.key,
    required this.membershipId,
    required this.studentId,
    this.currentLocationId,
    required this.currentTravelTime,
    required this.onLocationChanged,
    required this.onTravelTimeChanged,
  });

  @override
  ConsumerState<LocationTravelSelector> createState() =>
      _LocationTravelSelectorState();
}

class _LocationTravelSelectorState
    extends ConsumerState<LocationTravelSelector> {
  LocationType? _selectedType;
  final _externalAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Derive initial type from currentLocationId if provided
    _selectedType = _inferTypeFromLocationId(widget.currentLocationId);
  }

  @override
  void dispose() {
    _externalAddressController.dispose();
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
        Text('레슨 장소', style: NotebookTypography.sectionTitle),
        const SizedBox(height: AppSpacing.space1),
        Text(
          '이 학생의 기본 레슨 장소를 선택하세요',
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
          _locationOptions.map((option) {
            final isSelected = _selectedType == option.type;
            return ChoiceChip(
              avatar: Icon(
                option.icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.inkSecondary,
              ),
              label: Text(option.label),
              selected: isSelected,
              onSelected: (_) => _onTypeSelected(option.type),
              selectedColor: AppColors.paperAccent,
              backgroundColor: AppColors.paper,
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.ink,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color:
                    isSelected
                        ? AppColors.paperAccent
                        : AppColors.inkQuaternary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildAddressSection() {
    switch (_selectedType!) {
      case LocationType.studentHome:
        return _buildStudentHomeAddress();
      case LocationType.academyRoom:
        return _buildReadOnlyAddress(icon: Icons.school, text: '학원 주소 (자동)');
      case LocationType.externalPlace:
        return _buildExternalAddressField();
      case LocationType.teacherStudio:
        return _buildReadOnlyAddress(icon: Icons.person, text: '선생님 스튜디오 (자동)');
      case LocationType.online:
        return _buildReadOnlyAddress(icon: Icons.videocam, text: '이동시간 없음');
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
            text: '학생 주소 미등록',
            isWarning: true,
          );
        }
        return _buildReadOnlyAddress(icon: Icons.home, text: address);
      },
      loading:
          () => _buildReadOnlyAddress(icon: Icons.home, text: '주소 불러오는 중...'),
      error:
          (_, __) => _buildReadOnlyAddress(
            icon: Icons.home,
            text: '주소 조회 실패',
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
        labelText: '외부 장소 주소',
        hintText: '예: 강남 OO 스튜디오',
        prefixIcon: const Icon(Icons.music_note, size: AppSpacing.iconSM),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.inkQuaternary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
    // Determine if travel time should be locked to 0
    final isLocked = _selectedType == LocationType.teacherStudio;
    final effectiveValue = isLocked ? 0 : widget.currentTravelTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 폼 섹션 제목은 Playfair sectionTitle
        // 로 통일 (§7.17).
        Text('이동시간', style: NotebookTypography.sectionTitle),
        const SizedBox(height: AppSpacing.space2),
        DropdownButtonFormField<int>(
          initialValue:
              _travelTimeValues.contains(effectiveValue) ? effectiveValue : 0,
          items:
              _travelTimeValues.map((minutes) {
                return DropdownMenuItem<int>(
                  value: minutes,
                  child: Text(
                    minutes == 0 ? '없음' : '$minutes분',
                    style: AppTypography.bodyMedium,
                  ),
                );
              }).toList(),
          onChanged:
              isLocked
                  ? null
                  : (value) {
                    if (value != null) {
                      widget.onTravelTimeChanged(value);
                    }
                  },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: const BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: const BorderSide(color: AppColors.paperAccent),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space3,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          '스케줄에서 레슨 시작 전 이동 블록으로 표시됩니다',
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
      ],
    );
  }
}
