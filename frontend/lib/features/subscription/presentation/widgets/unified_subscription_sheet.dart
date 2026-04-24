import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../domain/entities/subscription_template.dart';
import '../providers/subscription_proposal_providers.dart';
import '../providers/subscription_template_providers.dart';

/// Unified bottom sheet for subscription proposal creation and direct issuance.
///
/// Template-first approach with progressive disclosure:
/// 1. Horizontal scrollable template cards (tap to select)
/// 2. Collapsible "direct input" section for custom values
/// 3. Bottom buttons: "direct issue" (outlined) + "send proposal" (filled)
///
/// Modes:
/// - "send proposal": multi-select (max 3), long-press to set recommended
/// - "direct issue": single select only, creates Subscription immediately
class UnifiedSubscriptionSheet extends ConsumerStatefulWidget {
  final String teacherId;
  final List<String> studentIds;
  final String? studentName;

  const UnifiedSubscriptionSheet({
    super.key,
    required this.teacherId,
    required this.studentIds,
    this.studentName,
  });

  /// Show the unified subscription sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String teacherId,
    required List<String> studentIds,
    String? studentName,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => UnifiedSubscriptionSheet(
            teacherId: teacherId,
            studentIds: studentIds,
            studentName: studentName,
          ),
    );
  }

  @override
  ConsumerState<UnifiedSubscriptionSheet> createState() =>
      _UnifiedSubscriptionSheetState();
}

