import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_detail_app_bar.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';

import '../../../../core/domain/value_objects/expertise_catalog_registry.dart';
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
import '../../../../features/onboarding/onboarding_facade.dart';
import '../../../../core/widgets/onboarding_step_header.dart';

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
  final _nameFocus = FocusNode();

  String? _profileImage;
  List<String> _selectedInstruments = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _selectedInstruments.isNotEmpty;
  }

  List<String> get _missingFields {
    final fields = <String>[];
    if (_nameController.text.trim().isEmpty) {
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
      // v3 §3.2 Phase A: 이름 + 악기 only. introduction 은 Phase C 보상 퀘스트로
      // 이관 (profileIntroduction). 빈 문자열은 backend 호환을 위해 유지.
      final profile = TeacherOnboardingProfile(
        name: _nameController.text.trim(),
        profileImage: _profileImage,
        instruments: _selectedInstruments,
        introduction: '',
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
      // issuance) hard gate. SSO → terms → role → profile (B) → step 4
      // (가용시간 빠른 설정) → home. #P1-7 (teacher-journey audit 2026-08-11):
      // step 4 was built (`FirstAvailabilitySetupScreen`) but never reachable
      // from this flow, so `OnboardingStepHeader.teacherSteps` promised 4
      // steps while only 3 ever ran. completeOnboarding() still fires here
      // (unchanged) — the new step is a plain in-flow navigation, not gated
      // by the router's AuthNeedsOnboarding redirect, so it behaves exactly
      // like the existing NextMissionSpotlight → teacherFirstAvailability
      // push from home (dashboard_tab.dart).
      ref.read(teacherOnboardingNotifierProvider.notifier).completeOnboarding();
      await ref.read(authNotifierProvider.notifier).completeOnboarding();

      if (mounted) {
        context.go(AppRoutes.teacherFirstAvailability);
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
                    AppStrings.profileSetupDeletePhoto,
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

  // #111: 뒤로가기 시 데이터 손실 경고 다이얼로그
  Future<void> _confirmBack(BuildContext context) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.profileSetupBackDialogTitle,
      message: AppStrings.profileSetupBackDialogMessage,
      confirmLabel: AppStrings.profileSetupBackDialogConfirm,
      cancelLabel: AppStrings.profileSetupBackDialogCancel,
      isDestructive: true,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
    if (confirmed == true && context.mounted) {
      context.go(AppRoutes.roleSelect);
    }
  }

  void _showInstrumentSelector() {
    // #1071: list the active discipline's expertise catalog (music =
    // instruments, byte-identical), not a hardcoded music list.
    final items =
        ExpertiseCatalogRegistry.forDiscipline(
          ref.read(activeDisciplineProvider),
        ).items;
    showNotebookBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showHandle: false,
      padding: EdgeInsets.zero,
      builder:
          (context) => _InstrumentSelectorSheet(
            items: items,
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
      appBar: NotebookDetailAppBar(
        title: AppStrings.onboardingProfileSetup,
        onLeadingTap: () => _confirmBack(context), // #111
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
                    // Progress indicator (#1104 — shared 4-step teacher header,
                    // 프로필=3/4). Replaces the former local 2-step indicator.
                    const OnboardingStepHeader(
                      steps: OnboardingStepHeader.teacherSteps,
                      currentStep: 3,
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Title — Notebook × Score: 스텝 타이틀 Playfair sectionTitle (§7.87-f).
                    Text(
                      AppStrings.onboardingProfileSetup,
                      style: NotebookTypography.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      AppStrings.profileSetupSubtitle,
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
                                AppStrings.profileSetupMissingFields(
                                  _missingFields.join(', '),
                                ),
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
              AppStrings.profileSetupNameLabel,
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
              AppStrings.profileSetupInstrumentLabel,
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
                          AppStrings.profileSetupInstrumentHint,
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
}

class _InstrumentSelectorSheet extends StatefulWidget {
  final List<String> items;
  final List<String> selectedInstruments;
  final ValueChanged<List<String>> onSelectionChanged;

  const _InstrumentSelectorSheet({
    required this.items,
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
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final instrument = widget.items[index];
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
