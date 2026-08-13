import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/price_input.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/selectors/selectors.dart';
import '../../../profile/domain/entities/teacher_settings.dart';
import '../../../settings/settings_facade.dart';
import '../../domain/entities/subscription_template.dart';

/// Add/edit sheet for a [SubscriptionTemplate].
///
/// Self-surfaced (owns its surface + scroll + handle) → callers use
/// `showNotebookModalBottomSheet` (see SubscriptionTemplateListScreen).
///
/// Pricing UX: a teacher's [TeacherSettings.lessonPriceTable] (악기×레벨→회당가)
/// is the source of the regular price (정가). Picking 악기+레벨 auto-fills the
/// regular price (회당가 × 횟수); the teacher then enters a sale price (판매가).
/// When 판매가 < 정가 the card/sheet shows the regular price struck through plus
/// the discount rate. Both prices are editable so teachers without a price table
/// can enter them manually.
class SubscriptionTemplateFormSheet extends ConsumerStatefulWidget {
  final String teacherId;
  final SubscriptionTemplate? template;
  final Future<void> Function(SubscriptionTemplate template) onSave;

  const SubscriptionTemplateFormSheet({
    super.key,
    required this.teacherId,
    this.template,
    required this.onSave,
  });

  @override
  ConsumerState<SubscriptionTemplateFormSheet> createState() =>
      _SubscriptionTemplateFormSheetState();
}

