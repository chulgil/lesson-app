import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/selectors/selectors.dart';
import '../../../relationship/presentation/providers/relationship_providers.dart';
import '../../../schedule/presentation/providers/lesson_request_providers.dart';
import '../../../schedule/presentation/widgets/previous_schedule_card.dart';
import '../../../students/domain/entities/class_membership.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../providers/subscription_providers.dart';

/// Screen for teachers to issue subscriptions to students.
class IssueSubscriptionScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String? membershipId;
  /// Teacher ID for looking up previous schedule on re-enrollment.
  final String? teacherId;
  /// If true, this is an app transition from existing offline lessons.
  /// Shows payment status selector and navigates to schedule setup after issue.
  final bool isAppTransition;
  /// If true, shows previous schedule restoration option.
  /// Set to true when re-enrolling an expired/past student.
  final bool showScheduleRestoration;
  /// Linked lesson request ID (for re-enrollment flow).
  /// When set, the request status will be updated to proposalSent after issue.
  final String? lessonRequestId;

  const IssueSubscriptionScreen({
    super.key,
    required this.studentId,
    this.membershipId,
    this.teacherId,
    this.isAppTransition = false,
    this.showScheduleRestoration = false,
    this.lessonRequestId,
  });

  @override
  ConsumerState<IssueSubscriptionScreen> createState() => _IssueSubscriptionScreenState();
}

