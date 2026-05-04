import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/selectors/selectors.dart';
import '../../domain/entities/subscription_template.dart';
import '../providers/subscription_template_providers.dart';

/// Screen for managing subscription templates (teacher app).
class SubscriptionTemplateListScreen extends ConsumerWidget {
  final String teacherId;

  const SubscriptionTemplateListScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(teacherTemplatesProvider(teacherId));

    return NotebookScreenScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.templateListAppBarTitle),
        backgroundColor: AppColors.paperDark,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              context.push(
                '${AppRoutes.proposalSettings}?teacherId=$teacherId',
              );
            },
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.proposalSettingsAppBarTitle,
          ),
        ],
      ),
      backgroundColor: AppColors.paperDark,
      body: templatesAsync.when(
        data: (templates) => _buildContent(context, ref, templates),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTemplateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.templateAddButton),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<SubscriptionTemplate> templates,
  ) {
    if (templates.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.space4),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _TemplateCard(
          template: template,
          onEdit: () => _showEditTemplateDialog(context, ref, template),
          onToggleActive: () => _toggleActive(ref, template),
          onDelete: () => _confirmDelete(context, ref, template),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_membership_outlined,
              size: 64,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.noSubscriptionsRegisteredTitle,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.templateEmptyHint,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            FilledButton.icon(
              onPressed: () => _showAddTemplateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.templateFirstCreate),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.paperAccent,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              AppStrings.cannotLoadData,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTemplateDialog(BuildContext context, WidgetRef ref) {
    showNotebookBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => _TemplateFormSheet(
            teacherId: teacherId,
            onSave: (template) async {
              await ref
                  .read(subscriptionTemplateNotifierProvider.notifier)
                  .createTemplate(
                    ownerId: template.ownerId,
                    ownerType: template.ownerType,
                    name: template.name,
                    totalLessons: template.totalLessons,
                    lessonDurationMinutes: template.lessonDurationMinutes,
                    validityDays: template.validityDays,
                    price: template.price,
                    description: template.description,
                  );
            },
          ),
    );
  }

  void _showEditTemplateDialog(
    BuildContext context,
    WidgetRef ref,
    SubscriptionTemplate template,
  ) {
    showNotebookBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => _TemplateFormSheet(
            teacherId: teacherId,
            template: template,
            onSave: (updated) async {
              await ref
                  .read(subscriptionTemplateNotifierProvider.notifier)
                  .updateTemplate(updated);
            },
          ),
    );
  }

  Future<void> _toggleActive(
    WidgetRef ref,
    SubscriptionTemplate template,
  ) async {
    await ref
        .read(subscriptionTemplateNotifierProvider.notifier)
        .toggleActive(template);
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SubscriptionTemplate template,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => NotebookAlertDialog(
            title: AppStrings.templateDeleteDialogTitle,
            content: Text(
              AppStrings.templateDeleteConfirmFormat(template.name),
            ),
            cancelLabel: AppStrings.cancel,
            confirmLabel: AppStrings.delete,
            isDestructive: true,
            onConfirm: () async {
              Navigator.pop(context);
              await ref
                  .read(subscriptionTemplateNotifierProvider.notifier)
                  .deleteTemplate(template);
            },
          ),
    );
  }
}

