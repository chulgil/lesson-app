import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/selectors/selectors.dart';
import '../../domain/entities/subscription_template.dart';
import '../providers/subscription_template_providers.dart';

/// Screen for managing subscription templates (teacher app).
class SubscriptionTemplateListScreen extends ConsumerWidget {
  final String teacherId;

  const SubscriptionTemplateListScreen({
    super.key,
    required this.teacherId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(teacherTemplatesProvider(teacherId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('수강권 관리'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              context.push('${AppRoutes.proposalSettings}?teacherId=$teacherId');
            },
            icon: const Icon(Icons.settings_outlined),
            tooltip: '자동 제안 설정',
          ),
        ],
      ),
      backgroundColor: AppColors.backgroundLight,
      body: templatesAsync.when(
        data: (templates) => _buildContent(context, ref, templates),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTemplateDialog(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          '수강권 추가',
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        ),
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
              color: AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '등록된 수강권이 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '수강권을 만들어 학생들에게 제안해보세요',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            FilledButton.icon(
              onPressed: () => _showAddTemplateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('첫 수강권 만들기'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
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
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              '데이터를 불러올 수 없습니다',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTemplateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TemplateFormSheet(
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TemplateFormSheet(
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
      WidgetRef ref, SubscriptionTemplate template) async {
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
      builder: (context) => AlertDialog(
        title: const Text('수강권 삭제'),
        content: Text('"${template.name}"을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(subscriptionTemplateNotifierProvider.notifier)
                  .deleteTemplate(template);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        side: BorderSide(
          color: template.isActive
              ? AppColors.borderLight
              : AppColors.textTertiaryLight.withValues(alpha: 0.3),
        ),
      ),
      color: template.isActive ? Colors.white : AppColors.surfaceSecondaryLight,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
                                color: template.isActive
                                    ? AppColors.textPrimaryLight
                                    : AppColors.textTertiaryLight,
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
                                  color: AppColors.textTertiaryLight
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '비활성',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textTertiaryLight,
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
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.flash_on,
                                      size: 12,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '자동',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.summaryText,
                          style: AppTypography.bodyMedium.copyWith(
                            color: template.isActive
                                ? AppColors.textSecondaryLight
                                : AppColors.textTertiaryLight,
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
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('수정'),
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
                            const SizedBox(width: 8),
                            Text(template.isActive ? '비활성화' : '활성화'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 20, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('삭제',
                                style: TextStyle(color: AppColors.error)),
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
                    label: '${template.lessonDurationMinutes}분',
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
                    label: '회당 ${template.formattedPricePerLesson}',
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
                    color: AppColors.textTertiaryLight,
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
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.textTertiaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? AppColors.primary : AppColors.textTertiaryLight,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isActive ? AppColors.primary : AppColors.textTertiaryLight,
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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLarge),
        ),
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Title
              Text(
                isEditing ? '수강권 수정' : '수강권 수강권 추가',
                style: AppTypography.headingMedium,
              ),
              const SizedBox(height: AppSpacing.space4),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '이름 *',
                  hintText: '예: 8회권, 기본 패키지',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요';
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
                label: '레슨 횟수',
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
                label: '수업 시간',
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
                label: '유효기간',
              ),
              const SizedBox(height: AppSpacing.space4),

              // Price field
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: '가격 (원) *',
                  hintText: '예: 400000',
                  prefixText: '₩ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '가격을 입력해주세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '숫자만 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space4),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명 (선택)',
                  hintText: '예: 가장 인기 있는 패키지입니다',
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
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space3,
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isEditing ? '수정하기' : '추가하기',
                          style: AppTypography.bodyLarge.copyWith(
                            color: Colors.white,
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
        color: _isAutoProposalEnabled
            ? AppColors.success.withValues(alpha: 0.05)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: _isAutoProposalEnabled
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.borderLight,
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
                  activeColor: AppColors.success,
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
                        color: _isAutoProposalEnabled
                            ? AppColors.success
                            : AppColors.textTertiaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '자동 제안 대상',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _isAutoProposalEnabled
                              ? AppColors.textPrimaryLight
                              : AppColors.textSecondaryLight,
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
                  ? '체험레슨 완료 또는 수강권 만료 시 학생에게\n'
                      '이 수강권이 자동으로 제안됩니다.'
                  : '이 수강권은 선생님이 직접 제안할 때만 사용됩니다.\n'
                      '자동 제안에 포함되지 않습니다.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
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
        description: _descriptionController.text.trim().isNotEmpty
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
            content: Text(isEditing ? '수강권이 수정되었습니다' : '수강권이 추가되었습니다'),
            backgroundColor: AppColors.practiceGood,
          ),
        );
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
        setState(() => _isSaving = false);
      }
    }
  }
}