class _SubscriptionTemplateFormSheetState
    extends ConsumerState<SubscriptionTemplateFormSheet> {
  /// Level keys — match the 2nd-level keys of [TeacherSettings.lessonPriceTable].
  static const _levelKeys = <String>['beginner', 'intermediate', 'advanced'];

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController; // 판매가 (sale price)
  late TextEditingController _regularPriceController; // 정가 (regular price)
  late TextEditingController _customLessonsController;
  late TextEditingController _customDurationController;
  late TextEditingController _customValidityController;

  // Price-table autofill helpers (not persisted on the template).
  String? _selectedInstrument;
  String? _selectedLevel;

  int _totalLessons = 8;
  int _lessonDuration = 50;
  int _validityDays = 90;
  bool _isCustomLessons = false;
  bool _isCustomDuration = false;
  bool _isCustomValidity = false;
  bool _isSaving = false;
  bool _isAutoProposalEnabled = true;

  bool get isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _nameController = TextEditingController(text: t?.name ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _priceController = TextEditingController(
      text: t != null ? formatPriceWithCommas(t.price) : '',
    );
    _regularPriceController = TextEditingController(
      text:
          t?.regularPrice != null
              ? formatPriceWithCommas(t!.regularPrice!)
              : '',
    );
    _customLessonsController = TextEditingController();
    _customDurationController = TextEditingController();
    _customValidityController = TextEditingController();

    if (t != null) {
      _totalLessons = t.totalLessons;
      _lessonDuration = t.lessonDurationMinutes;
      _validityDays = t.validityDays;
      _isAutoProposalEnabled = t.isAutoProposalEnabled;

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
    _regularPriceController.dispose();
    _customLessonsController.dispose();
    _customDurationController.dispose();
    _customValidityController.dispose();
    super.dispose();
  }

  String _levelLabel(String key) => switch (key) {
    'beginner' => AppStrings.experienceLevelBeginner,
    'intermediate' => AppStrings.experienceLevelIntermediate,
    'advanced' => AppStrings.experienceLevelAdvanced,
    _ => key,
  };

  /// Recompute the regular price from the price table when 악기+레벨 are known.
  /// [prefillSale] also seeds the (empty) sale price so the teacher can lower it.
  void _applyTablePrice(
    TeacherSettings? settings, {
    required bool prefillSale,
  }) {
    final inst = _selectedInstrument;
    final lvl = _selectedLevel;
    if (settings == null || inst == null || lvl == null) return;
    final perLesson = settings.getPrice(inst, lvl);
    if (perLesson == null) return;
    final regular = perLesson * _totalLessons;
    setState(() {
      _regularPriceController.text = formatPriceWithCommas(regular);
      if (prefillSale && parsePrice(_priceController.text) == null) {
        _priceController.text = formatPriceWithCommas(regular);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(teacherSettingsNotifierProvider).valueOrNull;
    final priceTable = settings?.lessonPriceTable ?? const {};
    // Instruments that actually have prices configured (autofill candidates).
    final instruments = priceTable.keys.toList();

    final regular = parsePrice(_regularPriceController.text);
    final sale = parsePrice(_priceController.text);
    final hasDiscount = regular != null && sale != null && regular > sale;
    final discountPct =
        hasDiscount ? (((regular - sale) / regular) * 100).round() : 0;

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
              const Center(child: BottomSheetHandle(margin: EdgeInsets.zero)),
              const SizedBox(height: AppSpacing.space4),

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
                  // 정가 = 회당가 × 횟수 → 횟수 변경 시 재계산 (판매가는 유지).
                  _applyTablePrice(settings, prefillSale: false);
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

              // 가격표 연동 (선택) — 악기·레벨 선택 시 정가 자동 입력.
              // 가격표가 비어 있으면 picker 를 숨기고 수동 입력만 노출.
              if (instruments.isNotEmpty) ...[
                Text(
                  AppStrings.templatePriceAutofillHint,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedInstrument,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: AppStrings.templateInstrumentLabel,
                        ),
                        items: [
                          for (final inst in instruments)
                            DropdownMenuItem(value: inst, child: Text(inst)),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedInstrument = value);
                          _applyTablePrice(settings, prefillSale: true);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedLevel,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: AppStrings.levelLabel,
                        ),
                        items: [
                          for (final lvl in _levelKeys)
                            DropdownMenuItem(
                              value: lvl,
                              child: Text(_levelLabel(lvl)),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedLevel = value);
                          _applyTablePrice(settings, prefillSale: true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),
              ],

              // 정가 (regular price) — optional, autofilled from price table.
              TextFormField(
                controller: _regularPriceController,
                decoration: const InputDecoration(
                  labelText: AppStrings.templateRegularPriceLabel,
                  hintText: AppStrings.templateRegularPriceHint,
                  prefixText: '₩ ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: const [ThousandsSeparatorInputFormatter()],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.space4),

              // 판매가 (sale price) — required, the actual price used downstream.
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: AppStrings.templatePriceLabel,
                  hintText: AppStrings.templatePriceHint,
                  prefixText: '₩ ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: const [ThousandsSeparatorInputFormatter()],
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.templatePriceRequired;
                  }
                  if (parsePrice(value) == null) {
                    return AppStrings.templatePriceNumbersOnly;
                  }
                  return null;
                },
              ),

              // 할인 미리보기 — 판매가 < 정가일 때만.
              if (hasDiscount) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  AppStrings.templateDiscountPreview(discountPct),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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

  /// 자동 제안 설정 섹션
  Widget _buildAutoProposalSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: _isAutoProposalEnabled ? AppColors.paperOkSoft : AppColors.paper,
        border: Border.all(
          color:
              _isAutoProposalEnabled
                  ? AppColors.paperOkSelected
                  : AppColors.inkQuaternary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      final sale = parsePrice(_priceController.text) ?? 0;
      final regular = parsePrice(_regularPriceController.text);
      // 정가는 판매가보다 클 때만 의미가 있다 — 아니면 단일가(null).
      final regularPrice = (regular != null && regular > sale) ? regular : null;

      final template = SubscriptionTemplate(
        id: widget.template?.id ?? '',
        ownerId: widget.teacherId,
        ownerType: SubscriptionTemplateOwnerType.teacher,
        name: _nameController.text.trim(),
        totalLessons: _totalLessons,
        lessonDurationMinutes: _lessonDuration,
        validityDays: _validityDays,
        price: sale,
        regularPrice: regularPrice,
        description:
            _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
        isActive: widget.template?.isActive ?? true,
        displayOrder: widget.template?.displayOrder ?? 0,
        createdAt: widget.template?.createdAt ?? DateTime.now(),
        isAutoProposalEnabled: _isAutoProposalEnabled,
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
