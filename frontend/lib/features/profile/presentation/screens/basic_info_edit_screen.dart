import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/address_search_field.dart';
import '../../../../core/widgets/profile_photo_header.dart';
import '../../../../features/profile/profile_facade.dart';
import '../../../auth/auth_facade.dart';
import '../../../students/students_ui_facade.dart';
import '../providers/background_image_provider.dart';
import '../providers/profile_image_provider.dart';

/// Screen for editing basic profile info (name, introduction, teaching style, specialties)
class BasicInfoEditScreen extends ConsumerStatefulWidget {
  const BasicInfoEditScreen({super.key});

  @override
  ConsumerState<BasicInfoEditScreen> createState() =>
      _BasicInfoEditScreenState();
}

class _BasicInfoEditScreenState extends ConsumerState<BasicInfoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _introductionController = TextEditingController();
  final _teachingStyleController = TextEditingController();

  final Set<String> _selectedSpecialties = {};
  final List<String> _lessonAreas = [];
  final _areaController = TextEditingController();

  // 주소 필드
  String? _postalCode;
  String? _address;
  String? _addressDetail;

  bool _isLoading = false;

  static const int _minIntroductionLength = 20;
  static const int _maxSpecialties = 5;
  static const int _maxAreas = 5;

  static const List<String> _specialtyOptions = [
    '클래식',
    '재즈',
    '팝',
    '입시',
    '취미',
    '아동',
    '성인',
    '앙상블',
    '오케스트라',
    '실내악',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final profileState = ref.read(teacherExtendedProfileProvider);
    final profile = profileState.valueOrNull;
    if (profile != null) {
      _nameController.text = profile.name;
      _nicknameController.text = profile.nickname ?? profile.name;
      _introductionController.text = profile.introduction;
      _teachingStyleController.text = profile.teachingStyle ?? '';
      if (profile.specialties != null) {
        _selectedSpecialties.addAll(profile.specialties!);
      }
      if (profile.lessonAreas != null) {
        _lessonAreas.addAll(profile.lessonAreas!);
      }
      _postalCode = profile.postalCode;
      _address = profile.address;
      _addressDetail = profile.addressDetail;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _introductionController.dispose();
    _teachingStyleController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  String get _userId {
    final authState = ref.read(authNotifierProvider);
    return authState is AuthAuthenticated ? authState.userId : '';
  }

  Future<void> _onTapProfileImage() async {
    final userId = _userId;
    final currentPath =
        ref.read(profileImageNotifierProvider(userId)).valueOrNull;

    final action = await showImagePickerBottomSheet(
      context,
      title: AppStrings.profileBasicInfoPhotoTitle,
      showDelete: currentPath != null,
    );
    if (action == null || !mounted) return;

    final notifier = ref.read(profileImageNotifierProvider(userId).notifier);

    if (action == ImagePickerAction.delete) {
      await notifier.removeImage();
      return;
    }

    final source =
        action == ImagePickerAction.camera
            ? ImageSource.camera
            : ImageSource.gallery;

    if (!mounted) return;
    await notifier.pickAndSaveImage(source, context);
  }

  Future<void> _onTapBackgroundImage() async {
    final userId = _userId;
    final currentPath =
        ref.read(backgroundImageNotifierProvider(userId)).valueOrNull;

    final action = await showImagePickerBottomSheet(
      context,
      title: AppStrings.profileBasicInfoBackgroundTitle,
      showDelete: currentPath != null,
    );
    if (action == null || !mounted) return;

    final notifier = ref.read(backgroundImageNotifierProvider(userId).notifier);

    if (action == ImagePickerAction.delete) {
      await notifier.removeImage();
      return;
    }

    final source =
        action == ImagePickerAction.camera
            ? ImageSource.camera
            : ImageSource.gallery;

    if (!mounted) return;
    await notifier.pickAndSaveImage(source, context);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(teacherExtendedProfileProvider.notifier);
      final teachingStyle = _teachingStyleController.text.trim();

      // Single atomic save: all fields in one API call
      final nicknameText = _nicknameController.text.trim();
      await notifier.updateBasicInfoAll(
        name: _nameController.text.trim(),
        nickname: nicknameText.isNotEmpty ? nicknameText : null,
        introduction: _introductionController.text.trim(),
        teachingStyle: teachingStyle.isNotEmpty ? teachingStyle : null,
        specialties: _selectedSpecialties.toList(),
        lessonAreas: _lessonAreas.toList(),
        postalCode: _postalCode,
        address: _address,
        addressDetail: _addressDetail,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.profileBasicInfoSaved),
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final userId = _userId;
    final profileImagePath =
        ref.watch(profileImageNotifierProvider(userId)).valueOrNull;
    final backgroundImagePath =
        ref.watch(backgroundImageNotifierProvider(userId)).valueOrNull;
    final name = _nameController.text;
    final initial = name.isNotEmpty ? name[0] : '?';

    return PopScope(
      canPop: !_isLoading,
      child: NotebookScreenScaffold(
        appBar: NotebookDetailAppBar(
          title: AppStrings.profileBasicInfoTitle,
          customActions: [
            TextButton(
              onPressed: _isLoading ? null : _save,
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(
                        '저장',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.paperAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ],
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
              // Photo header (profile + background)
              ProfilePhotoHeader(
                profileImagePath: profileImagePath,
                backgroundImagePath: backgroundImagePath,
                initial: initial,
                avatarColor: AppColors.paperAccentSoft,
                onTapProfile: _onTapProfileImage,
                onTapBackground: _onTapBackgroundImage,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Name field
              _buildLabel('이름', required: true),
              const SizedBox(height: AppSpacing.space2),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                  hintText: AppStrings.profileBasicInfoHintName,
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.space4),

              // Nickname field (호칭)
              _buildLabel('호칭 (닉네임)'),
              const SizedBox(height: AppSpacing.space1),
              Text(
                '학생에게 표시되는 이름입니다. 비워두면 본명이 사용됩니다.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              TextFormField(
                controller: _nicknameController,
                decoration: _inputDecoration(
                  hintText: '예) 영희쌤, 바이올린 선생님',
                ),
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Introduction field
              _buildLabel('소개글', required: true),
              const SizedBox(height: AppSpacing.space2),
              TextFormField(
                controller: _introductionController,
                decoration: _inputDecoration(
                  hintText:
                      '${AppStrings.profileBasicInfoHintIntroduction} (최소 $_minIntroductionLength자)',
                ),
                maxLines: 6,
                minLines: 4,
                textInputAction: TextInputAction.newline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '소개글을 입력해주세요';
                  }
                  if (value.trim().length < _minIntroductionLength) {
                    return '소개글은 최소 $_minIntroductionLength자 이상 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space2),
              _buildCharacterCount(),

              const SizedBox(height: AppSpacing.space6),

              // Teaching style field
              _buildLabel('교수 스타일'),
              const SizedBox(height: AppSpacing.space2),
              TextFormField(
                controller: _teachingStyleController,
                decoration: _inputDecoration(
                  hintText: AppStrings.profileBasicInfoHintTeachingStyle,
                ),
                maxLines: 4,
                minLines: 3,
                textInputAction: TextInputAction.newline,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Specialties field
              _buildLabel('전문 분야'),
              const SizedBox(height: AppSpacing.space1),
              Text(
                '최대 $_maxSpecialties개까지 선택할 수 있습니다',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              _buildSpecialtyChips(),

              const SizedBox(height: AppSpacing.space6),

              // Lesson areas field
              _buildLabel('활동 지역'),
              const SizedBox(height: AppSpacing.space1),
              Text(
                '최대 $_maxAreas개까지 추가할 수 있습니다',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              _buildAreaInput(),
              const SizedBox(height: AppSpacing.space2),
              _buildAreaChips(),

              const SizedBox(height: AppSpacing.space6),

              // 기본 레슨 장소 주소
              _buildLabel('레슨 장소 (홈, 스튜디오)'),
              const SizedBox(height: AppSpacing.space1),
              Text(
                '학생 방문 시 위치 안내, 방문레슨 이동시간 자동 계산에\n활용됩니다',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              AddressSearchField(
                initialPostalCode: _postalCode,
                initialAddress: _address,
                initialAddressDetail: _addressDetail,
                onChanged: (result) {
                  _postalCode = result.postalCode;
                  _address = result.address;
                  _addressDetail = result.addressDetail;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialtyChips() {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children:
          _specialtyOptions.map((specialty) {
            final isSelected = _selectedSpecialties.contains(specialty);
            return FilterChip(
              label: Text(specialty),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (_selectedSpecialties.length >= _maxSpecialties) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppStrings.profileBasicInfoMaxSelections(
                              _maxSpecialties,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    _selectedSpecialties.add(specialty);
                  } else {
                    _selectedSpecialties.remove(specialty);
                  }
                });
              },
              selectedColor: AppColors.paperAccentSoft,
              checkmarkColor: AppColors.paperAccent,
              labelStyle: AppTypography.bodyMedium.copyWith(
                color: isSelected ? AppColors.paperAccent : AppColors.ink,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color:
                      isSelected
                          ? AppColors.paperAccent
                          : AppColors.inkQuaternary,
                ),
              ),
              backgroundColor: AppColors.paper,
            );
          }).toList(),
    );
  }

  Widget _buildAreaInput() {
    return TextFormField(
      controller: _areaController,
      decoration: _inputDecoration(
        hintText: AppStrings.profileBasicInfoHintArea,
      ),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _addArea(),
    );
  }

  void _addArea() {
    final area = _areaController.text.trim();
    if (area.isEmpty) return;
    if (_lessonAreas.length >= _maxAreas) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.profileBasicInfoMaxAreas(_maxAreas)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_lessonAreas.contains(area)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.profileBasicInfoAreaDuplicate),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _lessonAreas.add(area);
      _areaController.clear();
    });
  }

  Widget _buildAreaChips() {
    if (_lessonAreas.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children:
          _lessonAreas.map((area) {
            return Chip(
              label: Text(area),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                setState(() => _lessonAreas.remove(area));
              },
              labelStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.ink,
              ),
              backgroundColor: AppColors.paperDark,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: AppColors.inkQuaternary),
              ),
            );
          }).toList(),
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

  Widget _buildCharacterCount() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _introductionController,
      builder: (context, value, _) {
        final length = value.text.trim().length;
        final isSufficient = length >= _minIntroductionLength;
        return Align(
          alignment: Alignment.centerRight,
          child: Text(
            isSufficient
                ? '$length자'
                : '$length자 (최소 $_minIntroductionLength자)',
            style: AppTypography.caption.copyWith(
              color:
                  isSufficient ? AppColors.inkTertiary : AppColors.paperAccent,
            ),
          ),
        );
      },
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