/// Individual template card widget.
class _TemplateCard extends StatelessWidget {
  final SubscriptionTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return NotebookCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color:
              template.isActive
                  ? AppColors.inkQuaternary
                  : AppColors.inkTertiary.withValues(alpha: 0.3),
        ),
      ),
      color: template.isActive ? AppColors.paper : AppColors.paperDark,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              template.name,
                              style: AppTypography.headingSmall.copyWith(
                                color:
                                    template.isActive
                                        ? AppColors.ink
                                        : AppColors.inkTertiary,
                              ),
                            ),
                            if (!template.isActive) ...[
                              const SizedBox(width: AppSpacing.space2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.inkTertiary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                child: Text(
                                  AppStrings.templateInactiveBadge,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.inkTertiary,
                                  ),
                                ),
                              ),
                            ],
                            // 🆕 자동 제안 배지
                            if (template.isAutoProposalEnabled &&
                                template.isActive) ...[
                              const SizedBox(width: AppSpacing.space2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.paperOk.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.flash_on,
                                      size: 12,
                                      color: AppColors.paperOk,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      AppStrings.templateAutoBadge,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.paperOk,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          template.summaryText,
                          style: AppTypography.bodyMedium.copyWith(
                            color:
                                template.isActive
                                    ? AppColors.inkSecondary
                                    : AppColors.inkTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menu button
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'toggle':
                          onToggleActive();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20),
                                SizedBox(width: AppSpacing.space2),
                                Text(AppStrings.modify),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  template.isActive
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.space2),
                                Text(
                                  template.isActive
                                      ? AppStrings.templateMenuDeactivate
                                      : AppStrings.templateMenuActivate,
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: AppColors.paperAccent,
                                ),
                                SizedBox(width: AppSpacing.space2),
                                Text(
                                  AppStrings.delete,
                                  style: TextStyle(
                                    color: AppColors.paperAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.space3),

              // Details row
              Row(
                children: [
                  _DetailChip(
                    icon: Icons.schedule,
                    label: AppStrings.durationMinutesValue(
                      template.lessonDurationMinutes,
                    ),
                    isActive: template.isActive,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  _DetailChip(
                    icon: Icons.calendar_today,
                    label: template.formattedValidity,
                    isActive: template.isActive,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  _DetailChip(
                    icon: Icons.calculate_outlined,
                    label: AppStrings.templateUnitPriceLabel(
                      template.formattedPricePerLesson,
                    ),
                    isActive: template.isActive,
                  ),
                ],
              ),

              // Description if present
              if (template.description != null &&
                  template.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  template.description!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail chip widget.
class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color:
            isActive
                ? AppColors.paperAccentSoft
                : AppColors.inkTertiary.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? AppColors.paperAccent : AppColors.inkTertiary,
          ),
          const SizedBox(width: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isActive ? AppColors.paperAccent : AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet form for creating/editing templates.
class _TemplateFormSheet extends ConsumerStatefulWidget {
  final String teacherId;
  final SubscriptionTemplate? template;
  final Future<void> Function(SubscriptionTemplate template) onSave;

  const _TemplateFormSheet({
    required this.teacherId,
    this.template,
    required this.onSave,
  });

  @override
  ConsumerState<_TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends ConsumerState<_TemplateFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _customLessonsController;
  late TextEditingController _customDurationController;
  late TextEditingController _customValidityController;

  int _totalLessons = 8;
  int _lessonDuration = 50;
  int _validityDays = 90;
  bool _isCustomLessons = false;
  bool _isCustomDuration = false;
  bool _isCustomValidity = false;
  bool _isSaving = false;
  bool _isAutoProposalEnabled = true; // 🆕 기본값: 자동 제안 활성화

  bool get isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _nameController = TextEditingController(text: t?.name ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _priceController = TextEditingController(
      text: t != null ? t.price.toString() : '',
    );
    _customLessonsController = TextEditingController();
    _customDurationController = TextEditingController();
    _customValidityController = TextEditingController();

    if (t != null) {
      _totalLessons = t.totalLessons;
      _lessonDuration = t.lessonDurationMinutes;
      _validityDays = t.validityDays;
      _isAutoProposalEnabled = t.isAutoProposalEnabled; // 🆕

      // Check if values are custom (not in presets)
      if (![4, 8, 12, 16].contains(t.totalLessons)) {
        _isCustomLessons = true;
        _customLessonsController.text = t.totalLessons.toString();
      }
      if (![30, 45, 50, 60, 90].contains(t.lessonDurationMinutes)) {
        _isCustomDuration = true;
        _customDurationController.text = t.lessonDurationMinutes.toString();
      }
      if (![30, 60, 90, 120, 150].contains(t.validityDays)) {
        _isCustomValidity = true;
        _customValidityController.text = t.validityDays.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _customLessonsController.dispose();
    _customDurationController.dispose();
    _customValidityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              const Center(child: BottomSheetHandle(margin: EdgeInsets.zero)),
              const SizedBox(height: AppSpacing.space4),

              // Title
              // Notebook × Score: 바텀시트 헤더 Playfair 승격 (§7.27 + §7.87-h
              // 2원 유한집합).
              Text(
                isEditing
                    ? AppStrings.templateEditSheetTitle
                    : AppStrings.templateAddSheetTitle,
                style: NotebookTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space4),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.templateNameLabel,
                  hintText: AppStrings.templateNameHint,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.templateNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space4),

              // Lessons count (using common widget)
              LessonCountSelector(
                selectedCount: _totalLessons,
                isCustom: _isCustomLessons,
                customController: _customLessonsController,
                onCountChanged: (count, isCustom) {
                  setState(() {
                    _totalLessons = count;
                    _isCustomLessons = isCustom;
                  });
                },
                label: AppStrings.lessonCountLabel,
              ),
              const SizedBox(height: AppSpacing.space4),

              // Lesson duration (using common widget)
              LessonDurationSelector(
                selectedDuration: _lessonDuration,
                isCustom: _isCustomDuration,
                customController: _customDurationController,
                onDurationChanged: (duration, isCustom) {
                  setState(() {
                    _lessonDuration = duration;
                    _isCustomDuration = isCustom;
                  });
                },
                label: AppStrings.infoLabelDuration,
              ),
              const SizedBox(height: AppSpacing.space4),

              // Validity period (using common widget)
              ValidityPeriodSelector(
                selectedDays: _validityDays,
                isCustom: _isCustomValidity,
                customController: _customValidityController,
                onPeriodChanged: (days, isCustom) {
                  setState(() {
                    _validityDays = days;
                    _isCustomValidity = isCustom;
                  });
                },
                label: AppStrings.validityPeriod,
              ),
              const SizedBox(height: AppSpacing.space4),

              // Price field
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: AppStrings.templatePriceLabel,
                  hintText: AppStrings.templatePriceHint,
                  prefixText: '₩ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.templatePriceRequired;
                  }
                  if (int.tryParse(value) == null) {
                    return AppStrings.templatePriceNumbersOnly;
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
                  hintText: AppStrings.templateDescHint,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.space4),

              // 🆕 자동 제안 설정
              _buildAutoProposalSection(),
              const SizedBox(height: AppSpacing.space6),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.paperAccent,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space3,
                    ),
                  ),
                  child:
                      _isSaving
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.paper,
                              ),
                            ),
                          )
                          : Text(
                            isEditing
                                ? AppStrings.templateSaveEdit
                                : AppStrings.templateSaveAdd,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.paper,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  /// 🆕 자동 제안 설정 섹션
  Widget _buildAutoProposalSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color:
            _isAutoProposalEnabled
                ? AppColors.paperOk.withValues(alpha: 0.05)
                : AppColors.paper,
        border: Border.all(
          color:
              _isAutoProposalEnabled
                  ? AppColors.paperOk.withValues(alpha: 0.3)
                  : AppColors.inkQuaternary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 체크박스 + 라벨
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _isAutoProposalEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isAutoProposalEnabled = value ?? true;
                    });
                  },
                  activeColor: AppColors.paperOk,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isAutoProposalEnabled = !_isAutoProposalEnabled;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.flash_on,
                        size: 18,
                        color:
                            _isAutoProposalEnabled
                                ? AppColors.paperOk
                                : AppColors.inkTertiary,
                      ),
                      const SizedBox(width: AppSpacing.space1),
                      Text(
                        AppStrings.templateAutoProposalCheckbox,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              _isAutoProposalEnabled
                                  ? AppColors.ink
                                  : AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),

          // 설명
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              _isAutoProposalEnabled
                  ? AppStrings.templateAutoProposalEnabledDesc
                  : AppStrings.templateAutoProposalDisabledDesc,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final template = SubscriptionTemplate(
        id: widget.template?.id ?? '',
        ownerId: widget.teacherId,
        ownerType: SubscriptionTemplateOwnerType.teacher,
        name: _nameController.text.trim(),
        totalLessons: _totalLessons,
        lessonDurationMinutes: _lessonDuration,
        validityDays: _validityDays,
        price: int.parse(_priceController.text.trim()),
        description:
            _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
        isActive: widget.template?.isActive ?? true,
        displayOrder: widget.template?.displayOrder ?? 0,
        createdAt: widget.template?.createdAt ?? DateTime.now(),
        isAutoProposalEnabled: _isAutoProposalEnabled, // 🆕
      );

      await widget.onSave(template);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? AppStrings.templateUpdatedSnackbar
                  : AppStrings.templateAddedSnackbar,
            ),
            backgroundColor: AppColors.paperOk,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.errorTryAgain),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
