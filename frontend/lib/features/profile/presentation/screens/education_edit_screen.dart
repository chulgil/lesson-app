import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/profile_facade.dart';

/// Screen for adding or editing education record
class EducationEditScreen extends ConsumerStatefulWidget {
  final int? index;

  const EducationEditScreen({super.key, this.index});

  @override
  ConsumerState<EducationEditScreen> createState() =>
      _EducationEditScreenState();
}

class _EducationEditScreenState extends ConsumerState<EducationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolController = TextEditingController();
  final _majorController = TextEditingController();
  final _graduationYearController = TextEditingController();

  String _selectedDegree = 'bachelor';
  bool _isLoading = false;
  bool _isEdit = false;

  final List<Map<String, String>> _degreeOptions = [
    {'value': 'high_school', 'label': '고등학교'},
    {'value': 'certificate', 'label': '수료'},
    {'value': 'associate', 'label': '전문학사'},
    {'value': 'bachelor', 'label': '학사'},
    {'value': 'master', 'label': '석사'},
    {'value': 'doctor', 'label': '박사'},
  ];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.index != null;
    if (_isEdit) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final profileState = ref.read(teacherExtendedProfileProvider);
    final profile = profileState.valueOrNull;
    if (profile != null &&
        profile.education != null &&
        widget.index! < profile.education!.length) {
      final education = profile.education![widget.index!];
      _schoolController.text = education.school;
      _majorController.text = education.major;
      _selectedDegree = education.degree;
      _graduationYearController.text =
          education.graduationYear?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _majorController.dispose();
    _graduationYearController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final education = Education(
      school: _schoolController.text.trim(),
      major:
          _majorController.text.trim().isEmpty
              ? ''
              : _majorController.text.trim(),
      degree: _selectedDegree,
      graduationYear:
          _graduationYearController.text.isEmpty
              ? null
              : int.tryParse(_graduationYearController.text),
    );

    try {
      if (_isEdit) {
        await ref
            .read(teacherExtendedProfileProvider.notifier)
            .updateEducation(widget.index!, education);
      } else {
        await ref
            .read(teacherExtendedProfileProvider.notifier)
            .addEducation(education);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.profileSaveErrorRetry)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _delete() async {
    if (!_isEdit) return;

    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.profileEducationDeleteTitle,
      content: const Text(AppStrings.profileEducationDeleteConfirm),
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref
            .read(teacherExtendedProfileProvider.notifier)
            .removeEducation(widget.index!);
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.profileDeleteErrorRetry)),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: _isEdit
            ? AppStrings.profileEducationEditTitle
            : AppStrings.profileEducationAddTitle,
        actions: [if (_isEdit) DetailAppBarAction.delete],
        onAction: (action) {
          if (action == DetailAppBarAction.delete) {
            if (!_isLoading) _delete();
          }
        },
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // School name
            _buildLabel('학교명', required: true),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _schoolController,
              decoration: _inputDecoration(
                hintText: AppStrings.profileEducationHintSchool,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '학교명을 입력해주세요';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.space4),

            // Degree
            _buildLabel('학위'),
            const SizedBox(height: AppSpacing.space2),
            DropdownButtonFormField<String>(
              initialValue: _selectedDegree,
              decoration: _inputDecoration(),
              items:
                  _degreeOptions.map((option) {
                    return DropdownMenuItem(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDegree = value);
                }
              },
            ),

            const SizedBox(height: AppSpacing.space4),

            // Major
            _buildLabel('전공'),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _majorController,
              decoration: _inputDecoration(
                hintText: AppStrings.profileEducationHintMajor,
              ),
            ),

            const SizedBox(height: AppSpacing.space4),

            // Graduation year
            _buildLabel('졸업연도'),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _graduationYearController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: _inputDecoration(
                hintText: AppStrings.profileEducationHintGradYear,
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final year = int.tryParse(value);
                  if (year == null || year < 1950 || year > 2030) {
                    return '올바른 연도를 입력해주세요';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.space6),

            // Save button
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.paperAccent,
                  foregroundColor: AppColors.paper,
                  shape: const RoundedRectangleBorder(),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.paper,
                          ),
                        )
                        : Text(
                          _isEdit ? '수정하기' : '추가하기',
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
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        if (required)
          Text(
            ' *',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.inkQuaternary),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.paperAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.paperAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.paperAccent, width: 2),
      ),
    );
  }
}
