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

/// Screen for adding or editing career record
class CareerEditScreen extends ConsumerStatefulWidget {
  final int? index;

  const CareerEditScreen({super.key, this.index});

  @override
  ConsumerState<CareerEditScreen> createState() => _CareerEditScreenState();
}

class _CareerEditScreenState extends ConsumerState<CareerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _organizationController = TextEditingController();
  final _positionController = TextEditingController();
  final _startYearController = TextEditingController();
  final _endYearController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isCurrentlyWorking = false;
  bool _isLoading = false;
  bool _isEdit = false;

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
        profile.career != null &&
        widget.index! < profile.career!.length) {
      final career = profile.career![widget.index!];
      _organizationController.text = career.organization;
      _positionController.text = career.position;
      _startYearController.text = career.startYear.toString();
      _endYearController.text = career.endYear?.toString() ?? '';
      _descriptionController.text = career.description ?? '';
      _isCurrentlyWorking = career.endYear == null;
    }
  }

  @override
  void dispose() {
    _organizationController.dispose();
    _positionController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final startYear =
        int.tryParse(_startYearController.text) ?? DateTime.now().year;

    final career = Career(
      organization: _organizationController.text.trim(),
      position:
          _positionController.text.trim().isEmpty
              ? ''
              : _positionController.text.trim(),
      startYear: startYear,
      endYear:
          _isCurrentlyWorking ? null : int.tryParse(_endYearController.text),
      description:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
    );

    try {
      if (_isEdit) {
        await ref
            .read(teacherExtendedProfileProvider.notifier)
            .updateCareer(widget.index!, career);
      } else {
        await ref
            .read(teacherExtendedProfileProvider.notifier)
            .addCareer(career);
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
      title: AppStrings.profileCareerDeleteTitle,
      content: const Text(AppStrings.profileCareerDeleteConfirm),
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
            .removeCareer(widget.index!);
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
            ? AppStrings.profileCareerEditTitle
            : AppStrings.profileCareerAddTitle,
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
            // Organization
            _buildLabel('기관/단체명', required: true),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _organizationController,
              decoration: _inputDecoration(
                hintText: AppStrings.profileCareerHintOrganization,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '기관/단체명을 입력해주세요';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.space4),

            // Position
            _buildLabel('직위/역할'),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _positionController,
              decoration: _inputDecoration(
                hintText: AppStrings.profileCareerHintPosition,
              ),
            ),

            const SizedBox(height: AppSpacing.space4),

            // Period
            _buildLabel('재직 기간'),
            const SizedBox(height: AppSpacing.space2),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startYearController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: _inputDecoration(
                      hintText: AppStrings.profileCareerHintStartYear,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final year = int.tryParse(value);
                        if (year == null || year < 1950 || year > 2030) {
                          return '올바른 연도';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.space2),
                  child: Text('~'),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _endYearController,
                    keyboardType: TextInputType.number,
                    enabled: !_isCurrentlyWorking,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: _inputDecoration(
                      hintText:
                          _isCurrentlyWorking
                              ? AppStrings.profileCareerHintEndYearCurrent
                              : AppStrings.profileCareerHintEndYear,
                    ),
                    validator: (value) {
                      if (!_isCurrentlyWorking &&
                          value != null &&
                          value.isNotEmpty) {
                        final year = int.tryParse(value);
                        if (year == null || year < 1950 || year > 2030) {
                          return '올바른 연도';
                        }
                        final startYear = int.tryParse(
                          _startYearController.text,
                        );
                        if (startYear != null && year < startYear) {
                          return '시작년도 이후';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space2),

            // Currently working checkbox
            Row(
              children: [
                Checkbox(
                  value: _isCurrentlyWorking,
                  onChanged: (value) {
                    setState(() {
                      _isCurrentlyWorking = value ?? false;
                      if (_isCurrentlyWorking) {
                        _endYearController.clear();
                      }
                    });
                  },
                  activeColor: AppColors.paperAccent,
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCurrentlyWorking = !_isCurrentlyWorking;
                      if (_isCurrentlyWorking) {
                        _endYearController.clear();
                      }
                    });
                  },
                  child: Text(
                    AppStrings.profileCareerCurrentlyWorking,
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space4),

            // Description
            _buildLabel('설명'),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 200,
              decoration: _inputDecoration(
                hintText: AppStrings.profileCareerHintDescription,
              ),
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
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.inkQuaternary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
