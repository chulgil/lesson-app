import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/profile/teacher_extended_profile_provider.dart';

/// Screen for editing basic profile info (name and introduction)
class BasicInfoEditScreen extends ConsumerStatefulWidget {
  const BasicInfoEditScreen({super.key});

  @override
  ConsumerState<BasicInfoEditScreen> createState() =>
      _BasicInfoEditScreenState();
}

class _BasicInfoEditScreenState extends ConsumerState<BasicInfoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _introductionController = TextEditingController();

  bool _isLoading = false;

  static const int _minIntroductionLength = 20;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final profileState = ref.read(teacherExtendedProfileProvider);
    final profile = profileState.valueOrNull;
    if (profile != null) {
      _nameController.text = profile.name;
      _introductionController.text = profile.introduction;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _introductionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(teacherExtendedProfileProvider.notifier)
          .updateBasicInfo(
            name: _nameController.text.trim(),
            introduction: _introductionController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 중 오류가 발생했습니다. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기본 정보 수정'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '저장',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // Name field
            _buildLabel('이름', required: true),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(
                hintText: '예: 홍길동',
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '이름을 입력해주세요';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.space6),

            // Introduction field
            _buildLabel('소개글', required: true),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _introductionController,
              decoration: _inputDecoration(
                hintText: '선생님을 소개해주세요 (최소 $_minIntroductionLength자)',
              ),
              maxLines: 6,
              minLines: 4,
              textInputAction: TextInputAction.newline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '소개글을 입력해주세요';
                }
                if (value.trim().length < _minIntroductionLength) {
                  return '소개글은 최소 $_minIntroductionLength자 이상 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.space2),
            _buildCharacterCount(),

            const SizedBox(height: AppSpacing.space6),

            // Save button
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLarge),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '저장하기',
                        style: AppTypography.button,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildCharacterCount() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _introductionController,
      builder: (context, value, _) {
        final length = value.text.trim().length;
        final isSufficient = length >= _minIntroductionLength;
        return Align(
          alignment: Alignment.centerRight,
          child: Text(
            isSufficient ? '$length자' : '$length자 (최소 $_minIntroductionLength자)',
            style: AppTypography.caption.copyWith(
              color: isSufficient
                  ? AppColors.textTertiaryLight
                  : AppColors.error,
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }
}
