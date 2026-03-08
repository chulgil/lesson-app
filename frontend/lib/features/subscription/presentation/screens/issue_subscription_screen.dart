import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../relationship/presentation/providers/relationship_providers.dart';
import '../../../students/domain/entities/class_membership.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../../../schedule/domain/entities/schedule_confirmation_card.dart';
import '../../../schedule/presentation/providers/lesson_request_providers.dart';
import '../../../schedule/presentation/providers/schedule_confirmation_card_providers.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';
import '../widgets/chip_input_field.dart';

/// Screen for teachers to issue subscriptions to students.
/// Supports both single student and batch issuance (multiple students).
class IssueSubscriptionScreen extends ConsumerStatefulWidget {
  /// List of student IDs to issue subscriptions to.
  /// For single student, this will contain one ID.
  /// For batch issuance, this will contain multiple IDs.
  final List<String> studentIds;
  final String? membershipId;
  final String? lessonRequestId;
  final List<String> lessonRequestIds;

  const IssueSubscriptionScreen({
    super.key,
    required this.studentIds,
    this.membershipId,
    this.lessonRequestId,
    this.lessonRequestIds = const [],
  });

  /// Whether this is a batch issuance (multiple students)
  bool get isBatchMode => studentIds.length > 1;

  /// Primary student ID (first in list, used for single mode or as reference)
  String get primaryStudentId => studentIds.isNotEmpty ? studentIds.first : '';

  @override
  ConsumerState<IssueSubscriptionScreen> createState() =>
      _IssueSubscriptionScreenState();
}

