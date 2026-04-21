import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Section title text.
class FormSectionTitle extends StatelessWidget {
  final String title;

  const FormSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTypography.headingSmall);
  }
}

/// Section subtitle text.
class FormSectionSubtitle extends StatelessWidget {
  final String subtitle;

  const FormSectionSubtitle(this.subtitle, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space1),
      child: Text(
        subtitle,
        style: AppTypography.caption.copyWith(
          color: AppColors.inkSecondary,
        ),
      ),
    );
  }
}
