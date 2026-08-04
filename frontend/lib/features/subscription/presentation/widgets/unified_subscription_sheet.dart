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
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../students/students_facade.dart';
import '../../domain/entities/subscription_template.dart';
import '../extensions/subscription_template_visuals.dart';
import '../providers/subscription_proposal_providers.dart';
import '../providers/subscription_template_providers.dart';
import 'duplicate_proposal_dialog.dart';
import 'bank_account_guard.dart';

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
    await showNotebookBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      padding: EdgeInsets.zero,
      showHandle: false,
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
                          AppStrings.errorOccurred,
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
              Text(
                AppStrings.unifiedSubscriptionAppBarTitle,
                style: NotebookTypography.appBarTitle,
              ),
              const Spacer(),
              const SizedBox(width: AppSpacing.iconMD),
            ],
          ),
        ),
        const ThinRule(),
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
        _buildSectionLabel(AppStrings.unifiedSubscriptionTemplateSection),
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
      decoration: BoxDecoration(color: AppColors.paperDark),
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
          AppStrings.unifiedSubscriptionNoTemplates,
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
        content: Text(
          AppStrings.proposalCreateRecommendedDesignatedFormat(template.name),
        ),
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
              AppStrings.unifiedSubscriptionDirectInputToggle,
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
          _buildFormLabel(AppStrings.issueFormLessonsTitle),
          const SizedBox(height: AppSpacing.space2),
          _buildLessonCountChips(),
          const SizedBox(height: AppSpacing.space4),
          _buildFormLabel(AppStrings.amountLabel),
          const SizedBox(height: AppSpacing.space2),
          _buildAmountInput(),
          const SizedBox(height: AppSpacing.space4),
          _buildFormLabel(AppStrings.validityPeriod),
          const SizedBox(height: AppSpacing.space1),
          if (_customLessonCount != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2),
              child: Text(
                AppStrings.unifiedSubscriptionAutoValidityFormat(
                  _autoValidityDays,
                ),
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
            label: Text(AppStrings.unifiedSubscriptionLessonChipFormat(count)),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _customLessonCount = selected ? count : null;
                // Clear template selection when using direct input
                _selectedTemplateIds.clear();
                _recommendedTemplateId = null;
              });
            },
            selectedColor: AppColors.paperAccentSoft,
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
          label: const Text(AppStrings.unifiedSubscriptionDirectInputChip),
          selected:
              _customLessonCount != null &&
              !_lessonCountOptions.contains(_customLessonCount),
          onSelected: (_) => _showCustomLessonCountDialog(),
          selectedColor: AppColors.paperAccentSoft,
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
          hintText: AppStrings.unifiedSubscriptionAmountHint,
          hintStyle: AppTypography.bodySmall.copyWith(
            color: AppColors.inkTertiary,
          ),
          suffixText: AppStrings.amountUnit,
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
              label: Text(AppStrings.unifiedSubscriptionDaysChipFormat(days)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _customValidityDays = selected ? days : null;
                });
              },
              selectedColor: AppColors.paperAccentSoft,
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

  /// §2.7 (AC-5.1) — 미가입(수기) 단일 학생은 제안을 받을 수 없다 (respond API
  /// 가 학생 계정 전제). 제안 버튼을 숨기고 즉시 발급만 노출한다.
  /// 배치(복수 학생)·조회 실패는 기존 동작 유지 (connected 가정).
  bool get _proposalAvailable {
    if (widget.studentIds.length != 1) return true;
    final students = ref.read(studentsProvider).valueOrNull ?? [];
    final match = students.where((s) => s.id == widget.studentIds.first);
    return match.isEmpty || match.first.isAppConnected;
  }

  Widget _buildBottomButtons() {
    final canSubmit =
        (_selectedTemplateIds.isNotEmpty || _hasValidDirectInput) &&
        !_isSubmitting;
    final proposalAvailable = _proposalAvailable;
    // 제안 불가(미가입) 시 즉시 발급 단독 노출 — 다중 템플릿 선택은 제안 전용
    // 이므로 이 경우에도 발급 버튼을 유지한다.
    final isSingleSelect =
        _selectedTemplateIds.length <= 1 || !proposalAvailable;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      shape: RoundedRectangleBorder(),
                    ),
                    child: Text(
                      AppStrings.unifiedSubscriptionDirectIssueButton,
                      style: AppTypography.buttonSmall.copyWith(
                        color:
                            canSubmit
                                ? AppColors.paperAccent
                                : AppColors.inkQuaternary,
                      ),
                    ),
                  ),
                ),
              if (isSingleSelect && proposalAvailable)
                const SizedBox(width: AppSpacing.space2),
              if (proposalAvailable)
                Expanded(
                  child: ElevatedButton(
                    onPressed: canSubmit ? _onSendProposal : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.paperAccent,
                      foregroundColor: AppColors.paper,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space3,
                      ),
                      shape: RoundedRectangleBorder(),
                      disabledBackgroundColor: AppColors.paperAccentSoft,
                    ),
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.paper,
                              ),
                            )
                            : Text(
                              _selectedTemplateIds.length > 1
                                  ? AppStrings.unifiedSubscriptionMultiSendFormat(
                                    _selectedTemplateIds.length,
                                  )
                                  : AppStrings.proposalSend,
                              style: AppTypography.buttonSmall.copyWith(
                                color: AppColors.paper,
                              ),
                            ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          // #769: 발급 방식 차이 캡션 — 버튼과 동일한 Expanded/SizedBox 구조로
          // 각 버튼 아래 정렬. 로직 변경 없이 설명만 추가.
          Row(
            children: [
              if (isSingleSelect) ...[
                Expanded(
                  child: Text(
                    AppStrings.unifiedSubscriptionDirectIssueCaption,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
              ],
              if (proposalAvailable)
                Expanded(
                  child: Text(
                    AppStrings.unifiedSubscriptionProposalCaption,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ),
            ],
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
    if (widget.studentIds.isEmpty) return; // #72 빈 학생 목록 .first StateError 방지
    if (_selectedTemplateIds.isEmpty && !_hasValidDirectInput) return;

    // The issue screen takes exactly one template — routing `.first` here
    // silently dropped the other selections. Guard instead of dropping.
    if (_selectedTemplateIds.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            AppStrings.unifiedSubscriptionDirectIssueSingleTemplateOnly,
          ),
          backgroundColor: AppColors.paperAccent,
        ),
      );
      return;
    }

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
    // 재진입 가드 (#D2) — await 전 동기적으로 _isSubmitting 을 세워, 더블탭이
    // 은행/중복 체크를 통과하기 전에 두 번째 발송(중복 제안)을 차단한다.
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      // #847 입금 계좌 미등록 시 제안 차단(학생 결제 불가 dead-end 방지).
      final bankOk = await ensureBankAccountRegistered(
        context: context,
        ref: ref,
        teacherId: widget.teacherId,
      );
      if (!bankOk || !mounted) return;

      // #696 §3.1.5 — single-student send: block while a pending/paymentNotified
      // proposal already exists for this student. Batch sends rely on the BE
      // 409 constraint (the per-student dialog UX does not fit batch flow).
      if (widget.studentIds.length == 1) {
        final canProceed = await ensureNoDuplicateProposal(
          context: context,
          ref: ref,
          teacherId: widget.teacherId,
          studentId: widget.studentIds.first,
          studentName: widget.studentName ?? AppStrings.student,
        );
        if (!canProceed || !mounted) return;
      }

      final notifier = ref.read(subscriptionProposalNotifierProvider.notifier);

      final templateId = _selectedTemplateIds.first;
      final templateAsync = ref.read(subscriptionTemplateProvider(templateId));
      final templateName =
          templateAsync.valueOrNull?.name ?? AppStrings.subscription;

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
                  ? AppStrings.proposalCreateMultiSentMessageFormat(
                    _selectedTemplateIds.length,
                  )
                  : AppStrings.proposalCreateSentMessage,
            ),
            backgroundColor: AppColors.paperOk,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.proposalCreateFailMessage),
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
    final result = await showNotebookDialog<int>(
      context: context,
      title: AppStrings.unifiedSubscriptionLessonCountDialogTitle,
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          hintText: AppStrings.unifiedSubscriptionLessonCountHint,
          suffixText: AppStrings.lessonsUnit,
        ),
      ),
      cancelLabel: AppStrings.cancel,
      onConfirm: () {
        final value = int.tryParse(controller.text);
        if (value != null && value > 0) {
          Navigator.of(context).pop(value);
        }
      },
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
        color: isSelected ? AppColors.paperAccentSoft : AppColors.paper,
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
              decoration: BoxDecoration(color: AppColors.paperAccentSoft),
              child: Text(
                AppStrings.templateRecommendedBadge,
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
