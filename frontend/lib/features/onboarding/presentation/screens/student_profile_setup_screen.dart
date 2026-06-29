import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/repository_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../students/students_facade.dart';

// instruments unified to InstrumentList.all (catalog SSOT, §16) — was #920 split

/// Student profile setup screen for student onboarding (step 1 of 2)
class StudentProfileSetupScreen extends ConsumerStatefulWidget {
  const StudentProfileSetupScreen({super.key});

  @override
  ConsumerState<StudentProfileSetupScreen> createState() =>
      _StudentProfileSetupScreenState();
}

class _StudentProfileSetupScreenState
    extends ConsumerState<StudentProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  String? _selectedInstrument;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _selectedInstrument != null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedInstrument == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (ref.read(mockDataModeProvider)) {
        // Mock mode: use existing student provider
        final student = Student(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          instrument: _selectedInstrument!,
          level: StudentLevel.beginner,
          status: StudentStatus.trial,
          createdAt: DateTime.now(),
        );
        await ref.read(studentsNotifierProvider.notifier).addStudent(student);
      } else {
        // Remote mode: call student self-profile API
        final apiClient = ref.read(apiClientProvider);
        await apiClient.post(
          '/students/me/profile',
          data: {
            'name': _nameController.text.trim(),
            'instrument': _selectedInstrument!,
            'level': 'beginner',
          },
        );
      }

      if (!mounted) return;

      context.go(AppRoutes.studentTutorial);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.onboardingProfileSaveFailure),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.paperAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showInstrumentSelector() {
    showNotebookModalBottomSheet<void>(
      context: context,
      builder:
          (context) => _InstrumentSelectorSheet(
            instruments: InstrumentList.all,
            selectedInstrument: _selectedInstrument,
            onSelected: (instrument) {
              setState(() => _selectedInstrument = instrument);
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
          onPressed: () => context.go(AppRoutes.studentInviteCode),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Form(
                  key: _formKey,
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
                        AppStrings.studentProfileSetupSubtitle,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.space8),

                      // Name input
                      _buildNameInput(),

                      const SizedBox(height: AppSpacing.space6),

                      // Instrument selector
                      _buildInstrumentSection(),
                    ],
                  ),
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
          label: AppStrings.onboardingProfile,
          isActive: true,
        ),
        _ProgressDivider(isActive: false),
        _ProgressStep(
          step: 2,
          label: AppStrings.onboardingTutorial,
          isActive: false,
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
              AppStrings.studentProfileSetupNameLabel,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.space1),
            Text('*', style: TextStyle(color: AppColors.paperAccent)),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        TextFormField(
          controller: _nameController,
          focusNode: _nameFocus,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.studentProfileSetupNameHint;
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: AppStrings.onboardingStudentNameHint,
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: OutlineInputBorder(
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
              AppStrings.studentProfileSetupInstrumentLabel,
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
            ),
            child:
                _selectedInstrument == null
                    ? Row(
                      children: [
                        Icon(Icons.music_note, color: AppColors.inkTertiary),
                        const SizedBox(width: AppSpacing.space2),
                        Text(
                          AppStrings.studentProfileSetupInstrumentHint,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.inkTertiary,
                          ),
                        ),
                      ],
                    )
                    : Row(
                      children: [
                        Chip(
                          label: Text(_selectedInstrument!),
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
                            setState(() => _selectedInstrument = null);
                          },
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }
}

// -- Private widgets --

class _ProgressStep extends StatelessWidget {
  final int step;
  final String label;
  final bool isActive;

  const _ProgressStep({
    required this.step,
    required this.label,
    required this.isActive,
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
              color: isActive ? AppColors.paperAccent : AppColors.inkQuaternary,
              borderRadius: BorderRadius.zero,
            ),
            child: Center(
              child: Text(
                '$step',
                style: AppTypography.bodySmall.copyWith(
                  color: isActive ? AppColors.paper : AppColors.inkTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isActive ? AppColors.ink : AppColors.inkTertiary,
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

class _InstrumentSelectorSheet extends StatelessWidget {
  final List<String> instruments;
  final String? selectedInstrument;
  final ValueChanged<String> onSelected;

  const _InstrumentSelectorSheet({
    required this.instruments,
    required this.selectedInstrument,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const BottomSheetHandle(margin: EdgeInsets.zero),
          const SizedBox(height: AppSpacing.space4),

          // Header — Notebook × Score: 시트 헤더 Playfair sectionTitle (§7.87-f / §7.27).
          Text(
            AppStrings.onboardingSelectInstrument,
            style: NotebookTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space4),

          // Choice chips grid
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space3,
            children:
                instruments.map((instrument) {
                  final isSelected = instrument == selectedInstrument;
                  return ChoiceChip(
                    label: Text(instrument),
                    selected: isSelected,
                    onSelected: (_) {
                      onSelected(instrument);
                      Navigator.pop(context);
                    },
                    selectedColor: AppColors.paperAccent.withValues(
                      alpha: 0.15,
                    ),
                    backgroundColor: AppColors.paper,
                    labelStyle: AppTypography.bodyMedium.copyWith(
                      color: isSelected ? AppColors.paperAccent : AppColors.ink,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color:
                            isSelected
                                ? AppColors.paperAccent
                                : AppColors.inkQuaternary,
                      ),
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
          ),

          const SizedBox(height: AppSpacing.space6),
        ],
      ),
    );
  }
}
