import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/presentation/providers/teacher_extended_profile_provider.dart';

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
          const SnackBar(content: Text('저장 중 오류가 발생했습니다. 다시 시도해주세요.')),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('경력 삭제'),
            content: const Text('이 경력 정보를 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.paperAccent,
                ),
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
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
            const SnackBar(content: Text('삭제 중 오류가 발생했습니다. 다시 시도해주세요.')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '경력 수정' : '경력 추가'),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _isLoading ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.paperAccent,
            ),
        ],
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
              decoration: _inputDecoration(hintText: '예: 서울시립교향악단'),
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
              decoration: _inputDecoration(hintText: '예: 제1바이올린 단원'),
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
                    decoration: _inputDecoration(hintText: '시작년도'),
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
                      hintText: _isCurrentlyWorking ? '현재' : '종료년도',
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
                  child: Text('현재 재직 중', style: AppTypography.bodyMedium),
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
              decoration: _inputDecoration(hintText: '담당 업무나 주요 활동 내용을 입력해주세요'),
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