class _IssueSubscriptionScreenState extends ConsumerState<IssueSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  SubscriptionType _selectedType = SubscriptionType.package;
  String? _selectedMembershipId;
  int _totalLessons = 4;
  bool _isCustomLessons = false;  // 커스텀 회차 입력 모드
  int _validityDays = 30;   // 회차권 유효기간 (일)
  bool _isCustomValidity = false;  // 커스텀 유효기간 입력 모드
  int _monthsCount = 1;
  int _originalAmount = 0;  // 정가
  int _discountPercent = 0; // 할인율 (0~100)
  bool _isCustomDiscount = false;  // 커스텀 할인율 입력 모드
  int _bonusLessons = 0;    // 보너스 횟수
  bool _isCustomBonus = false;  // 커스텀 보너스 입력 모드
  String? _bonusReason;     // 보너스 사유
  int _rescheduleAllowance = 2;  // 🆕 변경권 횟수 (기본값: 2)
  DateTime? _startDate;

  // 🆕 결제 상태 (앱 전환용)
  ProposalPaymentStatus _paymentStatus = ProposalPaymentStatus.pending;

  // 🆕 이전 스케줄 복원 관련
  PreviousSchedule? _restoredSchedule;
  bool _showScheduleCard = true;

  final _amountController = TextEditingController();
  final _customLessonsController = TextEditingController();
  final _customValidityController = TextEditingController();
  final _customDiscountController = TextEditingController();
  final _customBonusController = TextEditingController();

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
    // 앱 전환 시 기본값: 결제 완료
    if (widget.isAppTransition) {
      _paymentStatus = ProposalPaymentStatus.completed;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customLessonsController.dispose();
    _customValidityController.dispose();
    _customDiscountController.dispose();
    _customBonusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membershipsAsync = ref.watch(studentMembershipsProvider(widget.studentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAppTransition ? '수강권 등록' : '수강권 발급'),
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

          // 🆕 Previous schedule restoration card (for re-enrollment)
          if (widget.showScheduleRestoration &&
              widget.teacherId != null &&
              _showScheduleCard) ...[
            const SizedBox(height: AppSpacing.space4),
            _buildPreviousScheduleSection(),
          ],

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

          // 🆕 Payment status section (앱 전환 시 또는 명시적 표시)
          if (widget.isAppTransition || _selectedType != SubscriptionType.trial) ...[
            _buildPaymentStatusSection(),
            const SizedBox(height: AppSpacing.space6),
          ],

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

          // 🆕 Reschedule allowance section (체험권 제외)
          if (_selectedType != SubscriptionType.trial) ...[
            _buildRescheduleAllowanceSection(),
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

  /// 🆕 이전 스케줄 복원 섹션
  Widget _buildPreviousScheduleSection() {
    if (widget.teacherId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 복원된 스케줄이 있는 경우 표시
        if (_restoredSchedule != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 24),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이전 스케줄 복원됨',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatSchedule(_restoredSchedule!),
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _restoredSchedule = null;
                      _showScheduleCard = true;
                    });
                  },
                  child: const Text('취소'),
                ),
              ],
            ),
          ),
        ] else ...[
          // 이전 스케줄 카드 표시
          PreviousScheduleCard(
            teacherId: widget.teacherId!,
            studentId: widget.studentId,
            onRestore: (schedule) {
              setState(() {
                _restoredSchedule = schedule;
                _showScheduleCard = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('이전 스케줄(${_formatSchedule(schedule)})이 복원됩니다.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            onDismiss: () {
              setState(() => _showScheduleCard = false);
            },
          ),
        ],
      ],
    );
  }

  String _formatSchedule(PreviousSchedule schedule) {
    return LessonDateUtils.formatScheduleDisplay(
      weekday: schedule.lessonDay,
      time: schedule.lessonTime,
      includeWeekly: true,
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
    // 회차 프리셋: 4, 12, 24, 48
    const lessonPresets = [4, 12, 24, 48];
    // 유효기간 프리셋: 1개월(30), 3개월(90), 6개월(180), 1년(365)
    const validityPresets = [
      (days: 30, label: '1개월'),
      (days: 90, label: '3개월'),
      (days: 180, label: '6개월'),
      (days: 365, label: '1년'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 회차 선택
        Text('회차 선택', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            // 프리셋 칩들
            ...lessonPresets.map((count) {
              final isSelected = !_isCustomLessons && _totalLessons == count;
              return ChoiceChip(
                label: Text('$count회'),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _totalLessons = count;
                  _isCustomLessons = false;
                  _customLessonsController.clear();
                  // 회차에 따른 기본 유효기간 자동 설정
                  _autoSetValidityByLessons(count);
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
            }),
            // 직접 입력 칩
            ChoiceChip(
              label: const Text('직접 입력'),
              selected: _isCustomLessons,
              onSelected: (_) => setState(() {
                _isCustomLessons = true;
              }),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide(
                color: _isCustomLessons ? AppColors.primary : AppColors.borderLight,
              ),
              labelStyle: AppTypography.bodyMedium.copyWith(
                color: _isCustomLessons ? AppColors.primary : AppColors.textSecondaryLight,
                fontWeight: _isCustomLessons ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),

        // 커스텀 회차 입력 필드
        if (_isCustomLessons) ...[
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customLessonsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '회차 입력',
                    suffixText: '회',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space3,
                      vertical: AppSpacing.space3,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onChanged: (value) {
                    final count = int.tryParse(value) ?? 0;
                    if (count > 0) {
                      setState(() {
                        _totalLessons = count;
                        _autoSetValidityByLessons(count);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.space5),

        // 유효기간 선택
        Text('유효기간', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            // 프리셋 칩들
            ...validityPresets.map((preset) {
              final isSelected = !_isCustomValidity && _validityDays == preset.days;
              return ChoiceChip(
                label: Text(preset.label),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _validityDays = preset.days;
                  _isCustomValidity = false;
                  _customValidityController.clear();
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
            }),
            // 직접 입력 칩
            ChoiceChip(
              label: const Text('직접 입력'),
              selected: _isCustomValidity,
              onSelected: (_) => setState(() {
                _isCustomValidity = true;
              }),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide(
                color: _isCustomValidity ? AppColors.primary : AppColors.borderLight,
              ),
              labelStyle: AppTypography.bodyMedium.copyWith(
                color: _isCustomValidity ? AppColors.primary : AppColors.textSecondaryLight,
                fontWeight: _isCustomValidity ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),

        // 커스텀 유효기간 입력 필드
        if (_isCustomValidity) ...[
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customValidityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '유효기간 입력',
                    suffixText: '일',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space3,
                      vertical: AppSpacing.space3,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onChanged: (value) {
                    final days = int.tryParse(value) ?? 0;
                    if (days > 0) {
                      setState(() {
                        _validityDays = days;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],

        // 유효기간 안내
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  '유효기간 내 자유롭게 사용 가능합니다.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 회차에 따른 기본 유효기간 자동 설정
  void _autoSetValidityByLessons(int count) {
    if (_isCustomValidity) return;  // 커스텀 입력 중이면 자동 설정 안함

    if (count <= 4) {
      _validityDays = 30;  // 1개월
    } else if (count <= 12) {
      _validityDays = 90;  // 3개월
    } else if (count <= 24) {
      _validityDays = 180; // 6개월
    } else {
      _validityDays = 365; // 1년
    }
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

  /// 🆕 결제 상태 선택 섹션 (앱 전환용)
  Widget _buildPaymentStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('결제 상태', style: AppTypography.headingSmall),
            const SizedBox(width: AppSpacing.space2),
            if (widget.isAppTransition)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '앱 전환',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // 결제 대기 옵션
        _buildPaymentStatusOption(
          status: ProposalPaymentStatus.pending,
          icon: Icons.hourglass_empty,
        ),

        const SizedBox(height: AppSpacing.space2),

        // 결제 완료 옵션
        _buildPaymentStatusOption(
          status: ProposalPaymentStatus.completed,
          icon: Icons.check_circle_outline,
        ),

        // 안내 메시지
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: _paymentStatus == ProposalPaymentStatus.completed
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                _paymentStatus == ProposalPaymentStatus.completed
                    ? Icons.flash_on
                    : Icons.info_outline,
                size: 18,
                color: _paymentStatus == ProposalPaymentStatus.completed
                    ? AppColors.success
                    : AppColors.info,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  _paymentStatus == ProposalPaymentStatus.completed
                      ? '이미 결제가 완료된 경우 선택하세요.\n입금 확인 단계 없이 즉시 발급됩니다.'
                      : '학생이 결제 후 입금 완료 알림을 보내면\n선생님이 확인 후 수강권이 발급됩니다.',
                  style: AppTypography.caption.copyWith(
                    color: _paymentStatus == ProposalPaymentStatus.completed
                        ? AppColors.success
                        : AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusOption({
    required ProposalPaymentStatus status,
    required IconData icon,
  }) {
    final isSelected = _paymentStatus == status;
    final color = status == ProposalPaymentStatus.completed
        ? AppColors.success
        : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: () => setState(() => _paymentStatus = status),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: isSelected
              ? (status == ProposalPaymentStatus.completed
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1))
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected
                ? (status == ProposalPaymentStatus.completed
                    ? AppColors.success
                    : AppColors.primary)
                : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<ProposalPaymentStatus>(
              value: status,
              groupValue: _paymentStatus,
              onChanged: (value) {
                if (value != null) setState(() => _paymentStatus = value);
              },
              activeColor: status == ProposalPaymentStatus.completed
                  ? AppColors.success
                  : AppColors.primary,
            ),
            Icon(
              icon,
              color: isSelected ? color : AppColors.textTertiaryLight,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? color : null,
                    ),
                  ),
                  Text(
                    status.description,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected && status == ProposalPaymentStatus.completed)
              Icon(
                Icons.check,
                color: AppColors.success,
                size: 20,
              ),
          ],
        ),
      ),
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

        // 할인율 선택 (공통 위젯 사용)
        DiscountPercentSelector(
          selectedPercent: _discountPercent,
          isCustom: _isCustomDiscount,
          customController: _customDiscountController,
          onPercentChanged: (percent, isCustom) {
            setState(() {
              _discountPercent = percent;
              _isCustomDiscount = isCustom;
            });
          },
          label: '할인율',
          accentColor: AppColors.secondary,
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

        // 보너스 횟수 선택 (공통 위젯 사용)
        BonusCountSelector(
          selectedCount: _bonusLessons,
          isCustom: _isCustomBonus,
          customController: _customBonusController,
          onCountChanged: (count, isCustom) {
            setState(() {
              _bonusLessons = count;
              _isCustomBonus = isCustom;
              if (count == 0) _bonusReason = null;
            });
          },
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

  /// 🆕 변경권 설정 섹션
  Widget _buildRescheduleAllowanceSection() {
    // 체험권은 변경권 없음
    if (_selectedType == SubscriptionType.trial) return const SizedBox.shrink();

    const allowancePresets = [0, 1, 2, 3, 5];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('변경권', style: AppTypography.headingSmall),
            const SizedBox(width: AppSpacing.space2),
            Tooltip(
              message: '학생이 레슨 일정을 변경할 수 있는 횟수입니다.\n0회면 학생이 직접 변경할 수 없습니다.',
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // 변경권 횟수 선택
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: allowancePresets.map((count) {
            final isSelected = _rescheduleAllowance == count;
            return ChoiceChip(
              label: Text(count == 0 ? '변경불가' : '$count회'),
              selected: isSelected,
              onSelected: (_) => setState(() => _rescheduleAllowance = count),
              selectedColor: count == 0
                  ? AppColors.error.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: count == 0 ? AppColors.error : AppColors.primary,
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide(
                color: isSelected
                    ? (count == 0 ? AppColors.error : AppColors.primary)
                    : AppColors.borderLight,
              ),
              labelStyle: AppTypography.bodyMedium.copyWith(
                color: isSelected
                    ? (count == 0 ? AppColors.error : AppColors.primary)
                    : AppColors.textSecondaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),

        // 안내 메시지
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: _rescheduleAllowance == 0
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                _rescheduleAllowance == 0
                    ? Icons.block
                    : Icons.swap_horiz,
                size: 18,
                color: _rescheduleAllowance == 0
                    ? AppColors.error
                    : AppColors.info,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  _rescheduleAllowance == 0
                      ? '학생이 직접 레슨 일정을 변경할 수 없습니다.\n선생님에게 요청해야 합니다.'
                      : '학생이 $_rescheduleAllowance회까지 레슨 일정을 변경할 수 있습니다.\n선생님이 변경하는 경우 차감되지 않습니다.',
                  style: AppTypography.caption.copyWith(
                    color: _rescheduleAllowance == 0
                        ? AppColors.error
                        : AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
      } else if (_selectedType == SubscriptionType.package) {
        endDate = _startDate!.add(Duration(days: _validityDays));
      }
    }

    // 횟수 표시 (보너스 포함)
    String lessonsDisplay;
    if (_selectedType == SubscriptionType.trial) {
      lessonsDisplay = '체험 (1회)';
    } else if (_selectedType == SubscriptionType.package) {
      lessonsDisplay = _bonusLessons > 0
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
    final buttonText = widget.isAppTransition
        ? (_paymentStatus == ProposalPaymentStatus.completed
            ? '수강권 등록'
            : '수강권 제안')
        : (_paymentStatus == ProposalPaymentStatus.completed
            ? '수강권 발급'
            : '수강권 제안');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: FilledButton(
          onPressed: _issueSubscription,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(buttonText),
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
      // Package subscription
      totalLessons = _totalLessons;
      endDate = _startDate!.add(Duration(days: _validityDays));
    }

    // 🆕 결제 완료 선택 시 즉시 active, 결제 대기 시 결제 흐름 필요
    final isImmediateIssue = _paymentStatus == ProposalPaymentStatus.completed;

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
      status: isImmediateIssue ? SubscriptionStatus.active : SubscriptionStatus.active,
      createdAt: DateTime.now(),
      // 🆕 변경권 설정 (체험권은 기본값 0)
      totalRescheduleAllowance: _selectedType == SubscriptionType.trial
          ? 0
          : _rescheduleAllowance,
      usedRescheduleCount: 0,
    );

    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      await repository.create(subscription);

      // 🆕 이전 스케줄 복원이 선택된 경우, 스케줄 기록
      if (_restoredSchedule != null && widget.teacherId != null) {
        try {
          await ref.read(scheduleRecorderProvider.notifier).recordSchedule(
                teacherId: widget.teacherId!,
                studentId: widget.studentId,
                lessonDay: _restoredSchedule!.lessonDay,
                lessonTime: _restoredSchedule!.lessonTime,
                lessonDuration: _restoredSchedule!.lessonDuration,
              );
        } catch (e) {
          // Schedule recording failure is non-critical, log but don't block
          debugPrint('Failed to record restored schedule: $e');
        }
      }

      // 🆕 레슨 요청이 연결된 경우, 상태를 proposalSent로 업데이트
      if (widget.lessonRequestId != null) {
        try {
          await ref.read(lessonRequestActionsProvider.notifier).sendProposal(
                requestId: widget.lessonRequestId!,
                proposalId: subscription.id, // 수강권 ID를 제안 ID로 사용
              );
        } catch (e) {
          // Lesson request update failure is non-critical
          debugPrint('Failed to update lesson request status: $e');
        }
      }

      if (mounted) {
        // 🆕 앱 전환 + 즉시 발급 시 스케줄 설정 화면으로 이동
        if (widget.isAppTransition && isImmediateIssue) {
          final message = _restoredSchedule != null
              ? '수강권이 발급되었습니다. 이전 스케줄(${_formatSchedule(_restoredSchedule!)})이 복원됩니다.'
              : '수강권이 발급되었습니다. 정기 스케줄을 설정해주세요.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.primary,
            ),
          );
          // TODO: 스케줄 설정 화면으로 이동
          // context.pushReplacement('/schedule/setup/${widget.studentId}');
          context.pop(true);  // true = 수강권 발급 완료
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isImmediateIssue
                    ? '수강권이 발급되었습니다'
                    : '수강권 제안이 발송되었습니다. 학생의 결제를 기다려주세요.',
              ),
              backgroundColor: AppColors.primary,
            ),
          );
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
