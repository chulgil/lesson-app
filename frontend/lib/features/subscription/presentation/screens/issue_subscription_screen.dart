import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../students/domain/entities/class_membership.dart';
import '../../../students/domain/entities/lesson_location.dart';
import '../../domain/entities/lesson_policy.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_template.dart';
import '../../../schedule/schedule_facade.dart';
import '../extensions/lesson_policy_visuals.dart';
import '../providers/subscription_issue_flow_provider.dart';
import '../providers/subscription_template_providers.dart';
import '../widgets/issue_form_discount_bonus.dart';
import '../widgets/issue_form_membership_widgets.dart';
import '../widgets/issue_form_sections.dart';
import '../widgets/issue_form_summary_widgets.dart';
import '../widgets/issue_form_type_options.dart';
import '../widgets/location_travel_selector.dart';
import 'issue_subscription_actions.dart';

/// Screen for teachers to issue subscriptions to students.
/// Supports both single student and batch issuance (multiple students).
class IssueSubscriptionScreen extends ConsumerStatefulWidget {
  /// List of student IDs to issue subscriptions to.
  /// For single student, this will contain one ID.
  /// For batch issuance, this will contain multiple IDs.
  final List<String> studentIds;
  final String? membershipId;
  final String? templateId;
  final String? lessonRequestId;
  final List<String> lessonRequestIds;

