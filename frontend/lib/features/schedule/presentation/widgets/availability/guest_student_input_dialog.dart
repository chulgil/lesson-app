import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/bottom_sheet_handle.dart';

/// Guest student information collected before booking
class GuestStudentInfo {
  final String name;
  final String? phone;
  final String? email;

  const GuestStudentInfo({required this.name, this.phone, this.email});
}

/// Dialog for collecting guest student information before booking
class GuestStudentInputDialog extends StatefulWidget {
  const GuestStudentInputDialog({super.key});

  /// Show the dialog and return guest student info, or null if cancelled
  static Future<GuestStudentInfo?> show(BuildContext context) async {
    return showModalBottomSheet<GuestStudentInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GuestStudentInputDialog(),
    );
  }

  @override
  State<GuestStudentInputDialog> createState() =>
      _GuestStudentInputDialogState();
}

class _GuestStudentInputDialogState extends State<GuestStudentInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final info = GuestStudentInfo(
        name: _nameController.text.trim(),
        phone:
            _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
        email:
            _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
      );
      Navigator.of(context).pop(info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  const Center(
                    child: BottomSheetHandle(margin: EdgeInsets.zero),
                  ),

                  const SizedBox(height: AppSpacing.space5),

                  // Title
                  Text('예약자 정보 입력', style: AppTypography.headingMedium),

                  const SizedBox(height: AppSpacing.space2),

                  Text(
                    '레슨 예약을 위해 정보를 입력해주세요',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.space6),

                  // Name field (required)
                  _buildLabel('이름', isRequired: true),
                  const SizedBox(height: AppSpacing.space2),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(
                      hintText: '예약자 이름을 입력하세요',
                      prefixIcon: Icons.person_outline,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '이름을 입력해주세요';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.space4),

                  // Phone field (optional)
                  _buildLabel('연락처', isRequired: false),
                  const SizedBox(height: AppSpacing.space2),
                  TextFormField(
                    controller: _phoneController,
                    decoration: _inputDecoration(
                      hintText: '010-0000-0000',
                      prefixIcon: Icons.phone_outlined,
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: AppSpacing.space4),

                  // Email field (optional)
                  _buildLabel('이메일', isRequired: false),
                  const SizedBox(height: AppSpacing.space2),
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration(
                      hintText: 'example@email.com',
                      prefixIcon: Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          !_isValidEmail(value)) {
                        return '올바른 이메일 형식을 입력해주세요';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.space6),

                  // Info text
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space3),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMedium,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.ink,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Text(
                            '연락처나 이메일을 입력하면 예약 확정 알림을 받을 수 있어요',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.space6),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppSpacing.buttonHeight,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(AppStrings.cancel),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: AppSpacing.buttonHeight,
                          child: FilledButton(
                            onPressed: _submit,
                            child: const Text('예약하기'),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.space4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          text,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        if (isRequired)
          Text(
            ' *',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (!isRequired)
          Text(
            ' (선택)',
            style: AppTypography.caption.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(
        prefixIcon,
        size: 20,
        color: AppColors.inkSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: const BorderSide(color: AppColors.inkQuaternary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: const BorderSide(color: AppColors.inkQuaternary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: const BorderSide(color: AppColors.paperAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: const BorderSide(color: AppColors.paperAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      filled: true,
      fillColor: AppColors.paper,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
