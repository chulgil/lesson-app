import 'package:flutter/material.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/app_typography.dart';
import 'package:lessonaza/features/academy/academy.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_inquiry_repository.dart';

class AcademyInquiryFormWidget extends StatefulWidget {
  const AcademyInquiryFormWidget({
    required this.academyId,
    this.onSubmitSuccess,
    super.key,
  });

  final String academyId;
  final VoidCallback? onSubmitSuccess;

  @override
  State<AcademyInquiryFormWidget> createState() =>
      _AcademyInquiryFormWidgetState();
}

class _AcademyInquiryFormWidgetState extends State<AcademyInquiryFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _messageController;
  InquirySenderRole _selectedRole = InquirySenderRole.student;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = MockAcademyInquiryRepository();
      await repo.create(
        academyId: widget.academyId,
        senderRole: _selectedRole,
        senderName: _nameController.text,
        body: _messageController.text,
      );

      if (mounted) {
        _nameController.clear();
        _phoneController.clear();
        _messageController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.inquiryCreated),
            duration: const Duration(seconds: 2),
          ),
        );

        widget.onSubmitSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('문의 전송 실패: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.inquiryTabAsk,
            style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
          ),
          SizedBox(height: AppSpacing.space3),
          // Role selection
          Text(
            '관계 선택',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<InquirySenderRole>(
                  segments: const [
                    ButtonSegment(
                      value: InquirySenderRole.student,
                      label: Text('학생'),
                    ),
                    ButtonSegment(
                      value: InquirySenderRole.parent,
                      label: Text('학부모'),
                    ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (selected) {
                    setState(() => _selectedRole = selected.first);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.space4),
          // Name field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: AppStrings.inquiryFormNameLabel,
              hintText: AppStrings.inquiryFormNameHint,
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              contentPadding: EdgeInsets.all(AppSpacing.space3),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '이름을 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: AppSpacing.space3),
          // Phone field
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: AppStrings.inquiryFormPhoneLabel,
              hintText: AppStrings.inquiryFormPhoneHint,
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              contentPadding: EdgeInsets.all(AppSpacing.space3),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '연락처를 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: AppSpacing.space3),
          // Message field
          TextFormField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: AppStrings.inquiryFormMessageLabel,
              hintText: AppStrings.inquiryFormMessageHint,
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              contentPadding: EdgeInsets.all(AppSpacing.space3),
            ),
            maxLines: 5,
            minLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '문의 내용을 입력해주세요';
              }
              if (value.trim().length < 10) {
                return '10글자 이상 입력해주세요';
              }
              return null;
            },
          ),
          SizedBox(height: AppSpacing.space4),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              child: _isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.paper,
                        ),
                      ),
                    )
                  : Text(AppStrings.inquiryFormSubmit),
            ),
          ),
        ],
      ),
    );
  }
}
