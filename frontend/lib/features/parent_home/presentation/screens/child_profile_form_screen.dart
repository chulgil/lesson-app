import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/child_profile.dart';
import '../providers/child_profile_provider.dart';

/// Screen for adding or editing a child profile
class ChildProfileFormScreen extends ConsumerStatefulWidget {
  final ChildProfile? existingProfile;
  final String parentId;

  const ChildProfileFormScreen({
    super.key,
    this.existingProfile,
    required this.parentId,
  });

  @override
  ConsumerState<ChildProfileFormScreen> createState() =>
      _ChildProfileFormScreenState();
}

class _ChildProfileFormScreenState
    extends ConsumerState<ChildProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late int _selectedBirthYear;
  late String _selectedInstrument;
  late String _selectedLevel;
  late Color _selectedColor;
  bool _isLoading = false;

  bool get isEditing => widget.existingProfile != null;

  // Available profile colors
  static const _profileColors = [
    AppColors.profileBlue,
    AppColors.profilePink,
    AppColors.profileGreen,
    AppColors.profileOrange,
    AppColors.profilePurple,
    AppColors.profileTeal,
    AppColors.profileRed,
    AppColors.profileIndigo,
  ];

  // Instruments
  static const _instruments = [
    ('violin', '바이올린'),
    ('piano', '피아노'),
    ('cello', '첼로'),
    ('viola', '비올라'),
    ('flute', '플루트'),
  ];

  // Levels
  static const _levels = [
    ('beginner', '입문'),
    ('elementary', '초급'),
    ('intermediate', '중급'),
    ('advanced', '고급'),
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.existingProfile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _selectedBirthYear = profile?.birthYear ?? DateTime.now().year - 7;
    _selectedInstrument = profile?.instrument ?? 'violin';
    _selectedLevel = profile?.level ?? 'beginner';
    _selectedColor = profile?.profileColor ?? _profileColors[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final manager = ref.read(childProfileManagerProvider.notifier);

      if (isEditing) {
        await manager.updateChildProfile(
          widget.existingProfile!.copyWith(
            name: _nameController.text.trim(),
            birthYear: _selectedBirthYear,
            instrument: _selectedInstrument,
            level: _selectedLevel,
            profileColor: _selectedColor,
          ),
        );
      } else {
        await manager.addChildProfile(
          parentId: widget.parentId,
          name: _nameController.text.trim(),
          birthYear: _selectedBirthYear,
          instrument: _selectedInstrument,
          level: _selectedLevel,
          profileColor: _selectedColor,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? '자녀 정보가 수정되었습니다' : '자녀 프로필이 추가되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
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
    final currentYear = DateTime.now().year;
    final minYear = currentYear - 18; // Max 18 years old
    final maxYear = currentYear - 3; // Min 3 years old

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '자녀 정보 수정' : '자녀 추가'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // Info banner for under-14
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      '만 14세 미만 자녀는 별도 계정 없이 학부모 계정에서 관리됩니다.',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space6),

            // Profile color selector
            Text('프로필 색상', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.space2),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: _profileColors.map((color) {
                final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppColors.textPrimaryLight, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.space6),

            // Name field
            Text('이름/별명', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '자녀 이름 또는 별명 입력',
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '이름을 입력해주세요';
                }
                if (value.trim().length < 2) {
                  return '2글자 이상 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.space6),

            // Birth year selector
            Text('출생년도', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedBirthYear,
                  isExpanded: true,
                  items: List.generate(
                    maxYear - minYear + 1,
                    (index) {
                      final year = maxYear - index;
                      final age = currentYear - year;
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year년 (만 $age세)'),
                      );
                    },
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedBirthYear = value);
                    }
                  },
                ),
              ),
            ),
            // Age warning if 14 or older
            if (currentYear - _selectedBirthYear >= 14) ...[
              const SizedBox(height: AppSpacing.space2),
              Container(
                padding: const EdgeInsets.all(AppSpacing.space2),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 16),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        '만 14세 이상은 별도 계정 등록이 가능합니다.',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space6),

            // Instrument selector
            Text('악기', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedInstrument,
                  isExpanded: true,
                  items: _instruments.map((item) {
                    return DropdownMenuItem(
                      value: item.$1,
                      child: Text(item.$2),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedInstrument = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space6),

            // Level selector
            Text('수준', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLevel,
                  isExpanded: true,
                  items: _levels.map((item) {
                    return DropdownMenuItem(
                      value: item.$1,
                      child: Text(item.$2),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLevel = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space8),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
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
                        isEditing ? '저장' : '자녀 추가',
                        style: AppTypography.button.copyWith(color: Colors.white),
                      ),
              ),
            ),

            // Delete button for editing
            if (isEditing) ...[
              const SizedBox(height: AppSpacing.space3),
              TextButton(
                onPressed: _isLoading ? null : _showDeleteConfirmation,
                child: Text(
                  '자녀 프로필 삭제',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('자녀 프로필 삭제'),
        content: Text(
          "'${widget.existingProfile!.name}' 프로필을 삭제하시겠습니까?\n\n연결된 레슨 기록은 유지됩니다.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProfile();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProfile() async {
    setState(() => _isLoading = true);

    try {
      final manager = ref.read(childProfileManagerProvider.notifier);
      await manager.deleteChildProfile(
        widget.existingProfile!.id,
        widget.parentId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('자녀 프로필이 삭제되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
