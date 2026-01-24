import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import 'student_form_helpers.dart';

/// Basic info form fields (name, phone, email).
class BasicInfoFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;

  const BasicInfoFields({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Name
        TextFormField(
          controller: nameController,
          decoration: studentInputDecoration(
            label: '이름',
            hint: '학생 이름을 입력하세요',
            prefixIcon: Icons.person_outline,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '이름을 입력해주세요';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Phone
        TextFormField(
          controller: phoneController,
          decoration: studentInputDecoration(
            label: '연락처',
            hint: '010-0000-0000',
            prefixIcon: Icons.phone_outlined,
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Email
        TextFormField(
          controller: emailController,
          decoration: studentInputDecoration(
            label: '이메일',
            hint: 'email@example.com',
            prefixIcon: Icons.email_outlined,
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}
