import 'package:flutter/material.dart';
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
import '../widgets/issue_form_sections.dart';
import '../widgets/issue_form_membership_widgets.dart';
import '../widgets/issue_form_summary_widgets.dart';

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
  int _validityDays = 90;
  int _monthsCount = 1;
  int _originalAmount = 0;
  int _discountPercent = 0;
  int _bonusLessons = 0;
  String? _bonusReason;
  String _customBonusReason = '';
  DateTime? _startDate;

  final _amountController = TextEditingController();
  final _lessonsController = TextEditingController();
  final _validityController = TextEditingController();
  final _discountController = TextEditingController();
  final _bonusController = TextEditingController();
  final _customBonusReasonController = TextEditingController();

  String? get _effectiveBonusReason {
    if (_bonusLessons == 0) return null;
    if (_bonusReason == '기타') {
      return _customBonusReason.isNotEmpty ? _customBonusReason : null;
    }
    return _bonusReason;
  }

  int get _finalAmount {
    if (_discountPercent <= 0) return _originalAmount;
    return (_originalAmount * (100 - _discountPercent) / 100).round();
  }

  @override
  void initState() {
    super.initState();
    _selectedMembershipId = widget.membershipId;
    _startDate = DateTime.now();
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
                    return const NoMembershipState();
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
                error:
                    (error, _) => SubscriptionErrorState(
                      error: error.toString(),
                    ),
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
            MembershipSelectorWidget(
              memberships: memberships,
              selectedMembershipId: _selectedMembershipId,
              onChanged:
                  (value) => setState(() => _selectedMembershipId = value),
            ),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Selected membership info
          if (_selectedMembershipId != null)
            MembershipInfoCard(
              memberships: memberships,
              selectedMembershipId: _selectedMembershipId,
            ),

          const SizedBox(height: AppSpacing.space6),

          // Subscription type selector
          SubscriptionTypeSelector(
            selectedType: _selectedType,
            onChanged: (type) => setState(() => _selectedType = type),
          ),

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
          AmountInputSection(
            originalAmount: _originalAmount,
            controller: _amountController,
            selectedType: _selectedType,
            totalLessons: _totalLessons,
            finalAmount: _finalAmount,
            discountPercent: _discountPercent,
            onAmountChanged:
                (value) => setState(() => _originalAmount = value),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Discount section
          if (_selectedType != SubscriptionType.trial) ...[
            _buildDiscountSection(),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Bonus section
          if (_selectedType != SubscriptionType.trial) ...[
            _buildBonusSection(),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Start date
          StartDatePickerField(
            startDate: _startDate,
            onChanged: (date) => setState(() => _startDate = date),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Payment status
          PaymentStatusSection(
            isPaymentConfirmed: _isPaymentConfirmed,
            selectedPaymentMethod: _selectedPaymentMethod,
            onPaymentConfirmedChanged:
                (value) => setState(() => _isPaymentConfirmed = value),
            onPaymentMethodChanged:
                (method) => setState(() => _selectedPaymentMethod = method),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Summary card
          SubscriptionSummaryCard(
            selectedType: _selectedType,
            totalLessons: _totalLessons,
            monthsCount: _monthsCount,
            validityDays: _validityDays,
            originalAmount: _originalAmount,
            finalAmount: _finalAmount,
            discountPercent: _discountPercent,
            bonusLessons: _bonusLessons,
            effectiveBonusReason: _effectiveBonusReason,
            isPaymentConfirmed: _isPaymentConfirmed,
            selectedPaymentMethod: _selectedPaymentMethod,
            startDate: _startDate,
          ),

          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildBatchForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          BatchInfoBanner(studentCount: widget.studentIds.length),

          const SizedBox(height: AppSpacing.space6),

          SubscriptionTypeSelector(
            selectedType: _selectedType,
            onChanged: (type) => setState(() => _selectedType = type),
          ),

          const SizedBox(height: AppSpacing.space6),

          if (_selectedType == SubscriptionType.package)
            _buildPackageOptions()
          else if (_selectedType == SubscriptionType.monthly)
            _buildMonthlyOptions()
          else
            _buildTrialOptions(),

          const SizedBox(height: AppSpacing.space6),

          AmountInputSection(
            originalAmount: _originalAmount,
            controller: _amountController,
            selectedType: _selectedType,
            totalLessons: _totalLessons,
            finalAmount: _finalAmount,
            discountPercent: _discountPercent,
            onAmountChanged:
                (value) => setState(() => _originalAmount = value),
          ),

          const SizedBox(height: AppSpacing.space6),

          if (_selectedType != SubscriptionType.trial) ...[
            _buildDiscountSection(),
            const SizedBox(height: AppSpacing.space6),
          ],

          if (_selectedType != SubscriptionType.trial) ...[
            _buildBonusSection(),
            const SizedBox(height: AppSpacing.space6),
          ],

          StartDatePickerField(
            startDate: _startDate,
            onChanged: (date) => setState(() => _startDate = date),
          ),

          const SizedBox(height: AppSpacing.space6),

          PaymentStatusSection(
            isPaymentConfirmed: _isPaymentConfirmed,
            selectedPaymentMethod: _selectedPaymentMethod,
            onPaymentConfirmedChanged:
                (value) => setState(() => _isPaymentConfirmed = value),
            onPaymentMethodChanged:
                (method) => setState(() => _selectedPaymentMethod = method),
          ),

          const SizedBox(height: AppSpacing.space6),

          BatchSummaryCard(
            studentCount: widget.studentIds.length,
            selectedType: _selectedType,
            totalLessons: _totalLessons,
            monthsCount: _monthsCount,
            validityDays: _validityDays,
            originalAmount: _originalAmount,
            finalAmount: _finalAmount,
            discountPercent: _discountPercent,
            bonusLessons: _bonusLessons,
            effectiveBonusReason: _effectiveBonusReason,
            startDate: _startDate,
          ),

          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildPackageOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

    if (_bonusLessons > 0 && _effectiveBonusReason == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('보너스 사유를 선택해주세요')));
      return;
    }

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
      amount: _finalAmount,
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

  Future<String> _getStudentName() async {
    final student = await ref.read(
      studentProvider(widget.primaryStudentId).future,
    );
    return student?.name ?? '';
  }

  Future<void> _createScheduleConfirmationCard(
    Subscription subscription,
  ) async {
    final memberships = ref.read(
      studentMembershipsProvider(widget.primaryStudentId),
    );
    final membership = memberships.valueOrNull?.firstWhere(
      (m) => m.id == subscription.membershipId,
      orElse: () => throw Exception('Membership not found'),
    );

    if (membership == null) return;

    final lessonClassAsync = await ref.read(
      lessonClassProvider(membership.lessonClassId).future,
    );

    final cardType = await _detectScheduleCardType(subscription, membership);

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

    final suggestedDay = parseLessonDay(membership.lessonDay);
    final suggestedTime = membership.lessonTime;
    final lessonDuration = membership.lessonDuration;

    try {
      await ref
          .read(scheduleConfirmationCardNotifierProvider.notifier)
          .createCard(
            studentId: widget.primaryStudentId,
            teacherId: lessonClassAsync?.teacherId ?? '',
            teacherName: lessonClassAsync?.name ?? '선생님',
            instrument: membership.instrument,
            subscriptionId: subscription.id,
            cardType: cardType,
            totalLessons: subscription.totalLessons,
            suggestedDay: suggestedDay,
            suggestedTime: suggestedTime,
            lessonDuration: lessonDuration,
          );
    } catch (e) {
      debugPrint('Failed to create schedule confirmation card: $e');
    }
  }

  Future<ScheduleCardType> _detectScheduleCardType(
    Subscription subscription,
    ClassMembership membership,
  ) async {
    try {
      final allSubscriptions = await ref.read(
        studentSubscriptionsProvider(widget.primaryStudentId).future,
      );

      final sameMembershipSubs =
          allSubscriptions
              .where(
                (s) =>
                    s.membershipId == membership.id && s.id != subscription.id,
              )
              .toList();

      if (sameMembershipSubs.isNotEmpty) {
        return ScheduleCardType.reEnrollment;
      }

      final otherMembershipSubs =
          allSubscriptions
              .where((s) => s.membershipId != membership.id)
              .toList();

      if (otherMembershipSubs.isNotEmpty) {
        return ScheduleCardType.additionalInstrument;
      }

      return ScheduleCardType.afterTrial;
    } catch (e) {
      debugPrint('Failed to detect schedule card type: $e');
      return ScheduleCardType.afterTrial;
    }
  }

  void _issueBatchSubscription() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('시작일을 선택해주세요')));
      return;
    }

    if (_bonusLessons > 0 && _effectiveBonusReason == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('보너스 사유를 선택해주세요')));
      return;
    }

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
      totalLessons = _totalLessons;
      endDate = _startDate!.add(Duration(days: _validityDays));
    }

    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      int successCount = 0;
      int failCount = 0;

      final now = DateTime.now();
      for (int i = 0; i < widget.studentIds.length; i++) {
        final studentId = widget.studentIds[i];
        try {
          final subscription = Subscription(
            id: const Uuid().v4(),
            studentId: studentId,
            membershipId: '',
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
}
