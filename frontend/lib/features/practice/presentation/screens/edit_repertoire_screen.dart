import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/practice/practice_facade.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../widgets/section_form/add_section_widgets.dart';
import '../widgets/section_form/date_range_section.dart';

/// Screen for editing an existing repertoire
class EditRepertoireScreen extends ConsumerStatefulWidget {
  final String repertoireId;
  final String studentId;

  const EditRepertoireScreen({
    super.key,
    required this.repertoireId,
    required this.studentId,
  });

  @override
  ConsumerState<EditRepertoireScreen> createState() =>
      _EditRepertoireScreenState();
}

class _EditRepertoireScreenState extends ConsumerState<EditRepertoireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isInitialized = false;

  // Date fields
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeFromRepertoire(PracticeRepertoire repertoire) {
    if (_isInitialized) return;
    _isInitialized = true;

    _nameController.text = repertoire.name;
    _descriptionController.text = repertoire.description ?? '';
    _startDate = repertoire.startDate;
    _endDate = repertoire.endDate;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentRepertoire = await ref.read(
        repertoireProvider(widget.repertoireId).future,
      );
      if (currentRepertoire == null) throw Exception('Repertoire not found');

      final updatedRepertoire = currentRepertoire.copyWith(
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        clearEndDate: _endDate == null,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(repertoireCrudProvider.notifier)
          .updateRepertoire(updatedRepertoire);

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.editRepertoireUpdateFailedRetry),
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

  Future<void> _archive() async {
    final confirmed = await showNotebookDialog(
      context: context,
      title: AppStrings.archiveButton,
      message: AppStrings.archiveRepertoireConfirm,
      confirmLabel: AppStrings.archiveButton,
      cancelLabel: AppStrings.cancel,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final currentRepertoire = await ref.read(
        repertoireProvider(widget.repertoireId).future,
      );
      if (currentRepertoire == null) throw Exception('Repertoire not found');

      final archivedRepertoire = currentRepertoire.copyWith(
        isArchived: true,
        archivedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref
          .read(repertoireCrudProvider.notifier)
          .updateRepertoire(archivedRepertoire);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.repertoireArchivedSnackbar)),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.archiveFailedRetry),
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

  Future<void> _delete() async {
    final confirmed = await showNotebookDialog(
      context: context,
      title: AppStrings.deleteRepertoireTitle,
      message: AppStrings.deleteRepertoireConfirm,
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(repertoireCrudProvider.notifier)
          .deleteRepertoire(widget.repertoireId, widget.studentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.repertoireDeletedSnackbar)),
        );
        // Pop twice to go back to the list
        context.pop();
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.deleteFailedRetry),
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

  Future<void> _selectStartDate() async {
    final picked = await AppDatePicker.show(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: AppStrings.selectStartDate,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, clear it
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await AppDatePicker.show(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
      helpText: AppStrings.selectEndDate,
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _clearEndDate() {
    setState(() => _endDate = null);
  }

  @override
  Widget build(BuildContext context) {
    final repertoireAsync = ref.watch(repertoireProvider(widget.repertoireId));

    return NotebookScreenScaffold(
      appBar: AppBar(title: const Text(AppStrings.editRepertoireAppBarTitle)),
      body: repertoireAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text(AppStrings.errorOccurred)),
        data: (repertoire) {
          if (repertoire == null) {
            return const Center(child: Text(AppStrings.repertoireNotFound));
          }

          _initializeFromRepertoire(repertoire);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========================================
                  // 📋 기본 정보 섹션
                  // ========================================
                  const SectionHeader(
                    icon: '📋',
                    title: AppStrings.basicInfoTitle,
                    subtitle: AppStrings.editRepertoireBasicInfoSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.repertoireNameLabel,
                      hintText: AppStrings.editRepertoireNameHint,
                      prefixIcon: Icon(Icons.library_music),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.repertoireNameRequired;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.space4),

                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.descriptionOptional,
                      hintText: AppStrings.repertoireDescriptionHint,
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                  ),

                  const SizedBox(height: AppSpacing.space6),

                  // ========================================
                  // 📅 연습 기간 섹션
                  // ========================================
                  DateRangeSection(
                    startDate: _startDate,
                    endDate: _endDate,
                    onStartDateTap: _selectStartDate,
                    onEndDateTap: _selectEndDate,
                    onEndDateClear: _clearEndDate,
                    endDatePlaceholder: AppStrings.endDateNotSetDaily,
                    showHintMessage: true,
                  ),

                  const SizedBox(height: AppSpacing.space8),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.paper,
                                ),
                              )
                              : const Text(AppStrings.saveChangesButton),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.space8),

                  // ========================================
                  // 🗄️ 관리 섹션
                  // ========================================
                  const SettingSectionHeader(
                    icon: '🗄️',
                    title: AppStrings.managementSectionTitle,
                    description: AppStrings.managementSectionDescription,
                  ),
                  const SizedBox(height: AppSpacing.space3),

                  // Archive button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _archive,
                      icon: const Icon(Icons.archive_outlined),
                      label: const Text(AppStrings.archiveButton),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.paperAccent,
                        side: const BorderSide(color: AppColors.paperAccent),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.space2),

                  // Delete button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _delete,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text(AppStrings.deleteRepertoireTitle),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.paperAccent,
                        side: const BorderSide(color: AppColors.paperAccent),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.space4),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
