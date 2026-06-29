import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../domain/entities/child_profile.dart';

/// 자녀 카드 액션 시트 (#660 C7).
///
/// 자녀 카드 자체는 destructive 메타포(SwipeAction)에 맞지 않으므로
/// swipe 패턴은 적용하지 않고, 행 탭으로 본 시트를 띄워 2 액션을 노출한다.
///
/// 액션:
/// - [프로필 편집] — [onEditProfile]
class ChildProfileActionsBottomSheet extends StatelessWidget {
  const ChildProfileActionsBottomSheet({
    super.key,
    required this.profile,
    required this.onEditProfile,
  });

  final ChildProfile profile;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(margin: EdgeInsets.zero),
          const SizedBox(height: AppSpacing.space4),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Text(profile.name, style: NotebookTypography.sectionTitle),
          ),
          const SizedBox(height: AppSpacing.space3),
          const ThinRule(),
          ListTile(
            leading: Icon(Icons.edit_outlined, color: AppColors.ink),
            title: const Text(AppStrings.childProfileActionsEditProfile),
            trailing: Icon(Icons.chevron_right, color: AppColors.inkTertiary),
            onTap: () {
              Navigator.of(context).pop();
              onEditProfile();
            },
          ),
          const SizedBox(height: AppSpacing.space2),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
              ),
              child: Text(
                AppStrings.cancel,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
