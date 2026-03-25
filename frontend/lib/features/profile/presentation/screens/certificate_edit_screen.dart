import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../providers/profile/teacher_extended_profile_provider.dart';

/// Screen for adding or editing certificate
class CertificateEditScreen extends ConsumerStatefulWidget {
  final String? certificateId;

  const CertificateEditScreen({super.key, this.certificateId});

  @override
  ConsumerState<CertificateEditScreen> createState() =>
      _CertificateEditScreenState();
}

class _CertificateEditScreenState extends ConsumerState<CertificateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _issuingBodyController = TextEditingController();
  final _certificateNumberController = TextEditingController();

  CertificateType _selectedType = CertificateType.musicTeacher;
  DateTime _issueDate = DateTime.now();
  bool _isLoading = false;
  bool _isEdit = false;
  Certificate? _existingCertificate;

  final Map<CertificateType, String> _typeLabels = {
    CertificateType.musicTeacher: '음악 교원 자격증',
    CertificateType.cultureArtsEducator: '문화예술교육사',
    CertificateType.schoolTeacher: '학교 교원 자격증',
    CertificateType.conservatory: '음악원 수료증',
    CertificateType.degree: '음악 학위',
    CertificateType.performance: '연주 자격증',
    CertificateType.other: '기타',
  };

  @override
  void initState() {
    super.initState();
    _isEdit = widget.certificateId != null;
    if (_isEdit) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final notifier = ref.read(teacherExtendedProfileProvider.notifier);
    _existingCertificate = notifier.getCertificateById(widget.certificateId!);

    if (_existingCertificate != null) {
      _nameController.text = _existingCertificate!.name;
      _issuingBodyController.text = _existingCertificate!.issuingBody;
      _certificateNumberController.text =
          _existingCertificate!.certificateNumber ?? '';
      _selectedType = _existingCertificate!.type;
      _issueDate = _existingCertificate!.issueDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _issuingBodyController.dispose();
    _certificateNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() => _issueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final certificate = Certificate(
      id: _isEdit ? widget.certificateId! : const Uuid().v4(),
      type: _selectedType,
      name: _nameController.text.trim(),
      issuingBody: _issuingBodyController.text.trim(),
      issueDate: _issueDate,
      certificateNumber: _certificateNumberController.text.trim().isEmpty
          ? null
          : _certificateNumberController.text.trim(),
      // Placeholder image URL - will be replaced with actual upload later
      imageUrl: _isEdit
          ? _existingCertificate!.imageUrl
          : 'https://placeholder.com/certificate/${const Uuid().v4()}.jpg',
      status: CertificateStatus.pending,
      submittedAt: _isEdit ? _existingCertificate!.submittedAt : now,
    );

    try {
      if (_isEdit) {
        await ref
            .read(teacherExtendedProfileProvider.notifier)
            .updateCertificate(widget.certificateId!, certificate);
      } else {
        await ref
            .read(teacherExtendedProfileProvider.notifier)
            .addCertificate(certificate);
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
      builder: (context) => AlertDialog(
        title: const Text('자격증 삭제'),
        content: const Text('이 자격증 정보를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref
            .read(teacherExtendedProfileProvider.notifier)
            .removeCertificate(widget.certificateId!);
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
        title: Text(_isEdit ? '자격증 수정' : '자격증 추가'),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _isLoading ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // Certificate type
            _buildLabel('자격증 종류', required: true),
            const SizedBox(height: AppSpacing.space2),
            DropdownButtonFormField<CertificateType>(
              value: _selectedType,
              decoration: _inputDecoration(),
              items: CertificateType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_typeLabels[type] ?? type.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),

            const SizedBox(height: AppSpacing.space4),

            // Certificate name
            _buildLabel('자격증명', required: true),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(
                hintText: '예: 중등학교 정교사 2급 (음악)',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '자격증명을 입력해주세요';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.space4),

            // Issuing body
            _buildLabel('발급 기관', required: true),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _issuingBodyController,
              decoration: _inputDecoration(
                hintText: '예: 교육부',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '발급 기관을 입력해주세요';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.space4),

            // Issue date
            _buildLabel('발급일'),
            const SizedBox(height: AppSpacing.space2),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_issueDate.year}년 ${_issueDate.month}월 ${_issueDate.day}일',
                      style: AppTypography.bodyMedium,
                    ),
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.textSecondaryLight,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.space4),

            // Certificate number
            _buildLabel('자격증 번호'),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _certificateNumberController,
              decoration: _inputDecoration(
                hintText: '선택사항',
              ),
            ),

            const SizedBox(height: AppSpacing.space4),

            // Image upload placeholder
            _buildLabel('자격증 이미지'),
            const SizedBox(height: AppSpacing.space2),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.borderLight,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                color: AppColors.surfaceSecondaryLight,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      '자격증 이미지 업로드',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '(추후 지원 예정)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.space4),

            // Info box
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      '제출된 자격증은 관리자의 검토 후 승인됩니다. 승인 후 프로필에 인증 뱃지가 표시됩니다.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
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
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
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
                        _isEdit ? '수정하기' : '제출하기',
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
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }
}
