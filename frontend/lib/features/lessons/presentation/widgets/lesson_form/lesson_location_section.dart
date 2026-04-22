import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../students/domain/entities/lesson_location.dart';
import '../../../../students/presentation/providers/location_providers.dart';

/// Chip-style picker for selecting a teacher's lesson location.
///
/// Shows all active locations owned by the current teacher. Auto-prefills the
/// default location on first load via [onAutoPrefill] callback. Selection can
/// be cleared — location is optional on a lesson.
class LessonLocationSection extends ConsumerWidget {
  const LessonLocationSection({
    super.key,
    required this.teacherId,
    required this.selectedLocationId,
    required this.onSelected,
    this.onAutoPrefill,
  });

  final String teacherId;
  final String? selectedLocationId;
  final ValueChanged<LessonLocation?> onSelected;

  /// Called once when locations load and no selection exists yet.
  /// Use this to auto-prefill the default location.
  final ValueChanged<LessonLocation>? onAutoPrefill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(teacherLocationsProvider(teacherId));

    return locationsAsync.when(
      data: (locations) {
        final active = locations.where((l) => l.isActive).toList();

        if (active.isEmpty) {
          return _EmptyHint();
        }

        // Auto-prefill once if nothing selected yet.
        if (selectedLocationId == null && onAutoPrefill != null) {
          final defaultLoc = active.where((l) => l.isDefault).toList();
          final target =
              defaultLoc.isNotEmpty ? defaultLoc.first : active.first;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onAutoPrefill!(target);
          });
        }

        return Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            for (final loc in active)
              _LocationChip(
                location: loc,
                isSelected: loc.id == selectedLocationId,
                onTap:
                    () => onSelected(loc.id == selectedLocationId ? null : loc),
              ),
          ],
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.space2),
            child: SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      error: (_, __) => _EmptyHint(),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  final LessonLocation location;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (location.type) {
      case LocationType.academyRoom:
        return Icons.school;
      case LocationType.teacherStudio:
        return Icons.person;
      case LocationType.studentHome:
        return Icons.home;
      case LocationType.externalPlace:
        return Icons.music_note;
      case LocationType.online:
        return Icons.videocam;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(
        _icon,
        size: 16,
        color: isSelected ? AppColors.paperAccent : AppColors.inkSecondary,
      ),
      label: Text(location.name),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.paper,
      selectedColor: AppColors.paperAccent.withValues(alpha: 0.15),
      checkmarkColor: AppColors.paperAccent,
      side: BorderSide(
        color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
      ),
      labelStyle: AppTypography.bodySmall.copyWith(
        color: isSelected ? AppColors.paperAccent : AppColors.ink,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '등록된 장소가 없습니다',
      style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
    );
  }
}
