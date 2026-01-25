import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../students/domain/entities/class_membership.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';

/// Screen for teachers to issue subscriptions to students.
class IssueSubscriptionScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String? membershipId;

  const IssueSubscriptionScreen({
    super.key,
    required this.studentId,
    this.membershipId,
  });

  @override
  ConsumerState<IssueSubscriptionScreen> createState() => _IssueSubscriptionScreenState();
}

class _IssueSubscriptionScreenState extends ConsumerState<IssueSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  SubscriptionType _selectedType = SubscriptionType.package;
  String? _selectedMembershipId;
  int _totalLessons = 8;
  int _monthsCount = 1;
  int _originalAmount = 0;  // 정가
  int _discountPercent = 0; // 할인율 (0~100)
  int _bonusLessons = 0;    // 보너스 횟수
  String? _bonusReason;     // 보너스 사유
  DateTime? _startDate;

  final _amountController = TextEditingController();

  /// 할인 적용된 최종 금액
  int get _finalAmount {
    if (_discountPercent <= 0) return _originalAmount;
    return (_originalAmount * (100 - _discountPercent) / 100).round();
  }

  /// 총 횟수 (기본 + 보너스)
  int get _totalLessonsWithBonus => _totalLessons + _bonusLessons;

  @override
  void initState() {
    super.initState();
    _selectedMembershipId = widget.membershipId;
    _startDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membershipsAsync = ref.watch(studentMembershipsProvider(widget.studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('수강권 발급'),
        centerTitle: true,
      ),
      body: membershipsAsync.when(
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
          if (_selectedMembershipId != null)
            _buildMembershipInfo(memberships),

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

          // Summary card
          _buildSummaryCard(),

          const SizedBox(height: AppSpacing.space8),
        ],
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
          final lessonClassAsync = ref.watch(lessonClassProvider(membership.lessonClassId));

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: GestureDetector(
              onTap: () => setState(() => _selectedMembershipId = membership.id),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: membership.id,
                      groupValue: _selectedMembershipId,
                      onChanged: (value) => setState(() => _selectedMembershipId = value),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          lessonClassAsync.when(
                            data: (lessonClass) => Text(
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
    final lessonClassAsync = ref.watch(lessonClassProvider(membership.lessonClassId));

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
              final isAcademy = lessonClass?.type.toString().contains('academy') ?? false;
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
            loading: () => Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
            error: (_, __) => Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
                  data: (lessonClass) => Text(
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
            _buildTypeChip(SubscriptionType.package, '회차제', Icons.confirmation_number_outlined),
            const SizedBox(width: AppSpacing.space2),
            _buildTypeChip(SubscriptionType.monthly, '월정액', Icons.calendar_month),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(SubscriptionType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space3,
          ),
          decoration: BoxDecoration(
            color: isSelected
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
                color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
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
        Text('회차 선택', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [4, 8, 12, 16, 20, 24].map((count) {
            final isSelected = _totalLessons == count;
            return ChoiceChip(
              label: Text('$count회'),
              selected: isSelected,
              onSelected: (_) => setState(() => _totalLessons = count),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
              ),
              labelStyle: AppTypography.bodyMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
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
          children: [1, 3, 6, 12].map((months) {
            final isSelected = _monthsCount == months;
            return ChoiceChip(
              label: Text('$months개월'),
              selected: isSelected,
              onSelected: (_) => setState(() => _monthsCount = months),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
              ),
              labelStyle: AppTypography.bodyMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('정가', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ThousandsSeparatorFormatter(),
          ],
          decoration: InputDecoration(
            hintText: '금액 입력',
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
        if (_selectedType == SubscriptionType.package && _originalAmount > 0) ...[
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
        Row(
          children: [
            Text('할인 혜택', style: AppTypography.headingSmall),
            const SizedBox(width: AppSpacing.space2),
            Text(
              '(선택)',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // 할인율 선택
        Text(
          '할인율',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [0, 5, 10, 15, 20].map((percent) {
            final isSelected = _discountPercent == percent;
            return ChoiceChip(
              label: Text(percent == 0 ? '없음' : '$percent%'),
              selected: isSelected,
              onSelected: (_) => setState(() => _discountPercent = percent),
              selectedColor: AppColors.secondary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.secondary,
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide(
                color: isSelected ? AppColors.secondary : AppColors.borderLight,
              ),
              labelStyle: AppTypography.bodyMedium.copyWith(
                color: isSelected ? AppColors.secondary : AppColors.textSecondaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),

        // 할인 적용 시 금액 표시
        if (_discountPercent > 0 && _originalAmount > 0) ...[
          const SizedBox(height: AppSpacing.space3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.local_offer, size: 18, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '${NumberFormat('#,###').format(_originalAmount - _finalAmount)}원 할인',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${NumberFormat('#,###').format(_finalAmount)}원',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
        Row(
          children: [
            Text('보너스 횟수', style: AppTypography.headingSmall),
            const SizedBox(width: AppSpacing.space2),
            Text(
              '(선택)',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // 보너스 횟수 선택
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [0, 1, 2, 3].map((count) {
            final isSelected = _bonusLessons == count;
            return ChoiceChip(
              label: Text(count == 0 ? '없음' : '+$count회'),
              selected: isSelected,
              onSelected: (_) => setState(() {
                _bonusLessons = count;
                if (count == 0) _bonusReason = null;
              }),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
              ),
              labelStyle: AppTypography.bodyMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),

        // 보너스 사유 선택 (보너스가 있을 때만)
        if (_bonusLessons > 0) ...[
          const SizedBox(height: AppSpacing.space4),
          Text(
            '보너스 사유',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              _buildBonusReasonChip('대량 구매'),
              _buildBonusReasonChip('5주차 보너스'),
              _buildBonusReasonChip('추천 이벤트'),
              _buildBonusReasonChip('재등록 혜택'),
              _buildBonusReasonChip('기타'),
            ],
          ),

          // 보너스 정보 박스
          const SizedBox(height: AppSpacing.space3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.card_giftcard, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '보너스 +$_bonusLessons회',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_bonusReason != null) ...[
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '($_bonusReason)',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '총 $_totalLessonsWithBonus회',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
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
                  _startDate != null
                      ? dateFormat.format(_startDate!)
                      : '날짜 선택',
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
        endDate = DateTime(_startDate!.year, _startDate!.month + _monthsCount, _startDate!.day);
      } else if (_selectedType == SubscriptionType.trial) {
        endDate = _startDate!.add(const Duration(days: 7));
      }
    }

    // 횟수 표시 (보너스 포함)
    String lessonsDisplay;
    if (_selectedType == SubscriptionType.trial) {
      lessonsDisplay = '체험 (1회)';
    } else if (_selectedType == SubscriptionType.package) {
      lessonsDisplay = _bonusLessons > 0
          ? '회차제 ($_totalLessons + $_bonusLessons회)'
          : '회차제 ($_totalLessons회)';
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
              '+$_bonusLessons회${_bonusReason != null ? ' ($_bonusReason)' : ''}',
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
              color: valueColor ?? (strikethrough ? AppColors.textTertiaryLight : null),
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
          onPressed: _issueSubscription,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('수강권 발급'),
        ),
      ),
    );
  }

  void _issueSubscription() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedMembershipId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('레슨을 선택해주세요')),
      );
      return;
    }
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시작일을 선택해주세요')),
      );
      return;
    }

    // Validate bonus reason if bonus is set
    if (_bonusLessons > 0 && _bonusReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보너스 사유를 선택해주세요')),
      );
      return;
    }

    // Calculate end date
    DateTime? endDate;
    int? totalLessons;

    if (_selectedType == SubscriptionType.monthly) {
      endDate = DateTime(_startDate!.year, _startDate!.month + _monthsCount, _startDate!.day);
    } else if (_selectedType == SubscriptionType.trial) {
      totalLessons = 1;
      endDate = _startDate!.add(const Duration(days: 7));
    } else {
      totalLessons = _totalLessons;
    }

    final subscription = Subscription(
      id: const Uuid().v4(),
      studentId: widget.studentId,
      membershipId: _selectedMembershipId!,
      type: _selectedType,
      totalLessons: totalLessons,
      usedLessons: 0,
      bonusCount: _bonusLessons,
      bonusReason: _bonusReason,
      startDate: _startDate,
      endDate: endDate,
      amount: _finalAmount,  // 할인 적용된 금액
      status: SubscriptionStatus.active,
      createdAt: DateTime.now(),
    );

    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      await repository.create(subscription);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('수강권이 발급되었습니다'),
            backgroundColor: AppColors.primary,
          ),
        );
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              '오류가 발생했습니다',
              style: AppTypography.headingSmall,
            ),
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
