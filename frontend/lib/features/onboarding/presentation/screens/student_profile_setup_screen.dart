import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../students/domain/entities/student.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';

/// Available instruments for student selection
const _instruments = [
  '바이올린',
  '비올라',
  '첼로',
  '피아노',
  '플루트',
  '클라리넷',
  '기타',
  '드럼',
  '성악',
  '작곡',
];

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
      if (EnvironmentConfig.useMockData) {
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
          content: const Text('프로필 저장 실패. 다시 시도해주세요.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showInstrumentSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      builder:
          (context) => _InstrumentSelectorSheet(
            instruments: _instruments,
            selectedInstrument: _selectedInstrument,
            onSelected: (instrument) {
              setState(() => _selectedInstrument = instrument);
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

                      // Title
                      Text('프로필 설정', style: AppTypography.headingLarge),
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        '기본 정보를 설정해주세요',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondaryLight,
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.borderLight,
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
        _ProgressStep(step: 1, label: '프로필', isActive: true),
        _ProgressDivider(isActive: false),
        _ProgressStep(step: 2, label: '튜토리얼', isActive: false),
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
            Text('*', style: TextStyle(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        TextFormField(
          controller: _nameController,
          focusNode: _nameFocus,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '이름을 입력해주세요';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: '이름을 입력해주세요',
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
            Text('*', style: TextStyle(color: AppColors.error)),
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
            child:
                _selectedInstrument == null
                    ? Row(
                      children: [
                        Icon(
                          Icons.music_note,
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
                    : Row(
                      children: [
                        Chip(
                          label: Text(_selectedInstrument!),
                          labelStyle: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          deleteIcon: Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.primary,
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
              color: isActive ? AppColors.primary : AppColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: AppTypography.bodySmall.copyWith(
                  color: isActive ? Colors.white : AppColors.textTertiaryLight,
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
                  isActive
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

          // Header
          Text('악기 선택', style: AppTypography.headingMedium),
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
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundColor: Colors.white,
                    labelStyle: AppTypography.bodyMedium.copyWith(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.textPrimaryLight,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusRound,
                      ),
                      side: BorderSide(
                        color:
                            isSelected
                                ? AppColors.primary
                                : AppColors.borderLight,
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
