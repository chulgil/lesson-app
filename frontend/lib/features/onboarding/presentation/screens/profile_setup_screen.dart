import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/teacher_onboarding.dart';
import '../../../../models/teacher_settings.dart';
import '../../../../providers/onboarding/onboarding_providers.dart';

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

    final profile = TeacherOnboardingProfile(
      name: _nameController.text,
      profileImage: _profileImage,
      instruments: _selectedInstruments,
      introduction: _introController.text,
    );

    ref.read(teacherOnboardingNotifierProvider.notifier).updateProfile(profile);
    ref.read(teacherOnboardingNotifierProvider.notifier).submitProfile();

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _isLoading = false);

    if (mounted) {
      context.go(AppRoutes.teacherTutorial);
    }
  }

  Future<void> _selectProfileImage() async {
    // Mock image selection - in real app, use image_picker
    setState(() {
      _profileImage = 'https://example.com/profile.jpg';
    });
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
      builder: (context) => _InstrumentSelectorSheet(
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

                    // Title
                    Text(
                      '프로필 설정',
                      style: AppTypography.headingLarge,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      '학생들에게 보여질 기본 정보를 설정해주세요',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondaryLight,
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
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.space2),
                            Expanded(
                              child: Text(
                                '필수 항목: ${_missingFields.join(', ')}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.warning,
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.borderLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
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
                          '다음',
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
        _ProgressStep(step: 1, label: '휴대폰 인증', isActive: false, isCompleted: true),
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
            Text(
              '*',
              style: TextStyle(color: AppColors.error),
            ),
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
                    color: AppColors.borderLight,
                    shape: BoxShape.circle,
                    image: _profileImage != null
                        ? DecorationImage(
                            image: NetworkImage(_profileImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _profileImage == null
                      ? Icon(
                          Icons.person,
                          size: 48,
                          color: AppColors.textTertiaryLight,
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
                      color: AppColors.primary,
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
            Text(
              '*',
              style: TextStyle(color: AppColors.error),
            ),
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
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
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
            Text(
              '*',
              style: TextStyle(color: AppColors.error),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        GestureDetector(
          onTap: _showInstrumentSelector,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: _selectedInstruments.isEmpty
                ? Row(
                    children: [
                      Icon(
                        Icons.add,
                        color: AppColors.textTertiaryLight,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        '악기를 선택해주세요',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space2,
                    children: _selectedInstruments.map((instrument) {
                      return Chip(
                        label: Text(instrument),
                        labelStyle: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                        ),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        deleteIcon: Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.primary,
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
                Text(
                  '*',
                  style: TextStyle(color: AppColors.error),
                ),
              ],
            ),
            Text(
              '$charCount / 20자 이상',
              style: AppTypography.caption.copyWith(
                color: isValid ? AppColors.success : AppColors.textTertiaryLight,
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
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
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
              color: isActive || isCompleted
                  ? AppColors.primary
                  : AppColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '$step',
                      style: AppTypography.bodySmall.copyWith(
                        color: isActive
                            ? Colors.white
                            : AppColors.textTertiaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isActive || isCompleted
                  ? AppColors.textPrimaryLight
                  : AppColors.textTertiaryLight,
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
      color: isActive ? AppColors.primary : AppColors.borderLight,
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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '악기 선택',
                style: AppTypography.headingMedium,
              ),
              TextButton(
                onPressed: () {
                  widget.onSelectionChanged(_selected);
                  Navigator.pop(context);
                },
                child: Text(
                  '완료',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.primary,
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
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: AppColors.primary)
                      : Icon(Icons.circle_outlined, color: AppColors.borderLight),
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
