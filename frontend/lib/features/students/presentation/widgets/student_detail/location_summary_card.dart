import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/class_membership.dart';
import '../../../domain/entities/lesson_location.dart';
import '../../providers/location_providers.dart';

/// Compact card showing lesson location and travel time for a student.
class LocationSummaryCard extends ConsumerWidget {
  final ClassMembership? membership;

  const LocationSummaryCard({super.key, this.membership});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationId = membership?.lessonLocationId;
    final travelTime = membership?.travelTimeMinutes ?? 0;

    if (locationId == null && travelTime == 0) {
      return const SizedBox.shrink();
    }

    // Load location if ID is available
    final locationAsync =
        locationId != null ? ref.watch(locationProvider(locationId)) : null;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.paperDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: AppColors.paperAccent,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '레슨 장소',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            if (locationAsync != null)
              locationAsync.when(
                data:
                    (location) =>
                        _buildLocationInfo(context, location, travelTime),
                loading:
                    () => const SizedBox(
                      height: 20,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                error: (_, __) => _buildTravelOnly(context, travelTime),
              )
            else
              _buildTravelOnly(context, travelTime),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(
    BuildContext context,
    LessonLocation? location,
    int travelTime,
  ) {
    if (location == null) return _buildTravelOnly(context, travelTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(location.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                location.name,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        if (location.displayAddress.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(
            location.displayAddress,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
        if (travelTime > 0) ...[
          const SizedBox(height: AppSpacing.space2),
          _buildTravelChip(context, travelTime),
        ],
      ],
    );
  }

  Widget _buildTravelOnly(BuildContext context, int travelTime) {
    if (travelTime <= 0) return const SizedBox.shrink();
    return _buildTravelChip(context, travelTime);
  }

  Widget _buildTravelChip(BuildContext context, int travelTime) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paperAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 14,
            color: AppColors.paperAccent,
          ),
          const SizedBox(width: AppSpacing.space1),
          Text(
            '이동 $travelTime분',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
