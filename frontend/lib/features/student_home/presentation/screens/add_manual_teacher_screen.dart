import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../students/presentation/widgets/student_form/instrument_selector.dart';
import '../../domain/entities/manual_teacher.dart';
import '../providers/manual_teacher_provider.dart';

/// Screen for adding or editing a manually registered teacher.
class AddManualTeacherScreen extends ConsumerStatefulWidget {
  /// Pass an existing teacher to enter edit mode.
  final ManualTeacher? existingTeacher;

  const AddManualTeacherScreen({super.key, this.existingTeacher});

  @override
  ConsumerState<AddManualTeacherScreen> createState() =>
      _AddManualTeacherScreenState();
}

class _AddManualTeacherScreenState
    extends ConsumerState<AddManualTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  String? _selectedInstrument;
  bool _isSaving = false;

  bool get _isEditMode => widget.existingTeacher != null;

  @override
  void initState() {
    super.initState();
    final teacher = widget.existingTeacher;
    _nameController = TextEditingController(text: teacher?.name ?? '');
    _phoneController = TextEditingController(text: teacher?.phone ?? '');
    _notesController = TextEditingController(text: teacher?.notes ?? '');
    _selectedInstrument = teacher?.instrument;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _hasFormData() {
    return _nameController.text.isNotEmpty ||
        _phoneController.text.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _selectedInstrument != null;
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? AppStrings.studentHomeTeacherEditLabel
              : AppStrings.studentHomeTeacherRegisterLabel,
        ),
        leading: IconButton(
          onPressed: () => _confirmExit(),
          icon: const Icon(Icons.close),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: const Text(AppStrings.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field (required)
              Text(
                '이름',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: AppStrings.studentHomeTeacherNameHint,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Instrument field (optional)
              Text(
                '악기',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                '선택 사항',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              InstrumentSelector(
                selectedInstrument: _selectedInstrument,
                onChanged: (value) {
                  setState(() => _selectedInstrument = value);
                },
              ),

              const SizedBox(height: AppSpacing.space6),

              // Phone field (optional)
              Text(
                '전화번호',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                '선택 사항',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(hintText: '010-0000-0000'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Notes field (optional)
              Text(
                '메모',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                '선택 사항',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: AppStrings.studentHomeLessonNoteHint,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: AppSpacing.space8),

              // Save button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(
                    _isEditMode
                        ? AppStrings.studentHomeTeacherSaveLabel
                        : AppStrings.studentHomeTeacherRegisterAction,
                  ),
                ),
              ),

              if (_isEditMode) ...[
                const SizedBox(height: AppSpacing.space4),
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.buttonHeight,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _confirmDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.paperAccent,
                      side: const BorderSide(color: AppColors.paperAccent),
                    ),
                    child: const Text(AppStrings.studentHomeDeleteTeacher),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmExit() {
    if (!_hasFormData() || (_isEditMode && !_hasChanges())) {
      context.pop();
      return;
    }

    showDialog(
      context: context,
      builder:
          (ctx) => NotebookAlertDialog(
            title: const Text(AppStrings.studentHomeCancelWriting),
            content: const Text(AppStrings.studentHomeCancelWritingConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(AppStrings.continueWriting),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                },
                child: const Text(AppStrings.exitAction),
              ),
            ],
          ),
    );
  }

  bool _hasChanges() {
    final teacher = widget.existingTeacher;
    if (teacher == null) return false;
    return _nameController.text.trim() != teacher.name ||
        _selectedInstrument != teacher.instrument ||
        _phoneController.text.trim() != (teacher.phone ?? '') ||
        _notesController.text.trim() != (teacher.notes ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(manualTeacherNotifierProvider.notifier);

      if (_isEditMode) {
        final updated = widget.existingTeacher!.copyWith(
          name: _nameController.text.trim(),
          instrument: _selectedInstrument,
          phone:
              _phoneController.text.trim().isNotEmpty
                  ? _phoneController.text.trim()
                  : null,
          notes:
              _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
          profileColorValue: widget.existingTeacher!.profileColorValue,
        );
        await notifier.updateTeacher(updated);
      } else {
        final teacher = ManualTeacher(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          instrument: _selectedInstrument,
          phone:
              _phoneController.text.trim().isNotEmpty
                  ? _phoneController.text.trim()
                  : null,
          notes:
              _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
          createdAt: DateTime.now(),
        );
        await notifier.add(teacher);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? AppStrings.studentHomeTeacherInfoUpdated
                : AppStrings.studentHomeTeacherRegistered,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.studentHomeSaveFailedRetry),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.paperAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => NotebookAlertDialog(
            title: const Text(AppStrings.studentHomeDeleteTeacher),
            content: const Text(AppStrings.studentHomeDeleteTeacherConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.paperAccent,
                ),
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);

    try {
      await ref
          .read(manualTeacherNotifierProvider.notifier)
          .delete(widget.existingTeacher!.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.studentHomeTeacherDeleted),
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.studentHomeDeleteFailedRetry),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.paperAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
