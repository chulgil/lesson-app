import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../features/parent_home/domain/entities/parent_notification_settings.dart';
import '../extensions/parent_home_domain_visuals.dart';

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
              // Notebook × Score: BottomSheetHandle + 상단 제목 조합은 §7.27
              // 패턴. Playfair appBarTitle 로 통일.
              Text(
                AppStrings.parentHomeNotificationDetailSettings,
                style: NotebookTypography.appBarTitle,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),

        // Summary
        // §7.132: paperAccent.alpha → paperAccentSoft.
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paperAccentSoft,
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: AppColors.paperAccent,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '${_settings.enabledCount}/${ParentNotificationSettings.totalConfigurable}개 알림 활성화',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.paperAccent,
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
              Text(category.icon, style: AppTypography.bodyLarge),
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
            borderRadius: BorderRadius.zero,
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
                      _buildSettingTile(item),
                      if (!isLast)
                        const Padding(
                          padding: EdgeInsets.only(left: 16, right: 16),
                          child: ThinRule(),
                        ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(NotificationItem item) {
    return ListTile(
      dense: true,
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: AppTypography.bodyMedium.copyWith(
                color: item.isRequired ? AppColors.inkTertiary : AppColors.ink,
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
                        ? AppColors.paperOk.withValues(alpha: 0.15)
                        : Colors.transparent,
                borderRadius: BorderRadius.zero,
              ),
              child: Text(
                item.suffix,
                style: AppTypography.captionSmall.copyWith(
                  color:
                      item.isRequired
                          ? AppColors.inkTertiary
                          : item.isRecommended
                          ? AppColors.paperOk
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
            item.isRequired ? null : (value) => _handleToggle(item.type, value),
        activeThumbColor: AppColors.paperAccent,
      ),
    );
  }

  void _handleToggle(NotificationSettingType type, bool value) {
    ParentNotificationSettings updated = _settings;

    switch (type) {
      case NotificationSettingType.paymentRequest:
      case NotificationSettingType.paymentComplete:
        return;
      case NotificationSettingType.paymentDueSoon:
        updated = updated.copyWith(paymentDueSoon: value);
      case NotificationSettingType.lessonChange:
        updated = updated.copyWith(lessonChange: value);
      case NotificationSettingType.lessonCancel:
        updated = updated.copyWith(lessonCancel: value);
      case NotificationSettingType.lessonStart:
        updated = updated.copyWith(lessonStart: value);
      case NotificationSettingType.lessonEnd:
        updated = updated.copyWith(lessonEnd: value);
      case NotificationSettingType.newAssignment:
        updated = updated.copyWith(newAssignment: value);
      case NotificationSettingType.assignmentIncomplete:
        updated = updated.copyWith(assignmentIncomplete: value);
      case NotificationSettingType.practiceComplete:
        updated = updated.copyWith(practiceComplete: value);
      case NotificationSettingType.streakAchievement:
        updated = updated.copyWith(streakAchievement: value);
      case NotificationSettingType.teacherMessage:
        updated = updated.copyWith(teacherMessage: value);
      case NotificationSettingType.lessonNoteUpdate:
        updated = updated.copyWith(lessonNoteUpdate: value);
      case NotificationSettingType.weeklyReport:
        updated = updated.copyWith(weeklyReport: value);
      case NotificationSettingType.monthlyReport:
        updated = updated.copyWith(monthlyReport: value);
    }

    _updateSetting(updated);
  }
}
