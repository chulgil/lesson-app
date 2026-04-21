import 'package:flutter/material.dart';

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
            SizedBox(
              width: 130,
              child: TextFormField(
                controller: postalCodeController,
                decoration: studentInputDecoration(
                  label: '우편번호',
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
                        content: Text('주소 검색 기능이 곧 추가됩니다'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.search, size: AppSpacing.iconSM),
                  label: const Text('주소 검색'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.paperAccent,
                    side: const BorderSide(color: AppColors.paperAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
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
            label: '주소',
            hint: '주소를 입력해주세요 (예: 서울시 강남구 역삼동)',
            prefixIcon: Icons.location_on_outlined,
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Address detail (optional free text)
        TextFormField(
          controller: addressDetailController,
          decoration: studentInputDecoration(
            label: '상세주소',
            hint: '동/호수를 입력하세요 (선택)',
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