  const IssueSubscriptionScreen({
    super.key,
    required this.studentIds,
    this.membershipId,
    this.templateId,
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
    extends ConsumerState<IssueSubscriptionScreen>
    with IssueSubscriptionActions {
  final _formKey = GlobalKey<FormState>();

  SubscriptionType _selectedType = SubscriptionType.package;
  String? _selectedMembershipId;
  bool _isPaymentConfirmed = true;
  SubscriptionPaymentMethod _selectedPaymentMethod =
      SubscriptionPaymentMethod.bankTransfer;
  int _totalLessons = 8;
  int _validityDays = 90;
  int _monthsCount = 1;
  int _lessonsPerMonth = 4;
  int _originalAmount = 0;
  bool _hasPrefilledAmount = false;
  int _discountPercent = 0;
  int _bonusLessons = 0;
  String? _bonusReason;
  String _customBonusReason = '';
  DateTime? _startDate;
  int _rescheduleAllowance = 2;
  int _rescheduleDeadlineHours = 12;
  String? _selectedLocationId;
  int _travelTimeMinutes = 0;
  String? _appliedTemplateId;

  // 선생님 정책 기본값 연동.
  // 수강권 생성 시 정책값을 기본으로 표기하되, 실제 컨트롤은 수강권 단위.
  bool _policyApplied = false;
  LessonPolicy? _effectivePolicy;
  String? _appliedPolicyMembershipId;

  /// In-flight guard: prevents double-tap from issuing twice.
  bool _submitting = false;

  final _amountController = TextEditingController();
  final _lessonsController = TextEditingController();
  final _validityController = TextEditingController();
  final _discountController = TextEditingController();
  final _bonusController = TextEditingController();
  final _customBonusReasonController = TextEditingController();

  // --- Mixin interface ---

  @override
  String get primaryStudentId => widget.primaryStudentId;
  @override
  List<String> get allStudentIds => widget.studentIds;
  @override
  bool get isBatchMode => widget.isBatchMode;
  @override
  String? get lessonRequestId => widget.lessonRequestId;
  @override
  List<String> get lessonRequestIds => widget.lessonRequestIds;
  @override
  GlobalKey<FormState> get formKey => _formKey;
  @override
  SubscriptionType get selectedType => _selectedType;
  @override
  String? get selectedMembershipId => _selectedMembershipId;
  @override
  bool get isPaymentConfirmed => _isPaymentConfirmed;
  @override
  SubscriptionPaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;
  @override
  int get totalLessons => _totalLessons;
  @override
  int get validityDays => _validityDays;
  @override
  int get monthsCount => _monthsCount;
  @override
  int get lessonsPerMonth => _lessonsPerMonth;
  @override
  int get originalAmount => _originalAmount;
  @override
  int get discountPercent => _discountPercent;
  @override
  int get bonusLessons => _bonusLessons;
  @override
  DateTime? get startDate => _startDate;
  @override
  int get rescheduleAllowance => _rescheduleAllowance;
  @override
  int get rescheduleDeadlineHours => _rescheduleDeadlineHours;
  @override
  String? get selectedLocationId => _selectedLocationId;
  @override
  int get travelTimeMinutes => _travelTimeMinutes;

  @override
  String? get effectiveBonusReason {
    if (_bonusLessons == 0) return null;
    if (_bonusReason == AppStrings.issueFormBonusReasonOther) {
      return _customBonusReason.isNotEmpty ? _customBonusReason : null;
    }
    return _bonusReason;
  }

  @override
  int get finalAmount {
    if (_discountPercent <= 0) return _originalAmount;
    return (_originalAmount * (100 - _discountPercent) / 100).round();
  }

  /// Resolves the student's preferred location type from the linked lesson request.
  /// Returns null if there is no linked request or no preference was set.
  LocationType? _resolvePreferredLocationType() {
    final requestId = widget.lessonRequestId;
    if (requestId == null) return null;
    final requestAsync = ref.watch(unifiedRequestByIdProvider(requestId));
    final raw = requestAsync.valueOrNull?.preferredLocationType;
    if (raw == null) return null;
    try {
      return LocationType.values.byName(raw);
    } catch (_) {
      return null;
    }
  }

  // --- Lifecycle ---

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

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    _scheduleTemplateDefaults();

    final membershipsAsync =
        widget.isBatchMode
            ? const AsyncValue<List<ClassMembership>>.data([])
            : ref.watch(
              subscriptionIssueMembershipsProvider(widget.primaryStudentId),
            );

    // Pre-fill amount from student.monthlyFee (once only)
    if (!_hasPrefilledAmount &&
        !widget.isBatchMode &&
        widget.templateId == null) {
      final studentAsync = ref.watch(
        subscriptionIssueStudentProvider(widget.primaryStudentId),
      );
      studentAsync.whenData((student) {
        if (student != null && student.monthlyFee > 0 && _originalAmount == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _originalAmount = student.monthlyFee;
                _amountController.text = student.monthlyFee.toString();
                _hasPrefilledAmount = true;
              });
            }
          });
        } else {
          _hasPrefilledAmount = true;
        }
      });
    }

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: widget.isBatchMode
            ? AppStrings.batchSubscriptionAppBarTitle(widget.studentIds.length)
            : AppStrings.proposalTitle,
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
                      _applyPolicyDefaults(memberships.first);
                    });
                  } else if (_selectedMembershipId != null &&
                      _appliedPolicyMembershipId != _selectedMembershipId) {
                    final selected = memberships.firstWhere(
                      (m) => m.id == _selectedMembershipId,
                      orElse: () => memberships.first,
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _applyPolicyDefaults(selected);
                    });
                  }

                  return _buildForm(memberships);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) =>
                        SubscriptionErrorState(error: error.toString()),
              ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  void _scheduleTemplateDefaults() {
    final templateId = widget.templateId;
    if (templateId == null || _appliedTemplateId == templateId) return;

    final templateAsync = ref.watch(subscriptionTemplateProvider(templateId));
    templateAsync.whenData((template) {
      if (template == null || _appliedTemplateId == template.id) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _appliedTemplateId == template.id) return;
        _applyTemplateDefaults(template);
      });
    });
  }

  void _applyTemplateDefaults(SubscriptionTemplate template) {
    setState(() {
      _selectedType = SubscriptionType.package;
      _totalLessons = template.totalLessons;
      _validityDays = template.validityDays;
      _originalAmount = template.price;
      _rescheduleAllowance = template.rescheduleAllowance;
      _lessonsController.text = template.totalLessons.toString();
      _validityController.text = template.validityDays.toString();
      _amountController.text = template.price.toString();
      _hasPrefilledAmount = true;
      _appliedTemplateId = template.id;
    });
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
              onChanged: (value) {
                setState(() {
                  _selectedMembershipId = value;
                  _policyApplied = false;
                  _appliedPolicyMembershipId = null;
                });
                if (value != null) {
                  final m = memberships.firstWhere(
                    (x) => x.id == value,
                    orElse: () => memberships.first,
                  );
                  _applyPolicyDefaults(m);
                }
              },
            ),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Selected membership info
          if (_selectedMembershipId != null)
            MembershipInfoCard(
              memberships: memberships,
              selectedMembershipId: _selectedMembershipId,
            ),

          // Location & travel time selector
          if (_selectedMembershipId != null) ...[
            const SizedBox(height: AppSpacing.space6),
            LocationTravelSelector(
              membershipId: _selectedMembershipId!,
              studentId: widget.primaryStudentId,
              currentLocationId: _selectedLocationId,
              currentTravelTime: _travelTimeMinutes,
              onLocationChanged:
                  (locationId) =>
                      setState(() => _selectedLocationId = locationId),
              onTravelTimeChanged:
                  (minutes) => setState(() => _travelTimeMinutes = minutes),
              initialLocationType: _resolvePreferredLocationType(),
            ),
          ],

          const SizedBox(height: AppSpacing.space6),

          // Subscription type selector
          SubscriptionTypeSelector(
            selectedType: _selectedType,
            onChanged: (type) => setState(() => _selectedType = type),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Type-specific options
          _buildTypeOptions(),

          const SizedBox(height: AppSpacing.space6),

          // Amount input
          AmountInputSection(
            originalAmount: _originalAmount,
            controller: _amountController,
            selectedType: _selectedType,
            totalLessons: _totalLessons,
            finalAmount: finalAmount,
            discountPercent: _discountPercent,
            onAmountChanged: (value) => setState(() => _originalAmount = value),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Discount section
          if (_selectedType != SubscriptionType.trial) ...[
            DiscountSection(
              discountPercent: _discountPercent,
              originalAmount: _originalAmount,
              finalAmount: finalAmount,
              onChanged: (value) => setState(() => _discountPercent = value),
              controller: _discountController,
            ),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Bonus section
          if (_selectedType != SubscriptionType.trial) ...[
            BonusSection(
              bonusLessons: _bonusLessons,
              bonusReason: _bonusReason,
              customBonusReason: _customBonusReason,
              onBonusLessonsChanged: (value) {
                setState(() {
                  _bonusLessons = value;
                  if (value == 0) _bonusReason = null;
                });
              },
              onBonusReasonChanged:
                  (reason) => setState(() => _bonusReason = reason),
              onCustomBonusReasonChanged:
                  (value) => setState(() => _customBonusReason = value),
              bonusController: _bonusController,
              customBonusReasonController: _customBonusReasonController,
            ),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Start date
          StartDatePickerField(
            startDate: _startDate,
            onChanged: (date) => setState(() => _startDate = date),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Reschedule allowance (not for trial)
          if (_selectedType != SubscriptionType.trial) ...[
            _buildRescheduleAllowanceSection(),
            const SizedBox(height: AppSpacing.space6),
          ],

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
            finalAmount: finalAmount,
            discountPercent: _discountPercent,
            bonusLessons: _bonusLessons,
            effectiveBonusReason: effectiveBonusReason,
            isPaymentConfirmed: _isPaymentConfirmed,
            selectedPaymentMethod: _selectedPaymentMethod,
            startDate: _startDate,
            effectivePolicy: _effectivePolicy,
            rescheduleAllowance: _rescheduleAllowance,
            rescheduleDeadlineHours: _rescheduleDeadlineHours,
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

          _buildTypeOptions(),

          const SizedBox(height: AppSpacing.space6),

          AmountInputSection(
            originalAmount: _originalAmount,
            controller: _amountController,
            selectedType: _selectedType,
            totalLessons: _totalLessons,
            finalAmount: finalAmount,
            discountPercent: _discountPercent,
            onAmountChanged: (value) => setState(() => _originalAmount = value),
          ),

          const SizedBox(height: AppSpacing.space6),

          if (_selectedType != SubscriptionType.trial) ...[
            DiscountSection(
              discountPercent: _discountPercent,
              originalAmount: _originalAmount,
              finalAmount: finalAmount,
              onChanged: (value) => setState(() => _discountPercent = value),
              controller: _discountController,
            ),
            const SizedBox(height: AppSpacing.space6),
          ],

          if (_selectedType != SubscriptionType.trial) ...[
            BonusSection(
              bonusLessons: _bonusLessons,
              bonusReason: _bonusReason,
              customBonusReason: _customBonusReason,
              onBonusLessonsChanged: (value) {
                setState(() {
                  _bonusLessons = value;
                  if (value == 0) _bonusReason = null;
                });
              },
              onBonusReasonChanged:
                  (reason) => setState(() => _bonusReason = reason),
              onCustomBonusReasonChanged:
                  (value) => setState(() => _customBonusReason = value),
              bonusController: _bonusController,
              customBonusReasonController: _customBonusReasonController,
            ),
            const SizedBox(height: AppSpacing.space6),
          ],

          StartDatePickerField(
            startDate: _startDate,
            onChanged: (date) => setState(() => _startDate = date),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Reschedule allowance (not for trial)
          if (_selectedType != SubscriptionType.trial) ...[
            _buildRescheduleAllowanceSection(),
            const SizedBox(height: AppSpacing.space6),
          ],

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
            finalAmount: finalAmount,
            discountPercent: _discountPercent,
            bonusLessons: _bonusLessons,
            effectiveBonusReason: effectiveBonusReason,
            startDate: _startDate,
            effectivePolicy: _effectivePolicy,
            rescheduleAllowance: _rescheduleAllowance,
            rescheduleDeadlineHours: _rescheduleDeadlineHours,
          ),

          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildRescheduleAllowanceSection() {
    final policy = _effectivePolicy;
    final policyAllowance = policy?.maxChangesPerMonth;
    final matchesPolicy =
        policyAllowance != null && _rescheduleAllowance == policyAllowance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Notebook × Score: 폼 섹션 제목은 Playfair sectionTitle
            // 로 통일 (§7.17).
            Text(
              AppStrings.rescheduleAllowanceTitle,
              style: NotebookTypography.sectionTitle,
            ),
            if (policy != null) ...[
              const SizedBox(width: AppSpacing.space2),
              _PolicyBadge(isDefault: matchesPolicy),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          AppStrings.rescheduleAllowanceDescription,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        if (policy != null) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(
            matchesPolicy
                ? AppStrings.rescheduleAllowanceMatchesPolicy(
                  policy.changePolicySummary,
                )
                : AppStrings.rescheduleAllowanceOverridePolicy(
                  policy.changePolicySummary,
                  _rescheduleAllowance,
                ),
            style: AppTypography.bodySmall.copyWith(
              color:
                  matchesPolicy ? AppColors.paperAccent : AppColors.inkTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.space3),
        Row(
          children: [
            for (final count in [0, 1, 2, 3, 5])
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.space2),
                child: ChoiceChip(
                  label: Text(
                    count == 0
                        ? AppStrings.rescheduleAllowanceNone
                        : AppStrings.usageCountShort(count),
                  ),
                  selected: _rescheduleAllowance == count,
                  onSelected:
                      (_) => setState(() => _rescheduleAllowance = count),
                  selectedColor: AppColors.paperAccent,
                  backgroundColor: AppColors.paper,
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color:
                        _rescheduleAllowance == count
                            ? AppColors.paper
                            : AppColors.ink,
                    fontWeight:
                        _rescheduleAllowance == count
                            ? FontWeight.w600
                            : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color:
                        _rescheduleAllowance == count
                            ? AppColors.paperAccent
                            : AppColors.inkQuaternary,
                  ),
                  shape: const RoundedRectangleBorder(),
                ),
              ),
          ],
        ),
        if (_rescheduleAllowance > 0) ...[
          const SizedBox(height: AppSpacing.space4),
          // Notebook × Score: 폼 섹션 제목은 Playfair sectionTitle
          // 로 통일 (§7.17).
          Text(
            AppStrings.rescheduleDeadlineLabel,
            style: NotebookTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            AppStrings.rescheduleDeadlineDescription,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              for (final hours in [6, 12, 24, 48])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.space2),
                  child: ChoiceChip(
                    label: Text('$hours${AppStrings.hoursUnit}'),
                    selected: _rescheduleDeadlineHours == hours,
                    onSelected:
                        (_) => setState(() => _rescheduleDeadlineHours = hours),
                    selectedColor: AppColors.paperAccent,
                    backgroundColor: AppColors.paper,
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color:
                          _rescheduleDeadlineHours == hours
                              ? AppColors.paper
                              : AppColors.ink,
                      fontWeight:
                          _rescheduleDeadlineHours == hours
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color:
                          _rescheduleDeadlineHours == hours
                              ? AppColors.paperAccent
                              : AppColors.inkQuaternary,
                    ),
                    shape: const RoundedRectangleBorder(),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTypeOptions() {
    if (_selectedType == SubscriptionType.package) {
      return PackageOptionsSection(
        totalLessons: _totalLessons,
        validityDays: _validityDays,
        onLessonsChanged: (value) {
          setState(() {
            _totalLessons = value;
            if (value > 0) _setDefaultValidity(value);
          });
        },
        onValidityChanged: (value) => setState(() => _validityDays = value),
        lessonsController: _lessonsController,
        validityController: _validityController,
      );
    } else if (_selectedType == SubscriptionType.monthly) {
      return MonthlyOptionsSection(
        monthsCount: _monthsCount,
        onChanged: (months) => setState(() => _monthsCount = months),
        lessonsPerMonth: _lessonsPerMonth,
        onLessonsPerMonthChanged:
            (count) => setState(() => _lessonsPerMonth = count),
      );
    } else {
      return const TrialOptionsSection();
    }
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

  /// Guarded submit — disables the button while an issue is in flight so a
  /// double-tap cannot create two subscriptions.
  Future<void> _handleSubmit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      if (widget.isBatchMode) {
        await issueBatchSubscription();
      } else {
        await issueSubscription();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: FilledButton(
          onPressed: _submitting ? null : _handleSubmit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  widget.isBatchMode
                      ? AppStrings.batchIssueButtonLabel(
                          widget.studentIds.length,
                        )
                      : AppStrings.proposalTitle,
                ),
        ),
      ),
    );
  }

  /// Load teacher's default policy for the selected membership's class,
  /// and seed `_rescheduleAllowance` unless the user already edited.
  Future<void> _applyPolicyDefaults(ClassMembership membership) async {
    if (!mounted) return;
    if (_appliedPolicyMembershipId == membership.id && _policyApplied) return;

    try {
      final policy = await ref.read(
        subscriptionIssueEffectivePolicyProvider(membership).future,
      );
      if (policy == null || !mounted) return;

      setState(() {
        _effectivePolicy = policy;
        _appliedPolicyMembershipId = membership.id;
        if (!_policyApplied) {
          _rescheduleAllowance = policy.maxChangesPerMonth;
          _policyApplied = true;
        }
      });
    } catch (_) {
      // Policy is optional; fall back to hard-coded defaults silently.
    }
  }
}

/// Small badge shown next to reschedule section header when the teacher's
/// policy value is active (or has been manually overridden).
class _PolicyBadge extends StatelessWidget {
  final bool isDefault;
  const _PolicyBadge({required this.isDefault});

  @override
  Widget build(BuildContext context) {
    final color = isDefault ? AppColors.paperAccent : AppColors.inkTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isDefault
            ? AppStrings.policyBadgeDefault
            : AppStrings.policyBadgeCustom,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
