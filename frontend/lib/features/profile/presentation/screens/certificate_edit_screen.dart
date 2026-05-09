import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/providers/repository_provider.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/profile_facade.dart';

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
  String? _localImagePath; // Local file path for picked image
  String? _existingImageUrl; // Existing remote image URL (edit mode)

  final Map<CertificateType, String> _typeLabels = {
    CertificateType.musicTeacher: AppStrings.certificateTypeMusicTeacher,
    CertificateType.cultureArtsEducator:
        AppStrings.certificateTypeCultureArtsEducator,
    CertificateType.schoolTeacher: AppStrings.certificateTypeSchoolTeacher,
    CertificateType.conservatory: AppStrings.certificateTypeConservatory,
    CertificateType.degree: AppStrings.certificateTypeDegree,
    CertificateType.performance: AppStrings.certificateTypePerformance,
    CertificateType.other: AppStrings.certificateTypeOther,
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
      _existingImageUrl = _existingCertificate!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final source = await showNotebookBottomSheet<ImageSource>(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text(AppStrings.imageSourceCamera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text(AppStrings.imageSourceGallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
    );

    if (source == null) return;

    final picked = await pickImage(source);
    if (picked == null) return;

    setState(() {
      _localImagePath = picked.path;
    });
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
    final certId = _isEdit ? widget.certificateId! : const Uuid().v4();

    // Upload image if a new one was picked
    String? imageUrl = _isEdit ? _existingCertificate!.imageUrl : null;
    if (_localImagePath != null) {
      final apiClient = ref.read(apiClientProvider);
      final uploadService = ImageUploadService(
        apiClient,
        useMockData: ref.read(mockDataModeProvider),
      );
      final remoteUrl = await uploadService.uploadImage(
        filePath: _localImagePath!,
        imageType: 'certificate',
        entityType: 'teacher',
        entityId: certId,
      );
      if (remoteUrl != null) {
        imageUrl = remoteUrl;
      } else {
        // Mock mode or upload failed — use local path as fallback
        imageUrl = _localImagePath;
      }
    }

    final certificate = Certificate(
      id: certId,
      type: _selectedType,
      name: _nameController.text.trim(),
      issuingBody: _issuingBodyController.text.trim(),
      issueDate: _issueDate,
      certificateNumber:
          _certificateNumberController.text.trim().isEmpty
              ? null
              : _certificateNumberController.text.trim(),
      imageUrl: imageUrl ?? '',
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
          const SnackBar(content: Text(AppStrings.certificateSaveErrorRetry)),
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
      title: AppStrings.certificateDeleteDialogTitle,
      content: const Text(AppStrings.certificateDeleteConfirm),
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
            .removeCertificate(widget.certificateId!);
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.certificateDeleteErrorRetry),
            ),
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
            ? AppStrings.certificateEditAppBarEdit
            : AppStrings.certificateEditAppBarAdd,
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
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.screenPadding,
            AppSpacing.screenPadding,
            AppSpacing.screenPadding +
                MediaQuery.of(context).padding.bottom +
                32,
          ),
          children: [
            // Certificate type
            _buildLabel(AppStrings.certificateTypeLabel, required: true),
            const SizedBox(height: AppSpacing.space2),
            DropdownButtonFormField<CertificateType>(
              initialValue: _selectedType,
              decoration: _inputDecoration(),
              items:
                  CertificateType.values.map((type) {
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
            _buildLabel(AppStrings.certificateNameLabel, required: true),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(
                hintText: AppStrings.certificateNameHint,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.certificateNameRequired;
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.space4),

            // Issuing body
            _buildLabel(AppStrings.certificateIssuingBodyLabel, required: true),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _issuingBodyController,
              decoration: _inputDecoration(
                hintText: AppStrings.certificateIssuingBodyHint,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.certificateIssuingBodyRequired;
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.space4),

            // Issue date
            _buildLabel(AppStrings.certificateIssueDateLabel),
            const SizedBox(height: AppSpacing.space2),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.inkQuaternary),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDateYMDKorean(_issueDate),
                      style: AppTypography.bodyMedium,
                    ),
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.inkSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.space4),

            // Certificate number
            _buildLabel(AppStrings.certificateNumberLabel),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _certificateNumberController,
              decoration: _inputDecoration(
                hintText: AppStrings.certificateNumberHint,
              ),
            ),

            const SizedBox(height: AppSpacing.space4),

            // Image upload
            _buildLabel(AppStrings.certificateImageLabel),
            const SizedBox(height: AppSpacing.space2),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.inkQuaternary,
                    style: BorderStyle.solid,
                  ),
                  color: AppColors.paperDark,
                ),
                clipBehavior: Clip.hardEdge,
                child: _buildImageContent(),
              ),
            ),
            if (_localImagePath != null || _existingImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space2),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _localImagePath = null;
                      _existingImageUrl = null;
                    });
                  },
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.paperAccent,
                  ),
                  label: Text(
                    AppStrings.certificateImageDeleteLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.paperAccent,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.space4),

            // Info box
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.ink),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      AppStrings.certificateInfoBox,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.ink,
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
                          _isEdit
                              ? AppStrings.certificateUpdateButton
                              : AppStrings.certificateSubmitButton,
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

  Widget _buildImageContent() {
    // Show locally picked image
    if (_localImagePath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(_localImagePath!), fit: BoxFit.cover),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space1,
              ),
              decoration: BoxDecoration(
                // Notebook × Score: 이미지 썸네일 위 '탭하여 변경' 배지 — Material
                // AppColors.inkScrim 대신 ink 55% alpha 토큰 사용 (§7.47 grey 이식 패턴).
                color: AppColors.inkTertiary,
                borderRadius: BorderRadius.zero,
              ),
              child: Text(
                AppStrings.tapToChange,
                style: AppTypography.caption.copyWith(color: AppColors.paper),
              ),
            ),
          ),
        ],
      );
    }

    // Show existing remote image (edit mode)
    if (_existingImageUrl != null &&
        !_existingImageUrl!.startsWith('https://placeholder.com')) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _existingImageUrl!.startsWith('/')
              ? Image.file(File(_existingImageUrl!), fit: BoxFit.cover)
              : Image.network(
                _existingImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildEmptyImagePlaceholder(),
              ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space1,
              ),
              decoration: BoxDecoration(
                // Notebook × Score: 같은 '탭하여 변경' 배지 — ink 55% alpha 토큰.
                color: AppColors.inkTertiary,
                borderRadius: BorderRadius.zero,
              ),
              child: Text(
                AppStrings.tapToChange,
                style: AppTypography.caption.copyWith(color: AppColors.paper),
              ),
            ),
          ),
        ],
      );
    }

    return _buildEmptyImagePlaceholder();
  }

  Widget _buildEmptyImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: AppColors.inkSecondary,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.certificateImageEmptyTitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            AppStrings.certificateImageEmptyHint,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ],
      ),
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
    );
  }
}
