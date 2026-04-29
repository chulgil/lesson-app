import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';

/// Result returned when a badge is awarded.
typedef BadgeAwardResult = ({String badgeId, String? message});

/// Definition of a teacher-awardable badge.
class _TeacherBadge {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const _TeacherBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

/// List of badges that teachers can award to students.
const _teacherBadges = [
  _TeacherBadge(
    id: 'bestGrowth',
    name: '최고 성장상',
    description: '레슨에서 큰 성장을 보인 학생',
    icon: Icons.trending_up,
  ),
  _TeacherBadge(
    id: 'perfectPerformance',
    name: '완벽한 연주',
    description: '완벽하게 연주한 곡',
    icon: Icons.music_note,
  ),
  _TeacherBadge(
    id: 'challengeSpirit',
    name: '도전 정신',
    description: '어려운 곡에 도전',
    icon: Icons.flash_on,
  ),
];

/// BottomSheet for teacher badge award.
///
/// Shows 3 teacher-awardable badges as selectable cards,
/// an optional message field, and a confirm button.
class BadgeAwardSheet extends StatefulWidget {
  const BadgeAwardSheet({super.key});

  /// Show as a modal bottom sheet and return the result.
  static Future<BadgeAwardResult?> show(BuildContext context) {
    return showModalBottomSheet<BadgeAwardResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BadgeAwardSheet(),
    );
  }

  @override
  State<BadgeAwardSheet> createState() => _BadgeAwardSheetState();
}

class _BadgeAwardSheetState extends State<BadgeAwardSheet> {
  String? _selectedBadgeId;
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.zero,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.space3,
                AppSpacing.screenPadding,
                MediaQuery.of(context).padding.bottom + AppSpacing.space4,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  const Center(
                    child: BottomSheetHandle(
                      width: 36,
                      margin: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        color: AppColors.paperAccent,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      // Notebook × Score: 바텀시트 헤더 §7.27 + 정적 명사 → Playfair 승격.
                      Text(
                        '\uBDF3\uC9C0 \uC218\uC5EC',
                        style: NotebookTypography.sectionTitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Badge selection cards
                  ..._teacherBadges.map(_buildBadgeCard),
                  const SizedBox(height: AppSpacing.space4),

                  // Message text field
                  TextField(
                    controller: _messageController,
                    maxLength: 100,
                    maxLines: 2,
                    style: AppTypography.bodySmall,
                    decoration: InputDecoration(
                      hintText: '\uBA54\uC2DC\uC9C0 (\uC120\uD0DD)',
                      hintStyle: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      contentPadding: const EdgeInsets.all(AppSpacing.space3),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Confirm button
                  SizedBox(
                    height: AppSpacing.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _selectedBadgeId == null ? null : _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.paperAccent,
                        disabledBackgroundColor: AppColors.scheduleMutedAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        '\uC218\uC5EC\uD558\uAE30',
                        style: AppTypography.buttonSmall.copyWith(
                          color: AppColors.paper,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeCard(_TeacherBadge badge) {
    final isSelected = _selectedBadgeId == badge.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: InkWell(
        onTap: () => setState(() => _selectedBadgeId = badge.id),
        borderRadius: BorderRadius.zero,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.zero,
            color:
                isSelected
                    ? AppColors.paperAccentSoft
                    : null,
          ),
          child: Row(
            children: [
              // Badge icon circle
              Container(
                width: AppSpacing.iconXL,
                height: AppSpacing.iconXL,
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.paperAccentSoft
                          : AppColors.paperDark,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  badge.icon,
                  color:
                      isSelected
                          ? AppColors.paperAccent
                          : AppColors.inkSecondary,
                  size: AppSpacing.iconMD,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              // Badge text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      badge.description,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Selection indicator
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color:
                    isSelected ? AppColors.paperAccent : AppColors.inkTertiary,
                size: AppSpacing.iconSM,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onConfirm() {
    final message = _messageController.text.trim();
    Navigator.of(context).pop<BadgeAwardResult>((
      badgeId: _selectedBadgeId!,
      message: message.isEmpty ? null : message,
    ));
  }
}
