import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../features/profile/domain/entities/teacher_onboarding.dart';
import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../../features/onboarding/presentation/providers/onboarding_providers.dart';

/// Profile setup screen for teacher onboarding
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _introController = TextEditingController();
  final _nameFocus = FocusNode();
  final _introFocus = FocusNode();

  String? _profileImage;
  List<String> _selectedInstruments = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _introController.dispose();
    _nameFocus.dispose();
    _introFocus.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _nameController.text.isNotEmpty &&
        _profileImage != null &&
        _selectedInstruments.isNotEmpty &&
        _introController.text.length >= 20;
  }

  List<String> get _missingFields {
    final fields = <String>[];
    if (_nameController.text.isEmpty) fields.add('이름');
    if (_profileImage == null) fields.add('프로필 사진');
    if (_selectedInstruments.isEmpty) fields.add('악기');
    if (_introController.text.length < 20) fields.add('소개글 (20자 이상)');
    return fields;
  }

  Future<void> _submit() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      final profile = TeacherOnboardingProfile(
        name: _nameController.text,
        profileImage: _profileImage,
        instruments: _selectedInstruments,
        introduction: _introController.text,
      );

      ref
          .read(teacherOnboardingNotifierProvider.notifier)
          .updateProfile(profile);
      ref.read(teacherOnboardingNotifierProvider.notifier).submitProfile();

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        context.go(AppRoutes.teacherTutorial);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('프로필 저장 중 오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectProfileImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('갤러리에서 선택'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('카메라로 촬영'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  if (_profileImage != null)
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: AppColors.paperAccent,
                      ),
                      title: Text(
                        '사진 삭제',
                        style: TextStyle(color: AppColors.paperAccent),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _profileImage = null);
                      },
                    ),
                ],
              ),
            ),
          ),
    );

    if (source == null || !mounted) return;

    final picked = await pickImage(source);
    if (picked == null || !mounted) return;

    final croppedPath = await cropProfileImage(picked.path, context);
    if (croppedPath == null || !mounted) return;

    final savedPath = await saveProfileImage(
      croppedPath,
      'onboarding_${DateTime.now().millisecondsSinceEpoch}',
    );

    setState(() => _profileImage = savedPath);
  }

  void _showInstrumentSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      builder:
          (context) => _InstrumentSelectorSheet(
            selectedInstruments: _selectedInstruments,
            onSelectionChanged: (instruments) {
              setState(() => _selectedInstruments = instruments);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 설정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.teacherPhoneVerification),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress indicator
                    _buildProgressIndicator(),

                    const SizedBox(height: AppSpacing.space6),

                    // Title — Notebook × Score: 스텝 타이틀 Playfair sectionTitle (§7.87-f).
                    Text('프로필 설정', style: NotebookTypography.sectionTitle),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      '학생들에게 보여질 기본 정보를 설정해주세요',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Profile image
                    _buildProfileImageSection(),

                    const SizedBox(height: AppSpacing.space5),

                    // Name input
                    _buildNameInput(),

                    const SizedBox(height: AppSpacing.space5),

                    // Instrument selector
                    _buildInstrumentSection(),

                    const SizedBox(height: AppSpacing.space5),

                    // Introduction
                    _buildIntroductionInput(),

                    const SizedBox(height: AppSpacing.space4),

                    // Missing fields warning
                    if (_missingFields.isNotEmpty && !_isLoading)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.space3),
                        decoration: BoxDecoration(
                          color: AppColors.paperAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMedium,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.paperAccent,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.space2),
                            Expanded(
                              child: Text(
                                '필수 항목: ${_missingFields.join(', ')}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.paperAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Submit button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading || !_isFormValid ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.paperAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.inkQuaternary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusLarge,
                      ),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text('다음', style: AppTypography.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _ProgressStep(
          step: 1,
          label: '휴대폰 인증',
          isActive: false,
          isCompleted: true,
        ),
        _ProgressDivider(isActive: true),
        _ProgressStep(step: 2, label: '프로필 설정', isActive: true),
        _ProgressDivider(isActive: false),
        _ProgressStep(step: 3, label: '튜토리얼', isActive: false),
      ],
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '프로필 사진',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.space1),
            Text('*', style: TextStyle(color: AppColors.paperAccent)),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        Center(
          child: GestureDetector(
            onTap: _selectProfileImage,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.inkQuaternary,
                    shape: BoxShape.circle,
                    image:
                        _profileImage != null
                            ? DecorationImage(
                              image:
                                  _profileImage!.startsWith('http')
                                      ? NetworkImage(_profileImage!)
                                          as ImageProvider
                                      : FileImage(File(_profileImage!)),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      _profileImage == null
                          ? Icon(
                            Icons.person,
                            size: 48,
                            color: AppColors.inkTertiary,
                          )
                          : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.paperAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '이름',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.space1),
            Text('*', style: TextStyle(color: AppColors.paperAccent)),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: _nameController,
          focusNode: _nameFocus,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '선생님 이름을 입력해주세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.paperAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstrumentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '악기',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.space1),
            Text('*', style: TextStyle(color: AppColors.paperAccent)),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        GestureDetector(
          onTap: _showInstrumentSelector,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.inkQuaternary),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child:
                _selectedInstruments.isEmpty
                    ? Row(
                      children: [
                        Icon(Icons.add, color: AppColors.inkTertiary),
                        const SizedBox(width: AppSpacing.space2),
                        Text(
                          '악기를 선택해주세요',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.inkTertiary,
                          ),
                        ),
                      ],
                    )
                    : Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space2,
                      children:
                          _selectedInstruments.map((instrument) {
                            return Chip(
                              label: Text(instrument),
                              labelStyle: AppTypography.bodySmall.copyWith(
                                color: AppColors.paperAccent,
                              ),
                              backgroundColor: AppColors.paperAccent.withValues(
                                alpha: 0.1,
                              ),
                              deleteIcon: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.paperAccent,
                              ),
                              onDeleted: () {
                                setState(() {
                                  _selectedInstruments.remove(instrument);
                                });
                              },
                            );
                          }).toList(),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntroductionInput() {
    final charCount = _introController.text.length;
    final isValid = charCount >= 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '소개',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                Text('*', style: TextStyle(color: AppColors.paperAccent)),
              ],
            ),
            Text(
              '$charCount / 20자 이상',
              style: AppTypography.caption.copyWith(
                color: isValid ? AppColors.paperOk : AppColors.inkTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: _introController,
          focusNode: _introFocus,
          maxLines: 4,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '학생들에게 보여질 자기소개를 작성해주세요 (20자 이상)',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.paperAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final int step;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _ProgressStep({
    required this.step,
    required this.label,
    required this.isActive,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  isActive || isCompleted
                      ? AppColors.paperAccent
                      : AppColors.inkQuaternary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child:
                  isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                        '$step',
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              isActive ? Colors.white : AppColors.inkTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color:
                  isActive || isCompleted
                      ? AppColors.ink
                      : AppColors.inkTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProgressDivider extends StatelessWidget {
  final bool isActive;

  const _ProgressDivider({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: AppSpacing.space5),
      color: isActive ? AppColors.paperAccent : AppColors.inkQuaternary,
    );
  }
}

class _InstrumentSelectorSheet extends StatefulWidget {
  final List<String> selectedInstruments;
  final ValueChanged<List<String>> onSelectionChanged;

  const _InstrumentSelectorSheet({
    required this.selectedInstruments,
    required this.onSelectionChanged,
  });

  @override
  State<_InstrumentSelectorSheet> createState() =>
      _InstrumentSelectorSheetState();
}

class _InstrumentSelectorSheetState extends State<_InstrumentSelectorSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedInstruments);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          // Handle
          const BottomSheetHandle(margin: EdgeInsets.zero),
          const SizedBox(height: AppSpacing.space4),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Notebook × Score: 시트 헤더 Playfair sectionTitle (§7.87-f / §7.27).
              Text('악기 선택', style: NotebookTypography.sectionTitle),
              TextButton(
                onPressed: () {
                  widget.onSelectionChanged(_selected);
                  Navigator.pop(context);
                },
                child: Text(
                  '완료',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          // Instrument list
          Expanded(
            child: ListView.builder(
              itemCount: InstrumentList.all.length,
              itemBuilder: (context, index) {
                final instrument = InstrumentList.all[index];
                final isSelected = _selected.contains(instrument);

                return ListTile(
                  title: Text(instrument),
                  trailing:
                      isSelected
                          ? Icon(
                            Icons.check_circle,
                            color: AppColors.paperAccent,
                          )
                          : Icon(
                            Icons.circle_outlined,
                            color: AppColors.inkQuaternary,
                          ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(instrument);
                      } else {
                        _selected.add(instrument);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
