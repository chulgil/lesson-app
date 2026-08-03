import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../auth/auth_facade.dart';
import '../../domain/entities/child_profile.dart';
import '../extensions/parent_home_domain_visuals.dart';
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
  /// Resolve the parent id from auth when none was passed, instead of the
  /// 'parent_1' mock seed default. (#586)
  String get _parentId =>
      widget.parentId.isNotEmpty
          ? widget.parentId
          : ref.read(currentUserIdProvider);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late int _selectedBirthYear;
  late String _selectedInstrument;
  late String _selectedLevel;
  late Color _selectedColor;
  bool _isLoading = false;
  // #1072: true once the user explicitly picks an instrument, so build
  // stops re-deriving the default when the active discipline resolves.
  bool _instrumentTouched = false;

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

  // Levels
  static const _levels = [
    ('beginner', AppStrings.studentLevelBeginner),
    ('elementary', AppStrings.studentLevelElementary),
    ('intermediate', AppStrings.studentLevelIntermediate),
    ('advanced', AppStrings.studentLevelAdvanced),
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.existingProfile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _selectedBirthYear = profile?.birthYear ?? DateTime.now().year - 7;
    // New profiles default in build once the active discipline resolves
    // (see build); '' is the not-yet-derived sentinel. Edits keep their value.
    _selectedInstrument = profile?.instrument ?? '';
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
            profileColorKey: parentHomeColorKeyForColor(_selectedColor),
          ),
        );
      } else {
        await manager.addChildProfile(
          parentId: _parentId,
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
            content: Text(isEditing ? AppStrings.parentHomeChildUpdated : AppStrings.parentHomeChildAdded),
            backgroundColor: AppColors.paperOk,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.errorOccurredRetryAgain),
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

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final minYear = currentYear - 18; // Max 18 years old
    final maxYear = currentYear - 3; // Min 3 years old

    // #1072: expertise options follow the active discipline (music keeps its
    // curated key-space, byte-identical; fitness surfaces its specialties).
    final catalogOptions = childInstrumentOptionsFor(
      ref.watch(activeDisciplineProvider),
    );
    // A new, untouched profile defaults to the active discipline's first
    // option. Derived here, not in initState: activeDisciplineProvider first
    // emits the music fallback while its Hive storage loads, then the resolved
    // discipline — deriving in build re-snaps the default once it resolves,
    // instead of leaking 'violin' onto a fitness child. Edits keep their value.
    if (!isEditing && !_instrumentTouched && catalogOptions.isNotEmpty) {
      _selectedInstrument = catalogOptions.first.$1;
    }
    // Preserve a saved value outside the active catalog (e.g. a music child
    // viewed under a switched discipline) so the dropdown never asserts /
    // silently reverts - mirrors the StudentProfileEdit fix (#1098).
    final instrumentOptions =
        catalogOptions.any((o) => o.$1 == _selectedInstrument)
            ? catalogOptions
            : [
              (_selectedInstrument, childInstrumentLabel(_selectedInstrument)),
              ...catalogOptions,
            ];

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: isEditing
            ? AppStrings.parentHomeChildEditTitle
            : AppStrings.parentHomeChildAddTitle,
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
                color: AppColors.paperDark,
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.ink, size: 20),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      AppStrings.parentHomeUnder14Notice,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space6),

            // Profile color selector
            Text(
              AppStrings.parentHomeProfileColorLabel,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children:
                  _profileColors.map((color) {
                    final isSelected =
                        _selectedColor.toARGB32() == color.toARGB32();
                    // §7.132 W1.5: 색상 선택 swatch round → 사각 (Notebook 메타포). white → paper.
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          border:
                              isSelected
                                  ? Border.all(color: AppColors.ink, width: 3)
                                  : null,
                        ),
                        child:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  color: AppColors.paper,
                                  size: 20,
                                )
                                : null,
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: AppSpacing.space6),

            // Name field
            Text(
              AppStrings.parentHomeChildNameLabel,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: AppStrings.parentHomeChildNameHint,
                filled: true,
                fillColor: AppColors.paper,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.inkQuaternary),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.parentHomeChildNameRequired;
                }
                if (value.trim().length < 2) {
                  return AppStrings.parentHomeChildNameMinLength;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.space6),

            // Birth year selector
            Text(
              AppStrings.parentHomeBirthYearLabel,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
              ),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.inkQuaternary),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedBirthYear,
                  isExpanded: true,
                  items: List.generate(maxYear - minYear + 1, (index) {
                    final year = maxYear - index;
                    final age = currentYear - year;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(AppStrings.parentHomeBirthYearAgeFormat(year, age)),
                    );
                  }),
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
                  color: AppColors.paperAccentSoft,
                  borderRadius: BorderRadius.zero,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.paperAccent,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        AppStrings.parentHomeOver14Notice,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.paperAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space6),

            // Instrument selector
            Text(
              AppStrings.instrumentLabel,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
              ),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.inkQuaternary),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedInstrument,
                  isExpanded: true,
                  items:
                      instrumentOptions.map((item) {
                        return DropdownMenuItem(
                          value: item.$1,
                          child: Text(item.$2),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedInstrument = value;
                        _instrumentTouched = true;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space6),

            // Level selector
            Text(
              AppStrings.parentHomeLevelLabel,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
              ),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.inkQuaternary),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLevel,
                  isExpanded: true,
                  items:
                      _levels.map((item) {
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
              // §7.132 W1.5: white × 3 → paper.
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.paperAccent,
                  foregroundColor: AppColors.paper,
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
                          isEditing ? AppStrings.save : AppStrings.parentHomeChildAdd,
                          style: AppTypography.button.copyWith(
                            color: AppColors.paper,
                          ),
                        ),
              ),
            ),

            // Delete button for editing
            if (isEditing) ...[
              const SizedBox(height: AppSpacing.space3),
              TextButton(
                onPressed: _isLoading ? null : _showDeleteConfirmation,
                child: Text(
                  AppStrings.parentHomeDeleteChildProfile,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paperAccent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showNotebookDialog(
      context: context,
      title: AppStrings.parentHomeDeleteChildProfile,
      message:
          AppStrings.parentHomeChildDeleteConfirmFormat(widget.existingProfile!.name),
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
    );

    if (confirmed == true) {
      await _deleteProfile();
    }
  }

  Future<void> _deleteProfile() async {
    setState(() => _isLoading = true);

    try {
      final manager = ref.read(childProfileManagerProvider.notifier);
      await manager.deleteChildProfile(
        widget.existingProfile!.id,
        _parentId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.parentHomeChildDeleted),
            backgroundColor: AppColors.paperOk,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.parentHomeDeleteError),
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
}
