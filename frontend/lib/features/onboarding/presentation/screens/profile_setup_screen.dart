import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../features/auth/auth_facade.dart';
import '../../../../features/profile/domain/entities/teacher_onboarding.dart';
import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../../features/onboarding/onboarding_facade.dart';

typedef OnboardingProfileImageSaver =
    Future<String> Function(String sourcePath, String fileName);

typedef OnboardingProfileImageCropper =
    Future<String?> Function(String sourcePath);

@visibleForTesting
Future<String?> saveOnboardingProfileImage({
  required XFile pickedImage,
  required OnboardingProfileImageCropper cropper,
  required OnboardingProfileImageSaver saver,
  required String fileName,
}) async {
  final croppedPath = await cropper(pickedImage.path);
  final sourcePath = croppedPath ?? pickedImage.path;
  return saver(sourcePath, fileName);
}

/// Profile setup screen for teacher onboarding
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  static const instrumentSelectorKey = Key('profile_setup_instrument_selector');

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
    return _nameController.text.isNotEmpty && _selectedInstruments.isNotEmpty;
  }

  List<String> get _missingFields {
    final fields = <String>[];
    if (_nameController.text.isEmpty) {
      fields.add(AppStrings.onboardingFieldName);
    }
    if (_selectedInstruments.isEmpty) {
      fields.add(AppStrings.onboardingFieldInstrument);
    }
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

      // Persist the entered name/instruments/introduction to the backend
      // (PUT /teachers/me/profile, upsert). Without this the onboarding
      // profile is only held in memory and is lost on completion. (#14)
      await ref
          .read(currentTeacherProfileNotifierProvider.notifier)
          .createFromOnboarding(ref.read(teacherOnboardingNotifierProvider));

      // #430: Phone verification moved to optional quest + E3 (subscription
      // issuance) hard gate. SSO → terms → role → profile (B) → home direct.
      ref.read(teacherOnboardingNotifierProvider.notifier).completeOnboarding();
      await ref.read(authNotifierProvider.notifier).completeOnboarding();

      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.onboardingProfileSaveError),
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
    final source = await showNotebookBottomSheet<ImageSource>(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text(AppStrings.onboardingSelectFromGallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text(AppStrings.onboardingTakePhoto),
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
    );

    if (source == null || !mounted) return;

    try {
      final picked = await pickImage(source);
      if (picked == null || !mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.onboardingProfileImageCanceled),
            ),
          );
        }
        return;
      }

      final savedPath = await saveOnboardingProfileImage(
        pickedImage: picked,
        cropper: (sourcePath) => cropProfileImage(sourcePath, context),
        saver: saveProfileImage,
        fileName: 'onboarding_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted || savedPath == null) return;

      setState(() => _profileImage = savedPath);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.onboardingProfileImageError)),
      );
    }
  }

  void _showInstrumentSelector() {
    showNotebookBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showHandle: false,
      padding: EdgeInsets.zero,
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
    return NotebookScreenScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.onboardingProfileSetup),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.roleSelect),
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
                    Text(
                      AppStrings.onboardingProfileSetup,
                      style: NotebookTypography.sectionTitle,
                    ),
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
                          color: AppColors.paperAccentSoft,
                          borderRadius: BorderRadius.zero,
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
                    const SizedBox(height: AppSpacing.buttonHeight),
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
                    foregroundColor: AppColors.paper,
                    disabledBackgroundColor: AppColors.inkQuaternary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
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
                            AppStrings.onboardingNext,
                            style: AppTypography.button,
                          ),
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
          label: AppStrings.onboardingProfileSetup,
          isActive: true,
        ),
        _ProgressDivider(isActive: false),
        _ProgressStep(
          step: 2,
          label: AppStrings.onboardingContinueWithQuest,
          isActive: false,
        ),
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
              AppStrings.onboardingProfilePhotoOptional,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          AppStrings.onboardingProfilePhotoTrustHint,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        Center(
          child: GestureDetector(
            key: const Key('profile_setup_profile_image_picker'),
            onTap: _selectProfileImage,
            child: Stack(
              children: [
                Container(
                  key: const Key('profile_setup_profile_image_preview'),
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
                      border: Border.all(color: AppColors.paper, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppColors.paper,
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
            hintText: AppStrings.onboardingNameHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
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
          key: ProfileSetupScreen.instrumentSelectorKey,
          onTap: _showInstrumentSelector,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.inkQuaternary),
              borderRadius: BorderRadius.zero,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '소개 (선택)',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$charCount / 500자',
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
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
            hintText: AppStrings.onboardingIntroOptionalHint,
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
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
              borderRadius: BorderRadius.zero,
            ),
            child: Center(
              child:
                  isCompleted
                      ? const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.paper,
                      )
                      : Text(
                        '$step',
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              isActive
                                  ? AppColors.paper
                                  : AppColors.inkTertiary,
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
      key: const Key('profile_setup_instrument_selector_sheet'),
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
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
              Text(
                AppStrings.onboardingSelectInstrument,
                style: NotebookTypography.sectionTitle,
              ),
              TextButton(
                onPressed: () {
                  widget.onSelectionChanged(_selected);
                  Navigator.pop(context);
                },
                child: Text(
                  AppStrings.confirm,
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
                    final next = List<String>.from(_selected);
                    setState(() {
                      if (isSelected) {
                        next.remove(instrument);
                      } else {
                        next.add(instrument);
                      }
                      _selected = next;
                    });
                    widget.onSelectionChanged(next);
                    Navigator.pop(context);
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
