import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_spacing.dart';
import 'student_form_helpers.dart';

/// Parent/guardian info form fields.
class ParentInfoFields extends StatelessWidget {
  final TextEditingController parentNameController;
  final TextEditingController parentPhoneController;

  const ParentInfoFields({
    super.key,
    required this.parentNameController,
    required this.parentPhoneController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Parent name
        TextFormField(
          controller: parentNameController,
          decoration: studentInputDecoration(
            label: AppStrings.studentParentNameLabel,
            hint: AppStrings.studentParentNameHint,
            prefixIcon: Icons.family_restroom,
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Parent phone
        TextFormField(
          controller: parentPhoneController,
          decoration: studentInputDecoration(
            label: AppStrings.studentParentPhoneLabel,
            hint: '010-0000-0000',
            prefixIcon: Icons.phone_outlined,
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}
