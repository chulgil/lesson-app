import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'student_form_helpers.dart';

/// Address form fields for student location.
class AddressFields extends StatelessWidget {
  final TextEditingController postalCodeController;
  final TextEditingController addressController;
  final TextEditingController addressDetailController;

  const AddressFields({
    super.key,
    required this.postalCodeController,
    required this.addressController,
    required this.addressDetailController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Postal code + search button row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: postalCodeController,
                decoration: studentInputDecoration(
                  label: AppStrings.studentPostalCodeLabel,
                  hint: '00000',
                  prefixIcon: Icons.markunread_mailbox_outlined,
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space1),
              child: SizedBox(
                height: AppSpacing.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          AppStrings.studentAddressSearchComingSoon,
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.search, size: AppSpacing.iconSM),
                  label: const Text(AppStrings.studentAddressSearchLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.paperAccent,
                    side: const BorderSide(color: AppColors.paperAccent),
                    shape: const RoundedRectangleBorder(),
                    minimumSize: Size(0, AppSpacing.buttonHeight),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),

        // Address (manually editable)
        TextFormField(
          controller: addressController,
          decoration: studentInputDecoration(
            label: AppStrings.studentAddressLabel,
            hint: AppStrings.studentAddressHint,
            prefixIcon: Icons.location_on_outlined,
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Address detail (optional free text)
        TextFormField(
          controller: addressDetailController,
          decoration: studentInputDecoration(
            label: AppStrings.studentAddressDetailLabel,
            hint: AppStrings.studentAddressDetailHint,
            prefixIcon: Icons.apartment_outlined,
          ),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.space2),

        // Privacy notice
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: AppSpacing.iconXS,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(width: AppSpacing.space1),
            Flexible(
              child: Text(
                '주소는 연결된 선생님에게만 공개됩니다',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
