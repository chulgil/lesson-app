import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../features/parent_home/domain/entities/parent_notification_settings.dart';

/// Detailed notification settings sheet for parents.
class NotificationSettingsSheet extends StatefulWidget {
  final ParentNotificationSettings settings;
  final ScrollController scrollController;
  final ValueChanged<ParentNotificationSettings> onSettingsChanged;

  const NotificationSettingsSheet({
    super.key,
    required this.settings,
    required this.scrollController,
    required this.onSettingsChanged,
  });

  @override
  State<NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  late ParentNotificationSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _updateSetting(ParentNotificationSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsChanged(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _settings.groupedSettings;

    return Column(
      children: [
        // Handle
        const BottomSheetHandle(),

        // Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('알림 상세 설정', style: AppTypography.headingSmall),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),

        // Summary
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '${_settings.enabledCount}/${ParentNotificationSettings.totalConfigurable}개 알림 활성화',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Settings list
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            children: [
              for (final category in NotificationCategory.values)
                _buildCategorySection(category, grouped[category] ?? []),
              const SizedBox(height: AppSpacing.space8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    NotificationCategory category,
    List<NotificationItem> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.space4,
            bottom: AppSpacing.space2,
          ),
          child: Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.space2),
              Text(
                category.label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Column(
            children:
                items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == items.length - 1;

                  return Column(
                    children: [
                      _buildSettingTile(category, item, index),
                      if (!isLast)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    NotificationCategory category,
    NotificationItem item,
    int index,
  ) {
    return ListTile(
      dense: true,
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: AppTypography.bodyMedium.copyWith(
                color:
                    item.isRequired
                        ? AppColors.inkTertiary
                        : AppColors.ink,
              ),
            ),
          ),
          if (item.suffix.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: AppSpacing.space2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    item.isRequired
                        ? AppColors.inkTertiary.withValues(alpha: 0.2)
                        : item.isRecommended
                        ? AppColors.success.withValues(alpha: 0.15)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Text(
                item.suffix,
                style: AppTypography.captionSmall.copyWith(
                  color:
                      item.isRequired
                          ? AppColors.inkTertiary
                          : item.isRecommended
                          ? AppColors.success
                          : AppColors.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      trailing: Switch(
        value: item.isEnabled,
        onChanged:
            item.isRequired
                ? null
                : (value) => _handleToggle(category, index, value),
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  void _handleToggle(NotificationCategory category, int index, bool value) {
    ParentNotificationSettings updated = _settings;

    switch (category) {
      case NotificationCategory.payment:
        if (index == 2) updated = updated.copyWith(paymentDueSoon: value);
        break;
      case NotificationCategory.lesson:
        if (index == 0) updated = updated.copyWith(lessonChange: value);
        if (index == 1) updated = updated.copyWith(lessonCancel: value);
        if (index == 2) updated = updated.copyWith(lessonStart: value);
        if (index == 3) updated = updated.copyWith(lessonEnd: value);
        break;
      case NotificationCategory.assignment:
        if (index == 0) updated = updated.copyWith(newAssignment: value);
        if (index == 1) updated = updated.copyWith(assignmentIncomplete: value);
        break;
      case NotificationCategory.practice:
        if (index == 0) updated = updated.copyWith(practiceComplete: value);
        if (index == 1) updated = updated.copyWith(streakAchievement: value);
        break;
      case NotificationCategory.communication:
        if (index == 0) updated = updated.copyWith(teacherMessage: value);
        if (index == 1) updated = updated.copyWith(lessonNoteUpdate: value);
        break;
      case NotificationCategory.report:
        if (index == 0) updated = updated.copyWith(weeklyReport: value);
        if (index == 1) updated = updated.copyWith(monthlyReport: value);
        break;
    }

    _updateSetting(updated);
  }
}
