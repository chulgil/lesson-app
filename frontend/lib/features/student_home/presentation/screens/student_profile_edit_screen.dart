// Student profile edit screen for editing name, instrument, and contact info.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/students/domain/entities/student.dart';
import '../../../students/presentation/widgets/student_form/student_form_dialogs.dart';
import '../providers/student_home_profile_edit_provider.dart';

/// Student profile edit screen.
class StudentProfileEditScreen extends ConsumerStatefulWidget {
  const StudentProfileEditScreen({super.key});

  @override
  ConsumerState<StudentProfileEditScreen> createState() =>
      _StudentProfileEditScreenState();
}

class _StudentProfileEditScreenState
    extends ConsumerState<StudentProfileEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  String _selectedInstrument = '바이올린';
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isLoading = true;
  Student? _currentStudent;

  final List<String> _instruments = [
    '바이올린',
    '비올라',
    '첼로',
    '피아노',
    '플루트',
    '클라리넷',
    '기타',
    '드럼',
    '성악',
    '기타 악기',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final student = await ref.read(
        studentHomeProfileEditStudentProvider.future,
      );
      if (student != null && mounted) {
        setState(() {
          _currentStudent = student;
          _nameController.text = student.name;
          _emailController.text = student.email ?? '';
          _phoneController.text = student.phone ?? '';
          _selectedInstrument =
              _instruments.contains(student.instrument)
                  ? student.instrument
                  : '바이올린';
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _onSave() async {
    if (_currentStudent == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final updated = _currentStudent!.copyWith(
        name: _nameController.text.trim(),
        instrument: _selectedInstrument,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      await ref
          .read(studentHomeProfileEditActionsProvider)
          .updateStudent(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.studentHomeProfileSaved)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.studentHomeProfileSaveFailed),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return NotebookScreenScaffold(
        appBar: AppBar(title: const Text(AppStrings.studentHomeProfileEdit)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return NotebookScreenScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.studentHomeProfileEdit),
        actions: [
          TextButton(
            onPressed: _hasChanges && !_isSaving ? _onSave : null,
            child:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(
                      '저장',
                      style: TextStyle(
                        color:
                            _hasChanges
                                ? AppColors.paperAccent
                                : AppColors.inkTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Profile image section
          Center(child: _buildProfileImageSection()),

          const SizedBox(height: AppSpacing.space8),

          // Name field
          _buildFieldLabel('이름'),
          const SizedBox(height: AppSpacing.space2),
          _buildTextField(
            controller: _nameController,
            hintText: AppStrings.studentHomeNameHint,
            onChanged: (_) => _onFieldChanged(),
          ),

          const SizedBox(height: AppSpacing.space5),

          // Instrument field
          _buildFieldLabel('악기'),
          const SizedBox(height: AppSpacing.space2),
          _buildInstrumentSelector(),

          const SizedBox(height: AppSpacing.space5),

          // Email field
          _buildFieldLabel('이메일'),
          const SizedBox(height: AppSpacing.space2),
          _buildTextField(
            controller: _emailController,
            hintText: AppStrings.studentHomeEmailHint,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _onFieldChanged(),
          ),

          const SizedBox(height: AppSpacing.space5),

          // Phone field
          _buildFieldLabel('전화번호'),
          const SizedBox(height: AppSpacing.space2),
          _buildTextField(
            controller: _phoneController,
            hintText: AppStrings.studentHomePhoneHint,
            keyboardType: TextInputType.phone,
            onChanged: (_) => _onFieldChanged(),
          ),

          const SizedBox(height: AppSpacing.space8),

          // Info text
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: AppColors.ink),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    '프로필 정보는 선생님에게 공유됩니다.\n정확한 정보를 입력해주세요.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTypography.bodySmall.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.inkSecondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.inkTertiary,
        ),
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.inkQuaternary),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.inkQuaternary),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.ink, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildInstrumentSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedInstrument,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.inkSecondary),
          style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
          items:
              _instruments.map((instrument) {
                return DropdownMenuItem(
                  value: instrument,
                  child: Text(instrument),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedInstrument = value;
                _hasChanges = true;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    final studentId = _currentStudent?.id;
    final imagePath =
        studentId != null
            ? ref
                .watch(studentHomeProfileEditImagePathProvider(studentId))
                .valueOrNull
            : null;

    return Stack(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.paperDark,
          backgroundImage:
              imagePath != null ? FileImage(File(imagePath)) : null,
          child:
              imagePath == null
                  ? Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text[0]
                        : '?',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : null,
        ),
        // §7.132: round → 사각 카메라 뱃지.
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () => _onTapProfileImage(),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space2),
              decoration: const BoxDecoration(color: AppColors.ink),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: AppColors.paper,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onTapProfileImage() async {
    final studentId = _currentStudent?.id;
    if (studentId == null) return;

    final actions = ref.read(studentHomeProfileEditActionsProvider);
    final currentPath = actions.profileImagePath(studentId);

    final action = await showImagePickerBottomSheet(
      context,
      title: AppStrings.studentHomeProfilePhoto,
      showDelete: currentPath != null,
    );

    if (action == null || !mounted) return;

    if (action == ImagePickerAction.delete) {
      await actions.removeProfileImage(studentId);
      return;
    }

    final source =
        action == ImagePickerAction.camera
            ? ImageSource.camera
            : ImageSource.gallery;

    if (!mounted) return;
    await actions.pickAndSaveProfileImage(studentId, source, context);
  }
}