class _UnifiedSubscriptionSheetState
    extends ConsumerState<UnifiedSubscriptionSheet> {
  final Set<String> _selectedTemplateIds = {};
  String? _recommendedTemplateId;
  bool _isDirectInputExpanded = false;
  bool _isSubmitting = false;

  // Direct input fields
  int? _customLessonCount;
  final _amountController = TextEditingController();
  int? _customValidityDays;

  static const _lessonCountOptions = [4, 8, 12];
  static const _validityDaysOptions = [60, 90, 120];
  static const _maxTemplateSelections = 3;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(
      activeTeacherTemplatesProvider(widget.teacherId),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: templatesAsync.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (_, __) => Center(
                        child: Text(
                          '오류가 발생했습니다.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ),
                  data:
                      (templates) => _buildContent(templates, scrollController),
                ),
              ),
              _buildBottomButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const BottomSheetHandle(
          width: 36,
          margin: EdgeInsets.only(top: AppSpacing.space2),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, size: AppSpacing.iconMD),
              ),
              const Spacer(),
              // Notebook × Score: 바텀시트 제목도 Playfair appBarTitle 로 통일.
              Text('수강권 발급', style: NotebookTypography.appBarTitle),
              const Spacer(),
              const SizedBox(width: AppSpacing.iconMD),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.inkQuaternary),
      ],
    );
  }

  Widget _buildContent(
    List<SubscriptionTemplate> templates,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        if (widget.studentName != null) ...[
          _buildStudentInfo(),
          const SizedBox(height: AppSpacing.space6),
        ],
        _buildSectionLabel('템플릿 선택'),
        const SizedBox(height: AppSpacing.space3),
        _buildTemplateCards(templates),
        const SizedBox(height: AppSpacing.space4),
        _buildDirectInputToggle(),
        if (_isDirectInputExpanded) ...[
          const SizedBox(height: AppSpacing.space3),
          _buildDirectInputForm(),
        ],
        const SizedBox(height: AppSpacing.space8),
      ],
    );
  }

  Widget _buildStudentInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            size: AppSpacing.iconSM,
            color: AppColors.inkSecondary,
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            widget.studentName!,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.inkSecondary,
      ),
    );
  }

  Widget _buildTemplateCards(List<SubscriptionTemplate> templates) {
    if (templates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space6),
        alignment: Alignment.center,
        child: Text(
          '등록된 템플릿이 없습니다',
          style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: templates.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.space2),
        itemBuilder: (context, index) {
          final template = templates[index];
          final isSelected = _selectedTemplateIds.contains(template.id);
          final isRecommended = _recommendedTemplateId == template.id;

          return GestureDetector(
            onTap: () => _onTemplateTap(template.id),
            onLongPress:
                isSelected && _selectedTemplateIds.length > 1
                    ? () => _setRecommended(template)
                    : null,
            child: _TemplateChip(
              template: template,
              isSelected: isSelected,
              isRecommended: isRecommended,
            ),
          );
        },
      ),
    );
  }

  void _onTemplateTap(String templateId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedTemplateIds.contains(templateId)) {
        _selectedTemplateIds.remove(templateId);
        if (_recommendedTemplateId == templateId) {
          _recommendedTemplateId =
              _selectedTemplateIds.isNotEmpty
                  ? _selectedTemplateIds.first
                  : null;
        }
      } else {
        if (_selectedTemplateIds.length < _maxTemplateSelections) {
          _selectedTemplateIds.add(templateId);
          _recommendedTemplateId ??= templateId;
        }
      }
    });
  }

  void _setRecommended(SubscriptionTemplate template) {
    HapticFeedback.mediumImpact();
    setState(() {
      _recommendedTemplateId = template.id;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${template.name}을 추천으로 지정했습니다'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.paperAccent,
      ),
    );
  }

  Widget _buildDirectInputToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDirectInputExpanded = !_isDirectInputExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
        child: Row(
          children: [
            Icon(
              _isDirectInputExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: AppSpacing.iconSM,
              color: AppColors.inkSecondary,
            ),
            const SizedBox(width: AppSpacing.space1),
            Text(
              '직접 입력',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(height: 1, width: 200, color: AppColors.inkQuaternary),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectInputForm() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormLabel('회차'),
          const SizedBox(height: AppSpacing.space2),
          _buildLessonCountChips(),
          const SizedBox(height: AppSpacing.space4),
          _buildFormLabel('금액'),
          const SizedBox(height: AppSpacing.space2),
          _buildAmountInput(),
          const SizedBox(height: AppSpacing.space4),
          _buildFormLabel('유효기간'),
          const SizedBox(height: AppSpacing.space1),
          if (_customLessonCount != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2),
              child: Text(
                '자동: $_autoValidityDays일',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ),
          _buildValidityChips(),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: AppTypography.bodySmall.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    );
  }

  Widget _buildLessonCountChips() {
    return Wrap(
      spacing: AppSpacing.space2,
      children: [
        ..._lessonCountOptions.map((count) {
          final isSelected = _customLessonCount == count;
          return ChoiceChip(
            label: Text('$count회'),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _customLessonCount = selected ? count : null;
                // Clear template selection when using direct input
                _selectedTemplateIds.clear();
                _recommendedTemplateId = null;
              });
            },
            selectedColor: AppColors.paperAccent.withValues(alpha: 0.15),
            labelStyle: AppTypography.bodySmall.copyWith(
              color: isSelected ? AppColors.paperAccent : AppColors.ink,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide(
              color:
                  isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
            ),
          );
        }),
        ChoiceChip(
          label: const Text('직접입력'),
          selected:
              _customLessonCount != null &&
              !_lessonCountOptions.contains(_customLessonCount),
          onSelected: (_) => _showCustomLessonCountDialog(),
          selectedColor: AppColors.paperAccent.withValues(alpha: 0.15),
          labelStyle: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
          side: const BorderSide(color: AppColors.inkQuaternary),
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: TextField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          border: InputBorder.none,
          hintText: '금액을 입력하세요',
          hintStyle: AppTypography.bodySmall.copyWith(
            color: AppColors.inkTertiary,
          ),
          suffixText: '원',
          suffixStyle: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        style: AppTypography.bodyMedium,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );
  }

  Widget _buildValidityChips() {
    return Wrap(
      spacing: AppSpacing.space2,
      children:
          _validityDaysOptions.map((days) {
            final isSelected =
                (_customValidityDays ?? _autoValidityDays) == days;
            return ChoiceChip(
              label: Text('$days일'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _customValidityDays = selected ? days : null;
                });
              },
              selectedColor: AppColors.paperAccent.withValues(alpha: 0.15),
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.paperAccent : AppColors.ink,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color:
                    isSelected
                        ? AppColors.paperAccent
                        : AppColors.inkQuaternary,
              ),
            );
          }).toList(),
    );
  }

  /// Auto-calculate validity based on lesson count.
  int get _autoValidityDays {
    final count = _customLessonCount ?? 0;
    if (count <= 4) return 60;
    if (count <= 8) return 90;
    return 120;
  }

  Widget _buildBottomButtons() {
    final canSubmit =
        (_selectedTemplateIds.isNotEmpty || _hasValidDirectInput) &&
        !_isSubmitting;
    final isSingleSelect = _selectedTemplateIds.length <= 1;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.space3,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.space3,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: Row(
        children: [
          if (isSingleSelect)
            Expanded(
              child: OutlinedButton(
                onPressed: canSubmit ? _onDirectIssue : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space3,
                  ),
                  side: BorderSide(
                    color:
                        canSubmit
                            ? AppColors.paperAccent
                            : AppColors.inkQuaternary,
                  ),
                  shape: RoundedRectangleBorder(
                    
                  ),
                ),
                child: Text(
                  '바로 발급',
                  style: AppTypography.buttonSmall.copyWith(
                    color:
                        canSubmit
                            ? AppColors.paperAccent
                            : AppColors.inkQuaternary,
                  ),
                ),
              ),
            ),

          if (isSingleSelect) const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: ElevatedButton(
              onPressed: canSubmit ? _onSendProposal : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space3,
                ),
                shape: RoundedRectangleBorder(
                  
                ),
                disabledBackgroundColor: AppColors.paperAccent.withValues(
                  alpha: 0.3,
                ),
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text(
                        _selectedTemplateIds.length > 1
                            ? '${_selectedTemplateIds.length}개 제안 보내기'
                            : '제안 보내기',
                        style: AppTypography.buttonSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasValidDirectInput {
    return _customLessonCount != null &&
        _amountController.text.isNotEmpty &&
        (int.tryParse(_amountController.text) ?? 0) > 0;
  }

  Future<void> _onDirectIssue() async {
    if (_selectedTemplateIds.isEmpty && !_hasValidDirectInput) return;

    if (_selectedTemplateIds.isNotEmpty) {
      final templateId = _selectedTemplateIds.first;
      final studentId = widget.studentIds.first;
      Navigator.of(context).pop();
      context.push(
        '${AppRoutes.issueSubscription}?studentId=$studentId&templateId=$templateId',
      );
      return;
    }

    final studentId = widget.studentIds.first;
    Navigator.of(context).pop();
    context.push('${AppRoutes.issueSubscription}?studentId=$studentId');
  }

  Future<void> _onSendProposal() async {
    if (_selectedTemplateIds.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final notifier = ref.read(subscriptionProposalNotifierProvider.notifier);

      final templateId = _selectedTemplateIds.first;
      final templateAsync = ref.read(subscriptionTemplateProvider(templateId));
      final templateName = templateAsync.valueOrNull?.name ?? '수강권';

      for (final studentId in widget.studentIds) {
        await notifier.createMultiChoiceProposal(
          teacherId: widget.teacherId,
          studentId: studentId,
          templateIds: _selectedTemplateIds.toList(),
          recommendedTemplateId:
              _selectedTemplateIds.length > 1 ? _recommendedTemplateId : null,
          templateName: templateName,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedTemplateIds.length > 1
                  ? '${_selectedTemplateIds.length}개 수강권 제안을 보냈습니다'
                  : '수강권 제안을 보냈습니다',
            ),
            backgroundColor: AppColors.paperOk,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('제안 실패. 다시 시도해주세요.'),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showCustomLessonCountDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder:
          (context) => AlertDialog(
            // Notebook × Score: 전역 dialogTheme(titleTextStyle=dialogTitle) 적용을 위해 style 오버라이드 제거.
            title: const Text('회차 입력'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '횟수를 입력하세요',
                suffixText: '회',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () {
                  final value = int.tryParse(controller.text);
                  if (value != null && value > 0) {
                    Navigator.of(context).pop(value);
                  }
                },
                child: const Text(AppStrings.confirm),
              ),
            ],
          ),
    );

    controller.dispose();

    if (result != null) {
      setState(() {
        _customLessonCount = result;
        _selectedTemplateIds.clear();
        _recommendedTemplateId = null;
      });
    }
  }
}

/// Compact template card for horizontal scrolling.
class _TemplateChip extends StatelessWidget {
  final SubscriptionTemplate template;
  final bool isSelected;
  final bool isRecommended;

  const _TemplateChip({
    required this.template,
    required this.isSelected,
    required this.isRecommended,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 120,
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color:
            isSelected
                ? AppColors.paperAccent.withValues(alpha: 0.05)
                : AppColors.paper,
        border: Border.all(
          color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space1,
                vertical: 1,
              ),
              margin: const EdgeInsets.only(bottom: AppSpacing.space1),
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withValues(alpha: 0.15),
              ),
              child: Text(
                '추천',
                style: AppTypography.caption.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(
            template.name,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.paperAccent : AppColors.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            template.formattedPrice,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color:
                  isSelected ? AppColors.paperAccent : AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            template.formattedValidity,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ],
      ),
    );
  }
}
