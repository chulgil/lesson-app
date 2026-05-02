import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../domain/entities/lesson_policy.dart';
import '../providers/lesson_policy_providers.dart';
import '../widgets/chip_input_field.dart';

/// Screen for teachers to configure lesson policies.
class LessonPolicyScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final String? lessonClassId;

  const LessonPolicyScreen({
    super.key,
    required this.teacherId,
    this.lessonClassId,
  });

  @override
  ConsumerState<LessonPolicyScreen> createState() => _LessonPolicyScreenState();
}

class _LessonPolicyScreenState extends ConsumerState<LessonPolicyScreen> {
  // 변경/취소 정책
  int _minCancelHours = 4;
  int _maxChangesPerMonth = 2;
  bool _allowSameDayCancel = false;

  // 노쇼 정책
  bool _deductLessonOnNoShow = true;
  int _gracePeriodMinutes = 15;

  // 이월 정책
  bool _allowCarryover = true;
  int _maxCarryoverLessons = 1;
  int _carryoverPeriodMonths = 1;

  // Controllers
  final _cancelHoursController = TextEditingController();
  final _changesController = TextEditingController();
  final _graceController = TextEditingController();
  final _carryoverCountController = TextEditingController();
  final _carryoverMonthsController = TextEditingController();

  String? _existingPolicyId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingPolicy();
  }

  Future<void> _loadExistingPolicy() async {
    final repository = ref.read(lessonPolicyRepositoryProvider);
    final policy = await repository.getEffectivePolicy(
      teacherId: widget.teacherId,
      lessonClassId: widget.lessonClassId,
    );

    if (policy != null && mounted) {
      setState(() {
        _existingPolicyId = policy.id;
        _minCancelHours = policy.minCancelHours;
        _maxChangesPerMonth = policy.maxChangesPerMonth;
        _allowSameDayCancel = policy.allowSameDayCancel;
        _deductLessonOnNoShow = policy.deductLessonOnNoShow;
        _gracePeriodMinutes = policy.gracePeriodMinutes;
        _allowCarryover = policy.allowCarryover;
        _maxCarryoverLessons = policy.maxCarryoverLessons;
        _carryoverPeriodMonths = policy.carryoverPeriodMonths;

        _cancelHoursController.text = _minCancelHours.toString();
        _changesController.text = _maxChangesPerMonth.toString();
        _graceController.text = _gracePeriodMinutes.toString();
        _carryoverCountController.text = _maxCarryoverLessons.toString();
        _carryoverMonthsController.text = _carryoverPeriodMonths.toString();

        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cancelHoursController.dispose();
    _changesController.dispose();
    _graceController.dispose();
    _carryoverCountController.dispose();
    _carryoverMonthsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lessonClassId != null
              ? AppStrings.policyClassAppBarTitle
              : AppStrings.policyLessonAppBarTitle,
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  _buildCancelPolicy(),
                  const SizedBox(height: AppSpacing.space6),
                  _buildNoShowPolicy(),
                  const SizedBox(height: AppSpacing.space6),
                  _buildCarryoverPolicy(),
                  const SizedBox(height: AppSpacing.space6),
                  _buildPolicySummary(),
                  const SizedBox(height: AppSpacing.space6),
                  _buildRelatedSettings(),
                  const SizedBox(height: AppSpacing.space8),
                ],
              ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.paperAccent),
        const SizedBox(width: AppSpacing.space2),
        // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17 패턴).
        Text(title, style: NotebookTypography.sectionTitle),
      ],
    );
  }

  Widget _buildCancelPolicy() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            AppStrings.policyChangeCancelHeader,
            Icons.event_busy,
          ),
          const SizedBox(height: AppSpacing.space4),

          // 최소 취소 시간
          ChipInputField(
            title: AppStrings.policyMinCancelHoursTitle,
            options: const [2, 4, 24],
            currentValue: _minCancelHours,
            onChanged: (value) => setState(() => _minCancelHours = value),
            controller: _cancelHoursController,
            suffix: AppStrings.policyHoursBeforeSuffix,
            labelFormatter: (v) => AppStrings.policyHoursFormat(v),
          ),

          const SizedBox(height: AppSpacing.space4),

          // 월 변경 횟수
          ChipInputField(
            title: AppStrings.policyMonthlyChangesTitle,
            options: const [1, 2, 99],
            currentValue: _maxChangesPerMonth,
            onChanged: (value) => setState(() => _maxChangesPerMonth = value),
            controller: _changesController,
            suffix: AppStrings.lessonsUnit,
            labelFormatter:
                (v) =>
                    v >= 99
                        ? AppStrings.policyUnlimited
                        : AppStrings.policyTimesFormat(v),
          ),

          const SizedBox(height: AppSpacing.space4),

          // 당일 취소 허용
          _buildToggleRow(
            AppStrings.policyAllowSameDayCancelToggle,
            _allowSameDayCancel,
            (value) => setState(() => _allowSameDayCancel = value),
          ),
        ],
      ),
    );
  }

  Widget _buildNoShowPolicy() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(AppStrings.policyNoShowHeader, Icons.person_off),
          const SizedBox(height: AppSpacing.space4),

          // 노쇼 시 횟수 차감
          _buildToggleRow(
            AppStrings.policyNoShowDeduct,
            _deductLessonOnNoShow,
            (value) => setState(() => _deductLessonOnNoShow = value),
          ),

          const SizedBox(height: AppSpacing.space4),

          // 지각 허용 시간
          ChipInputField(
            title: AppStrings.policyGracePeriodTitle,
            options: const [10, 15, 30],
            currentValue: _gracePeriodMinutes,
            onChanged: (value) => setState(() => _gracePeriodMinutes = value),
            controller: _graceController,
            suffix: AppStrings.minuteLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildCarryoverPolicy() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            AppStrings.policyCarryoverHeader,
            Icons.swap_horiz,
          ),
          const SizedBox(height: AppSpacing.space4),

          // 이월 허용
          _buildToggleRow(
            AppStrings.policyAllowCarryoverToggle,
            _allowCarryover,
            (value) => setState(() => _allowCarryover = value),
          ),

          if (_allowCarryover) ...[
            const SizedBox(height: AppSpacing.space4),

            // 최대 이월 횟수
            ChipInputField(
              title: AppStrings.policyMaxCarryoverTitle,
              options: const [1, 2, 3],
              currentValue: _maxCarryoverLessons,
              onChanged:
                  (value) => setState(() => _maxCarryoverLessons = value),
              controller: _carryoverCountController,
              suffix: AppStrings.lessonsUnit,
            ),

            const SizedBox(height: AppSpacing.space4),

            // 이월 유효 기간
            ChipInputField(
              title: AppStrings.policyCarryoverPeriodTitle,
              options: const [1, 2, 3],
              currentValue: _carryoverPeriodMonths,
              onChanged:
                  (value) => setState(() => _carryoverPeriodMonths = value),
              controller: _carryoverMonthsController,
              suffix: AppStrings.policyMonthsSuffix,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.paperAccent,
        ),
      ],
    );
  }

  Widget _buildPolicySummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccentSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notebook × Score: 강조된 요약 섹션 제목도 Playfair sectionTitle 로 통일,
          // paperAccent 색상만 copyWith 로 유지 (§7.17 패턴, color override 변형).
          Text(
            AppStrings.policySummaryHeader,
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          _buildSummaryItem(
            AppStrings.policyCancelLabel,
            _allowSameDayCancel
                ? AppStrings.policyCancelSameDay
                : AppStrings.policyHoursBeforeFormat(_minCancelHours),
          ),
          _buildSummaryItem(
            AppStrings.policyChangeLabel,
            _maxChangesPerMonth >= 99
                ? AppStrings.policyUnlimited
                : AppStrings.policyMonthlyChangesFormat(_maxChangesPerMonth),
          ),
          _buildSummaryItem(
            AppStrings.policyNoShowLabel,
            _deductLessonOnNoShow
                ? AppStrings.policyDeductCount
                : AppStrings.policyKeepCount,
          ),
          _buildSummaryItem(
            AppStrings.policyLatenessLabel,
            AppStrings.policyLatenessFormat(_gracePeriodMinutes),
          ),
          _buildSummaryItem(
            AppStrings.policyCarryoverLabel,
            _allowCarryover
                ? AppStrings.policyCarryoverFormat(
                  _maxCarryoverLessons,
                  _carryoverPeriodMonths,
                )
                : AppStrings.policyNotAllowed,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(AppStrings.policyRelatedHeader, Icons.settings),
        const SizedBox(height: AppSpacing.space3),
        _buildRelatedSettingItem(
          icon: Icons.schedule,
          label: AppStrings.lessonTimeSettings,
          onTap: () => context.push(AppRoutes.lessonTimeSettings),
        ),
        _buildRelatedSettingItem(
          icon: Icons.payments_outlined,
          label: AppStrings.policyTuitionManagement,
          onTap: () => context.push(AppRoutes.outstandingPayments),
        ),
        _buildRelatedSettingItem(
          icon: Icons.library_books_outlined,
          label: AppStrings.policyTemplateManagement,
          onTap: () => context.push(AppRoutes.tipTemplateManagement),
        ),
      ],
    );
  }

  Widget _buildRelatedSettingItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space3,
          horizontal: AppSpacing.space2,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.inkSecondary),
            const SizedBox(width: AppSpacing.space3),
            Expanded(child: Text(label, style: AppTypography.bodyMedium)),
            Icon(Icons.chevron_right, color: AppColors.inkTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: FilledButton(
          onPressed: _savePolicy,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text(AppStrings.save),
        ),
      ),
    );
  }

  Future<void> _savePolicy() async {
    final policy = LessonPolicy(
      id: _existingPolicyId ?? const Uuid().v4(),
      teacherId: widget.teacherId,
      lessonClassId: widget.lessonClassId,
      minCancelHours: _minCancelHours,
      maxChangesPerMonth: _maxChangesPerMonth,
      allowSameDayCancel: _allowSameDayCancel,
      deductLessonOnNoShow: _deductLessonOnNoShow,
      gracePeriodMinutes: _gracePeriodMinutes,
      allowCarryover: _allowCarryover,
      maxCarryoverLessons: _maxCarryoverLessons,
      carryoverPeriodMonths: _carryoverPeriodMonths,
      createdAt: DateTime.now(),
    );

    try {
      final repository = ref.read(lessonPolicyRepositoryProvider);
      await repository.savePolicy(policy);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.policySavedSnackbar),
            backgroundColor: AppColors.paperAccent,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.proposalSettingsSaveFailedSnackbar),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }
}
