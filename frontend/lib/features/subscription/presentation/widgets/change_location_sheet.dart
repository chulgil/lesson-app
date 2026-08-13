import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../onboarding/onboarding_facade.dart'
    show currentTeacherProfileProvider;
import '../../../students/students_facade.dart';
import 'location_option_resolver.dart';
import 'location_travel_selector.dart';

/// Bottom sheet for changing a membership's lesson location and travel time.
class ChangeLocationSheet extends ConsumerStatefulWidget {
  final ClassMembership membership;
  final Future<void> Function(String? locationId, int travelTime) onSave;

  /// Student's preferred location type from their original lesson request.
  /// When the teacher picks a different type, a confirmation dialog is shown.
  final LocationType? preferredLocationType;

  const ChangeLocationSheet({
    super.key,
    required this.membership,
    required this.onSave,
    this.preferredLocationType,
  });

  @override
  ConsumerState<ChangeLocationSheet> createState() =>
      _ChangeLocationSheetState();
}

class _ChangeLocationSheetState extends ConsumerState<ChangeLocationSheet> {
  late String? _locationId;
  late int _travelTime;
  LocationType? _selectedLocationType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _locationId = widget.membership.lessonLocationId;
    _travelTime = widget.membership.travelTimeMinutes;
  }

  /// Returns a human-readable label for [type].
  String _locationTypeLabel(LocationType type) {
    switch (type) {
      case LocationType.studentHome:
        return AppStrings.locationStudentHomeLabel;
      case LocationType.externalPlace:
        return AppStrings.locationExternalPlaceLabel;
      case LocationType.teacherStudio:
        return AppStrings.locationTeacherHomeLabel;
      case LocationType.online:
        return AppStrings.locationOnlineLabel;
      case LocationType.academyRoom:
        return AppStrings.academy;
    }
  }

  Future<void> _handleSave() async {
    final preferred = widget.preferredLocationType;

    // Show warning dialog if the selected type differs from student's preference
    if (preferred != null &&
        _selectedLocationType != null &&
        _selectedLocationType != preferred) {
      final confirmed = await showNotebookDialog<bool>(
        context: context,
        title: AppStrings.locationChangeWarningTitle,
        content: Text(
          AppStrings.locationChangeWarningBody(
            _locationTypeLabel(preferred),
            _locationTypeLabel(_selectedLocationType!),
          ),
        ),
        confirmLabel: AppStrings.changeTypeLabel,
        cancelLabel: AppStrings.cancel,
      );
      if (confirmed != true) return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(_locationId, _travelTime);
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space5,
        right: AppSpacing.space5,
        top: AppSpacing.space5,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.space5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.changeLocation,
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          LocationTravelSelector(
            membershipId: widget.membership.id,
            studentId: widget.membership.studentId,
            currentLocationId: _locationId,
            currentTravelTime: _travelTime,
            onLocationChanged: (id) => setState(() => _locationId = id),
            onTravelTimeChanged: (t) => setState(() => _travelTime = t),
            onLocationTypeChanged:
                (type) => setState(() => _selectedLocationType = type),
            // #1146 — gate location options by the teacher's lesson types.
            allowedLocationTypes: allowedLocationTypes(
              ref.watch(currentTeacherProfileProvider).valueOrNull?.lessonTypes,
              isAcademy: false,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                foregroundColor: AppColors.paper,
                minimumSize: Size(0, AppSpacing.buttonHeight),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: _saving ? null : _handleSave,
              child:
                  _saving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(AppStrings.save),
            ),
          ),
        ],
      ),
    );
  }
}