class _IssueSubscriptionScreenState
    extends ConsumerState<IssueSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  SubscriptionType _selectedType = SubscriptionType.package;
  String? _selectedMembershipId;
  bool _isPaymentConfirmed = true;
  SubscriptionPaymentMethod _selectedPaymentMethod =
      SubscriptionPaymentMethod.bankTransfer;
  int _totalLessons = 8;
  int _validityDays = 90; // 회차권 유효기간 (일)
  int _monthsCount = 1;
  int _originalAmount = 0; // 정가
  int _discountPercent = 0; // 할인율 (0~100)
  int _bonusLessons = 0; // 보너스 횟수
  String? _bonusReason; // 보너스 사유 (선택된 칩)
  String _customBonusReason = ''; // 기타 선택 시 직접 입력 사유
  DateTime? _startDate;

  final _amountController = TextEditingController();
  final _lessonsController = TextEditingController();
  final _validityController = TextEditingController();
  final _discountController = TextEditingController();
  final _bonusController = TextEditingController();
  final _customBonusReasonController = TextEditingController();

  /// 실제 사용될 보너스 사유 (기타 선택 시 직접 입력값 사용)
  String? get _effectiveBonusReason {
    if (_bonusLessons == 0) return null;
    if (_bonusReason == '기타') {
      return _customBonusReason.isNotEmpty ? _customBonusReason : null;
    }
    return _bonusReason;
  }

  /// 할인 적용된 최종 금액
  int get _finalAmount {
    if (_discountPercent <= 0) return _originalAmount;
    return (_originalAmount * (100 - _discountPercent) / 100).round();
  }

  @override
  void initState() {
    super.initState();
    _selectedMembershipId = widget.membershipId;
    _startDate = DateTime.now();
    // 기본값 설정
    _lessonsController.text = _totalLessons.toString();
    _validityController.text = _validityDays.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _lessonsController.dispose();
    _validityController.dispose();
    _discountController.dispose();
    _bonusController.dispose();
    _customBonusReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For single student mode, use membership selector
    // For batch mode, skip membership selection (use subscription template approach)
    final membershipsAsync =
        widget.isBatchMode
            ? const AsyncValue<List<ClassMembership>>.data([])
            : ref.watch(studentMembershipsProvider(widget.primaryStudentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isBatchMode
              ? '수강권 발급 (${widget.studentIds.length}명)'
              : '수강권 발급',
        ),
        centerTitle: true,
      ),
      body:
          widget.isBatchMode
              ? _buildBatchForm()
              : membershipsAsync.when(
                data: (memberships) {
                  if (memberships.isEmpty) {
                    return _buildNoMembershipState();
                  }

                  // Auto-select first membership if none selected
                  if (_selectedMembershipId == null && memberships.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _selectedMembershipId = memberships.first.id;
                      });
                    });
                  }

                  return _buildForm(memberships);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _buildErrorState(error.toString()),
              ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildForm(List<ClassMembership> memberships) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Membership selector (if multiple)
          if (memberships.length > 1) ...[
            _buildMembershipSelector(memberships),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Selected membership info
          if (_selectedMembershipId != null) _buildMembershipInfo(memberships),

          const SizedBox(height: AppSpacing.space6),

          // Subscription type selector
          _buildTypeSelector(),

          const SizedBox(height: AppSpacing.space6),

          // Type-specific options
          if (_selectedType == SubscriptionType.package)
            _buildPackageOptions()
          else if (_selectedType == SubscriptionType.monthly)
            _buildMonthlyOptions()
          else
            _buildTrialOptions(),

          const SizedBox(height: AppSpacing.space6),

          // Amount input
          _buildAmountInput(),

          const SizedBox(height: AppSpacing.space6),

          // Discount section (체험권 제외)
          if (_selectedType != SubscriptionType.trial) ...[
            _buildDiscountSection(),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Bonus section (체험권 제외)
          if (_selectedType != SubscriptionType.trial) ...[
            _buildBonusSection(),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Start date
          _buildStartDatePicker(),

          const SizedBox(height: AppSpacing.space6),

          // Payment status
          _buildPaymentStatusSection(),

          const SizedBox(height: AppSpacing.space6),

          // Summary card
          _buildSummaryCard(),

          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('결제 방식', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            Expanded(
              child: _buildPaymentStatusChip(
                label: '선불',
                icon: Icons.payment,
                isSelected: _isPaymentConfirmed,
                onTap: () => setState(() => _isPaymentConfirmed = true),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: _buildPaymentStatusChip(
                label: '후불',
                icon: Icons.schedule,
                isSelected: !_isPaymentConfirmed,
                onTap: () => setState(() => _isPaymentConfirmed = false),
                accentColor: AppColors.warning,
              ),
            ),
          ],
        ),

        // Payment method selector (only when prepaid)
        if (_isPaymentConfirmed) ...[
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children:
                SubscriptionPaymentMethod.values.map((method) {
                  final isSelected = _selectedPaymentMethod == method;
                  return ChoiceChip(
                    label: Text(method.label),
                    selected: isSelected,
                    onSelected:
                        (_) => setState(() => _selectedPaymentMethod = method),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceLight,
                    side: BorderSide(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.borderLight,
                    ),
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.textSecondaryLight,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
          ),
        ],

        // Info for postpaid
        if (!_isPaymentConfirmed) ...[
          const SizedBox(height: AppSpacing.space3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    '후불 수강권은 미수금으로 표시됩니다. 입금 확인 후 결제완료 처리할 수 있습니다.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentStatusChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final color = accentColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space3,
          horizontal: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? color.withValues(alpha: 0.1)
                  : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? color : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? color : AppColors.textSecondaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipSelector(List<ClassMembership> memberships) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('레슨 선택', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        ...memberships.map((membership) {
          final isSelected = _selectedMembershipId == membership.id;
          final lessonClassAsync = ref.watch(
            lessonClassProvider(membership.lessonClassId),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: GestureDetector(
              onTap:
                  () => setState(() => _selectedMembershipId = membership.id),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: membership.id,
                      groupValue: _selectedMembershipId,
                      onChanged:
                          (value) =>
                              setState(() => _selectedMembershipId = value),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          lessonClassAsync.when(
                            data:
                                (lessonClass) => Text(
                                  lessonClass?.name ?? '개인레슨',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            loading: () => const Text('...'),
                            error: (_, __) => const Text('레슨'),
                          ),
                          Text(
                            membership.instrument,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMembershipInfo(List<ClassMembership> memberships) {
    final membership = memberships.firstWhere(
      (m) => m.id == _selectedMembershipId,
      orElse: () => memberships.first,
    );
    final lessonClassAsync = ref.watch(
      lessonClassProvider(membership.lessonClassId),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          lessonClassAsync.when(
            data: (lessonClass) {
              final isAcademy =
                  lessonClass?.type.toString().contains('academy') ?? false;
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Center(
                  child: Text(
                    isAcademy ? '🏫' : '👤',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            },
            loading:
                () => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                ),
            error:
                (_, __) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                  child: const Icon(Icons.person),
                ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                lessonClassAsync.when(
                  data:
                      (lessonClass) => Text(
                        lessonClass?.name ?? '개인레슨',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  loading: () => const Text('...'),
                  error: (_, __) => const Text('개인레슨'),
                ),
                Text(
                  '${membership.instrument} · ${membership.level ?? '레벨 미설정'}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('수강권 유형', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            _buildTypeChip(SubscriptionType.trial, '체험', Icons.star_outline),
            const SizedBox(width: AppSpacing.space2),
            _buildTypeChip(
              SubscriptionType.package,
              '회차제',
              Icons.confirmation_number_outlined,
            ),
            const SizedBox(width: AppSpacing.space2),
            _buildTypeChip(
              SubscriptionType.monthly,
              '월정액',
              Icons.calendar_month,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        _buildTypeDescription(),
      ],
    );
  }

  Widget _buildTypeDescription() {
    final String description;
    final IconData icon;

    switch (_selectedType) {
      case SubscriptionType.trial:
        description =
            '1회 체험 레슨으로, 학생과 선생님의 적합성을 확인합니다. 무료 또는 할인 금액으로 설정할 수 있습니다.';
        icon = Icons.lightbulb_outline;
      case SubscriptionType.package:
        description = '정해진 횟수만큼 레슨을 진행합니다. 매 레슨마다 유연하게 스케줄을 조율할 수 있습니다.';
        icon = Icons.swap_horiz;
      case SubscriptionType.monthly:
        description = '월 단위 정기 수강권입니다. 고정된 요일·시간에 레슨이 자동 배정되어 스케줄 관리가 편리합니다.';
        icon = Icons.event_repeat;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              description,
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

  Widget _buildTypeChip(SubscriptionType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? AppColors.primary
                        : AppColors.textSecondaryLight,
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color:
                      isSelected
                          ? AppColors.primary
                          : AppColors.textSecondaryLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 회차 선택 (3개 + 입력)
        ChipInputField(
          title: '회차',
          options: const [4, 8, 12],
          currentValue: _totalLessons,
          onChanged: (value) {
            setState(() {
              _totalLessons = value;
              if (value > 0) _setDefaultValidity(value);
            });
          },
          controller: _lessonsController,
          suffix: '회',
        ),

        const SizedBox(height: AppSpacing.space4),

        // 유효기간 선택 (3개 + 입력)
        ChipInputField(
          title: '유효기간',
          options: const [60, 90, 180],
          currentValue: _validityDays,
          onChanged: (value) => setState(() => _validityDays = value),
          controller: _validityController,
          suffix: '일',
        ),
      ],
    );
  }

  void _setDefaultValidity(int lessonCount) {
    int defaultDays;
    if (lessonCount <= 4) {
      defaultDays = 60;
    } else if (lessonCount <= 8) {
      defaultDays = 90;
    } else if (lessonCount <= 12) {
      defaultDays = 120;
    } else {
      defaultDays = 180;
    }
    _validityDays = defaultDays;
    _validityController.text = defaultDays.toString();
  }

  Widget _buildMonthlyOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('기간 선택', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children:
              [1, 3, 6, 12].map((months) {
                final isSelected = _monthsCount == months;
                return ChoiceChip(
                  label: Text('$months개월'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _monthsCount = months),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceLight,
                  side: BorderSide(
                    color:
                        isSelected ? AppColors.primary : AppColors.borderLight,
                  ),
                  labelStyle: AppTypography.bodyMedium.copyWith(
                    color:
                        isSelected
                            ? AppColors.primary
                            : AppColors.textSecondaryLight,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildTrialOptions() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              '체험 레슨은 1회 수강권이 발급됩니다.\n무료 또는 할인된 금액으로 설정할 수 있습니다.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    // Common amount presets
    const presets = [200000, 300000, 400000, 500000];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('정가', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),

        // Amount preset chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                presets.map((amount) {
                  final isSelected = _originalAmount == amount;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.space2),
                    child: ChoiceChip(
                      label: Text('${amount ~/ 10000}만원'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _originalAmount = amount;
                            _amountController.text = NumberFormat(
                              '#,###',
                            ).format(amount);
                          });
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      labelStyle: AppTypography.bodySmall.copyWith(
                        color:
                            isSelected
                                ? AppColors.primary
                                : AppColors.textPrimaryLight,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color:
                            isSelected
                                ? AppColors.primary
                                : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSmall,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ThousandsSeparatorFormatter(),
          ],
          decoration: InputDecoration(
            hintText: '직접 입력',
            suffixText: '원',
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
          onChanged: (value) {
            final cleanValue = value.replaceAll(',', '');
            setState(() {
              _originalAmount = int.tryParse(cleanValue) ?? 0;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '금액을 입력해주세요';
            }
            return null;
          },
        ),
        if (_selectedType == SubscriptionType.package &&
            _originalAmount > 0) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            '회당 ${NumberFormat('#,###').format((_originalAmount / _totalLessons).round())}원',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipInputField(
          title: '할인',
          isOptional: true,
          options: const [0, 5, 10, 20],
          currentValue: _discountPercent,
          onChanged: (value) => setState(() => _discountPercent = value),
          controller: _discountController,
          suffix: '%',
          maxValue: 100,
          selectedColor: AppColors.secondary,
          zeroLabel: '없음',
        ),

        // 할인 적용 시 금액 표시
        if (_discountPercent > 0 && _originalAmount > 0) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            '${NumberFormat('#,###').format(_originalAmount)}원 → ${NumberFormat('#,###').format(_finalAmount)}원 (-${NumberFormat('#,###').format(_originalAmount - _finalAmount)}원)',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBonusSection() {
    // 체험권은 보너스 없음
    if (_selectedType == SubscriptionType.trial) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipInputField(
          title: '보너스',
          isOptional: true,
          options: const [0, 1, 2, 3],
          currentValue: _bonusLessons,
          onChanged: (value) {
            setState(() {
              _bonusLessons = value;
              if (value == 0) _bonusReason = null;
            });
          },
          controller: _bonusController,
          suffix: '회',
          zeroLabel: '없음',
          labelFormatter: (value) => value == 0 ? '없음' : '+$value회',
        ),

        // 보너스 사유 선택 (보너스가 있을 때만)
        if (_bonusLessons > 0) ...[
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              _buildBonusReasonChip('대량 구매'),
              _buildBonusReasonChip('5주차'),
              _buildBonusReasonChip('추천'),
              _buildBonusReasonChip('재등록'),
              _buildBonusReasonChip('기타'),
            ],
          ),
          // 기타 선택 시 직접 입력 필드 표시
          if (_bonusReason == '기타') ...[
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              controller: _customBonusReasonController,
              decoration: InputDecoration(
                hintText: '사유를 직접 입력해주세요',
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _customBonusReason = value;
                });
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildBonusReasonChip(String reason) {
    final isSelected = _bonusReason == reason;
    return ChoiceChip(
      label: Text(reason),
      selected: isSelected,
      onSelected: (_) => setState(() => _bonusReason = reason),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.borderLight,
      ),
      labelStyle: AppTypography.bodySmall.copyWith(
        color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildStartDatePicker() {
    final dateFormat = DateFormat('yyyy년 M월 d일');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('시작일', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _startDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() => _startDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.textSecondaryLight),
                const SizedBox(width: AppSpacing.space3),
                Text(
                  _startDate != null ? dateFormat.format(_startDate!) : '날짜 선택',
                  style: AppTypography.bodyMedium,
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppColors.textTertiaryLight),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final dateFormat = DateFormat('yyyy년 M월 d일');
    DateTime? endDate;

    if (_startDate != null) {
      if (_selectedType == SubscriptionType.monthly) {
        endDate = DateTime(
          _startDate!.year,
          _startDate!.month + _monthsCount,
          _startDate!.day,
        );
      } else if (_selectedType == SubscriptionType.trial) {
        endDate = _startDate!.add(const Duration(days: 7));
      } else if (_selectedType == SubscriptionType.package) {
        endDate = _startDate!.add(Duration(days: _validityDays));
      }
    }

    // 횟수 표시 (보너스 포함)
    String lessonsDisplay;
    if (_selectedType == SubscriptionType.trial) {
      lessonsDisplay = '체험 (1회)';
    } else if (_selectedType == SubscriptionType.package) {
      lessonsDisplay =
          _bonusLessons > 0
              ? '회차제 ($_totalLessons + $_bonusLessons회, $_validityDays일)'
              : '회차제 ($_totalLessons회, $_validityDays일)';
    } else {
      lessonsDisplay = '월정액 ($_monthsCount개월)';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '발급 요약',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          _buildSummaryRow('유형', lessonsDisplay),

          // 금액 (할인 적용 시 정가/할인가 표시)
          if (_discountPercent > 0 && _originalAmount > 0) ...[
            _buildSummaryRow(
              '정가',
              '${NumberFormat('#,###').format(_originalAmount)}원',
              strikethrough: true,
            ),
            _buildSummaryRow(
              '할인',
              '-${NumberFormat('#,###').format(_originalAmount - _finalAmount)}원 ($_discountPercent%)',
              valueColor: AppColors.secondary,
            ),
            _buildSummaryRow(
              '결제금액',
              '${NumberFormat('#,###').format(_finalAmount)}원',
              isBold: true,
            ),
          ] else ...[
            _buildSummaryRow(
              '금액',
              '${NumberFormat('#,###').format(_originalAmount)}원',
            ),
          ],

          // 보너스 횟수
          if (_bonusLessons > 0) ...[
            _buildSummaryRow(
              '보너스',
              '+$_bonusLessons회${_effectiveBonusReason != null ? ' ($_effectiveBonusReason)' : ''}',
              valueColor: AppColors.primary,
            ),
          ],

          // Payment status
          _buildSummaryRow(
            '결제',
            _isPaymentConfirmed
                ? '${_selectedPaymentMethod.label} (확인됨)'
                : '미결제 (후불)',
            valueColor: _isPaymentConfirmed ? null : AppColors.warning,
          ),

          if (_startDate != null)
            _buildSummaryRow('시작일', dateFormat.format(_startDate!)),
          if (endDate != null)
            _buildSummaryRow('만료일', dateFormat.format(endDate)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool strikethrough = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color:
                  valueColor ??
                  (strikethrough ? AppColors.textTertiaryLight : null),
              decoration: strikethrough ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: FilledButton(
          onPressed:
              widget.isBatchMode ? _issueBatchSubscription : _issueSubscription,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(
            widget.isBatchMode
                ? '${widget.studentIds.length}명에게 수강권 발급'
                : '수강권 발급',
          ),
        ),
      ),
    );
  }

  void _issueSubscription() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedMembershipId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('레슨을 선택해주세요')));
      return;
    }
    if (_startDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('시작일을 선택해주세요')));
      return;
    }

    // Validate bonus reason if bonus is set
    if (_bonusLessons > 0 && _effectiveBonusReason == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('보너스 사유를 선택해주세요')));
      return;
    }

    // Calculate end date
    DateTime? endDate;
    int? totalLessons;

    if (_selectedType == SubscriptionType.monthly) {
      endDate = DateTime(
        _startDate!.year,
        _startDate!.month + _monthsCount,
        _startDate!.day,
      );
    } else if (_selectedType == SubscriptionType.trial) {
      totalLessons = 1;
      endDate = _startDate!.add(const Duration(days: 7));
    } else {
      // Package subscription
      totalLessons = _totalLessons;
      endDate = _startDate!.add(Duration(days: _validityDays));
    }

    final now = DateTime.now();
    final subscription = Subscription(
      id: const Uuid().v4(),
      studentId: widget.primaryStudentId,
      membershipId: _selectedMembershipId!,
      type: _selectedType,
      totalLessons: totalLessons,
      usedLessons: 0,
      bonusCount: _bonusLessons,
      bonusReason: _effectiveBonusReason,
      startDate: _startDate,
      endDate: endDate,
      amount: _finalAmount, // 할인 적용된 금액
      status: SubscriptionStatus.active,
      createdAt: now,
      paymentConfirmed: _isPaymentConfirmed,
      paymentMethod: _isPaymentConfirmed ? _selectedPaymentMethod : null,
      paymentConfirmedAt: _isPaymentConfirmed ? now : null,
      originalAmount: _discountPercent > 0 ? _originalAmount : null,
      discountAmount:
          _discountPercent > 0 ? (_originalAmount - _finalAmount) : null,
      discountReason: _discountPercent > 0 ? '$_discountPercent% 할인' : null,
    );

    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      await repository.create(subscription);

      // Transition relationship to active (Issue #59)
      final teacherId = await _getTeacherIdFromMembership(
        subscription.membershipId,
      );
      if (teacherId != null) {
        final relationRepo = ref.read(
          teacherStudentRelationRepositoryProvider,
        );
        await relationRepo.onSubscriptionIssued(
          teacherId: teacherId,
          studentId: widget.primaryStudentId,
          subscriptionId: subscription.id,
        );
      }

      // Create schedule confirmation card for student (Issue #62)
      await _createScheduleConfirmationCard(subscription);

      // Update lesson request status to proposalSent
      if (widget.lessonRequestId != null) {
        await ref
            .read(lessonRequestActionsProvider.notifier)
            .sendProposal(
              requestId: widget.lessonRequestId!,
              proposalId: subscription.id,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('수강권이 발급되었습니다'),
            backgroundColor: AppColors.primary,
          ),
        );

        // Navigate to schedule registration for quick setup (Issue #59)
        if (teacherId != null) {
          final studentName = await _getStudentName();
          if (!mounted) return;
          context.pop();
          context.push(
            AppRoutes.registerRegularLesson,
            extra: {
              'teacherId': teacherId,
              'teacherName': '선생님',
              'studentId': widget.primaryStudentId,
              'studentName': studentName,
            },
          );
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('발급 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Get teacher ID from membership's lesson class.
  Future<String?> _getTeacherIdFromMembership(String membershipId) async {
    final memberships = ref.read(
      studentMembershipsProvider(widget.primaryStudentId),
    );
    final membership = memberships.valueOrNull?.firstWhere(
      (m) => m.id == membershipId,
      orElse: () => throw Exception('Membership not found'),
    );
    if (membership == null) return null;

    final lessonClass = await ref.read(
      lessonClassProvider(membership.lessonClassId).future,
    );
    return lessonClass?.teacherId;
  }

  /// Get student name for schedule registration screen.
  Future<String> _getStudentName() async {
    final student = await ref.read(
      studentProvider(widget.primaryStudentId).future,
    );
    return student?.name ?? '';
  }

  /// Create a schedule confirmation card for the student after subscription issuance.
  Future<void> _createScheduleConfirmationCard(
    Subscription subscription,
  ) async {
    // Get membership info for instrument and lesson class
    final memberships = ref.read(
      studentMembershipsProvider(widget.primaryStudentId),
    );
    final membership = memberships.valueOrNull?.firstWhere(
      (m) => m.id == subscription.membershipId,
      orElse: () => throw Exception('Membership not found'),
    );

    if (membership == null) return;

    // Get lesson class to find teacher info
    final lessonClassAsync = await ref.read(
      lessonClassProvider(membership.lessonClassId).future,
    );

    // Determine card type based on subscription history
    final cardType = await _detectScheduleCardType(subscription, membership);

    // Convert lessonDay string to int (1=Mon, 7=Sun)
    int? parseLessonDay(String? day) {
      if (day == null) return null;
      const dayMap = {
        'Mon': 1,
        'Tue': 2,
        'Wed': 3,
        'Thu': 4,
        'Fri': 5,
        'Sat': 6,
        'Sun': 7,
        '월': 1,
        '화': 2,
        '수': 3,
        '목': 4,
        '금': 5,
        '토': 6,
        '일': 7,
      };
      return dayMap[day];
    }

    // Use membership's existing schedule as suggested time if available
    final suggestedDay = parseLessonDay(membership.lessonDay);
    final suggestedTime = membership.lessonTime;
    final lessonDuration = membership.lessonDuration;

    try {
      await ref
          .read(scheduleConfirmationCardNotifierProvider.notifier)
          .createCard(
            studentId: widget.primaryStudentId,
            teacherId: lessonClassAsync?.teacherId ?? '',
            teacherName:
                lessonClassAsync?.name ?? '선생님', // Use class name as fallback
            instrument: membership.instrument,
            subscriptionId: subscription.id,
            cardType: cardType,
            totalLessons: subscription.totalLessons,
            suggestedDay: suggestedDay,
            suggestedTime: suggestedTime,
            lessonDuration: lessonDuration,
          );
    } catch (e) {
      // Log error but don't fail the subscription issuance
      debugPrint('Failed to create schedule confirmation card: $e');
    }
  }

  /// Detect the schedule card type based on subscription history.
  ///
  /// - afterTrial: First non-trial subscription (after trial lesson)
  /// - reEnrollment: Same membership already had expired subscriptions
  /// - additionalInstrument: Student has subscriptions for other instruments
  Future<ScheduleCardType> _detectScheduleCardType(
    Subscription subscription,
    ClassMembership membership,
  ) async {
    try {
      final allSubscriptions = await ref.read(
        studentSubscriptionsProvider(widget.primaryStudentId).future,
      );

      // Check if same membership had previous subscriptions (exclude current)
      final sameMembershipSubs =
          allSubscriptions
              .where(
                (s) =>
                    s.membershipId == membership.id && s.id != subscription.id,
              )
              .toList();

      if (sameMembershipSubs.isNotEmpty) {
        // Had previous subscriptions for this membership → re-enrollment
        return ScheduleCardType.reEnrollment;
      }

      // Check if student has subscriptions for other memberships
      final otherMembershipSubs =
          allSubscriptions
              .where((s) => s.membershipId != membership.id)
              .toList();

      if (otherMembershipSubs.isNotEmpty) {
        // Has subscriptions for other instruments → additional instrument
        return ScheduleCardType.additionalInstrument;
      }

      // First subscription ever → after trial
      return ScheduleCardType.afterTrial;
    } catch (e) {
      debugPrint('Failed to detect schedule card type: $e');
      return ScheduleCardType.afterTrial;
    }
  }

  Widget _buildNoMembershipState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '등록된 레슨이 없습니다',
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '학생을 레슨에 먼저 등록해주세요.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build form for batch mode (multiple students)
  Widget _buildBatchForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Batch info banner
          _buildBatchInfoBanner(),

          const SizedBox(height: AppSpacing.space6),

          // Subscription type selector
          _buildTypeSelector(),

          const SizedBox(height: AppSpacing.space6),

          // Type-specific options
          if (_selectedType == SubscriptionType.package)
            _buildPackageOptions()
          else if (_selectedType == SubscriptionType.monthly)
            _buildMonthlyOptions()
          else
            _buildTrialOptions(),

          const SizedBox(height: AppSpacing.space6),

          // Amount input
          _buildAmountInput(),

          const SizedBox(height: AppSpacing.space6),

          // Discount section (체험권 제외)
          if (_selectedType != SubscriptionType.trial) ...[
            _buildDiscountSection(),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Bonus section (체험권 제외)
          if (_selectedType != SubscriptionType.trial) ...[
            _buildBonusSection(),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Start date
          _buildStartDatePicker(),

          const SizedBox(height: AppSpacing.space6),

          // Payment status
          _buildPaymentStatusSection(),

          const SizedBox(height: AppSpacing.space6),

          // Batch summary card
          _buildBatchSummaryCard(),

          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildBatchInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.people, color: AppColors.info),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.studentIds.length}명의 학생에게 동일한 수강권을 발급합니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '각 학생에게 개별 수강권이 생성됩니다',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.info.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchSummaryCard() {
    final dateFormat = DateFormat('yyyy년 M월 d일');
    DateTime? endDate;

    if (_startDate != null) {
      if (_selectedType == SubscriptionType.monthly) {
        endDate = DateTime(
          _startDate!.year,
          _startDate!.month + _monthsCount,
          _startDate!.day,
        );
      } else if (_selectedType == SubscriptionType.trial) {
        endDate = _startDate!.add(const Duration(days: 7));
      } else if (_selectedType == SubscriptionType.package) {
        endDate = _startDate!.add(Duration(days: _validityDays));
      }
    }

    // 횟수 표시 (보너스 포함)
    String lessonsDisplay;
    if (_selectedType == SubscriptionType.trial) {
      lessonsDisplay = '체험 (1회)';
    } else if (_selectedType == SubscriptionType.package) {
      lessonsDisplay =
          _bonusLessons > 0
              ? '회차제 ($_totalLessons + $_bonusLessons회, $_validityDays일)'
              : '회차제 ($_totalLessons회, $_validityDays일)';
    } else {
      lessonsDisplay = '월정액 ($_monthsCount개월)';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '배치 발급 요약',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          _buildSummaryRow('발급 대상', '${widget.studentIds.length}명'),
          _buildSummaryRow('유형', lessonsDisplay),

          // 금액 (할인 적용 시 정가/할인가 표시)
          if (_discountPercent > 0 && _originalAmount > 0) ...[
            _buildSummaryRow(
              '정가',
              '${NumberFormat('#,###').format(_originalAmount)}원',
              strikethrough: true,
            ),
            _buildSummaryRow(
              '할인',
              '-${NumberFormat('#,###').format(_originalAmount - _finalAmount)}원 ($_discountPercent%)',
              valueColor: AppColors.secondary,
            ),
            _buildSummaryRow(
              '개인당 금액',
              '${NumberFormat('#,###').format(_finalAmount)}원',
              isBold: true,
            ),
          ] else ...[
            _buildSummaryRow(
              '개인당 금액',
              '${NumberFormat('#,###').format(_originalAmount)}원',
            ),
          ],

          // 총 금액
          _buildSummaryRow(
            '총 예상 금액',
            '${NumberFormat('#,###').format(_finalAmount * widget.studentIds.length)}원',
            isBold: true,
            valueColor: AppColors.primary,
          ),

          // 보너스 횟수
          if (_bonusLessons > 0) ...[
            _buildSummaryRow(
              '보너스',
              '+$_bonusLessons회${_effectiveBonusReason != null ? ' ($_effectiveBonusReason)' : ''}',
              valueColor: AppColors.primary,
            ),
          ],

          if (_startDate != null)
            _buildSummaryRow('시작일', dateFormat.format(_startDate!)),
          if (endDate != null)
            _buildSummaryRow('만료일', dateFormat.format(endDate)),
        ],
      ),
    );
  }

  /// Issue subscriptions to multiple students
  void _issueBatchSubscription() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('시작일을 선택해주세요')));
      return;
    }

    // Validate bonus reason if bonus is set
    if (_bonusLessons > 0 && _effectiveBonusReason == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('보너스 사유를 선택해주세요')));
      return;
    }

    // Calculate end date
    DateTime? endDate;
    int? totalLessons;

    if (_selectedType == SubscriptionType.monthly) {
      endDate = DateTime(
        _startDate!.year,
        _startDate!.month + _monthsCount,
        _startDate!.day,
      );
    } else if (_selectedType == SubscriptionType.trial) {
      totalLessons = 1;
      endDate = _startDate!.add(const Duration(days: 7));
    } else {
      // Package subscription
      totalLessons = _totalLessons;
      endDate = _startDate!.add(Duration(days: _validityDays));
    }

    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      int successCount = 0;
      int failCount = 0;

      // Issue subscription to each student
      final now = DateTime.now();
      for (int i = 0; i < widget.studentIds.length; i++) {
        final studentId = widget.studentIds[i];
        try {
          final subscription = Subscription(
            id: const Uuid().v4(),
            studentId: studentId,
            membershipId: '', // Batch mode doesn't require membership
            type: _selectedType,
            totalLessons: totalLessons,
            usedLessons: 0,
            bonusCount: _bonusLessons,
            bonusReason: _effectiveBonusReason,
            startDate: _startDate,
            endDate: endDate,
            amount: _finalAmount,
            status: SubscriptionStatus.active,
            createdAt: now,
            paymentConfirmed: _isPaymentConfirmed,
            paymentMethod: _isPaymentConfirmed ? _selectedPaymentMethod : null,
            paymentConfirmedAt: _isPaymentConfirmed ? now : null,
            originalAmount: _discountPercent > 0 ? _originalAmount : null,
            discountAmount:
                _discountPercent > 0 ? (_originalAmount - _finalAmount) : null,
            discountReason:
                _discountPercent > 0 ? '$_discountPercent% 할인' : null,
          );
          await repository.create(subscription);

          // Update lesson request status to proposalSent
          if (i < widget.lessonRequestIds.length) {
            await ref
                .read(lessonRequestActionsProvider.notifier)
                .sendProposal(
                  requestId: widget.lessonRequestIds[i],
                  proposalId: subscription.id,
                );
          }

          successCount++;
        } catch (e) {
          failCount++;
          debugPrint('Failed to issue subscription for student $studentId: $e');
        }
      }

      if (mounted) {
        if (failCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount명에게 수강권이 발급되었습니다'),
              backgroundColor: AppColors.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount명 발급 완료, $failCount명 실패'),
              backgroundColor:
                  failCount == widget.studentIds.length
                      ? AppColors.error
                      : AppColors.warning,
            ),
          );
        }
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('발급 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.space3),
            Text('오류가 발생했습니다', style: AppTypography.headingSmall),
            const SizedBox(height: AppSpacing.space2),
            Text(
              error,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Text input formatter for thousands separator.
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final cleanText = newValue.text.replaceAll(',', '');
    final number = int.tryParse(cleanText);

    if (number == null) {
      return oldValue;
    }

    final formatted = NumberFormat('#,###').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
