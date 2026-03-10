import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../students/domain/entities/class_membership.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../domain/entities/subscription.dart';
import '../widgets/issue_form_discount_bonus.dart';
import '../widgets/issue_form_membership_widgets.dart';
import '../widgets/issue_form_sections.dart';
import '../widgets/issue_form_summary_widgets.dart';
import '../widgets/issue_form_type_options.dart';
import 'issue_subscription_actions.dart';

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
  SubscriptionPaymentMethod get selectedPaymentMethod =>
      _selectedPaymentMethod;
  @override
  int get totalLessons => _totalLessons;
  @override
  int get validityDays => _validityDays;
  @override
  int get monthsCount => _monthsCount;
  @override
  int get originalAmount => _originalAmount;
  @override
  int get discountPercent => _discountPercent;
  @override
  int get bonusLessons => _bonusLessons;
  @override
  DateTime? get startDate => _startDate;

  @override
  String? get effectiveBonusReason {
    if (_bonusLessons == 0) return null;
    if (_bonusReason == '기타') {
      return _customBonusReason.isNotEmpty ? _customBonusReason : null;
    }
    return _bonusReason;
  }

  @override
  int get finalAmount {
    if (_discountPercent <= 0) return _originalAmount;
    return (_originalAmount * (100 - _discountPercent) / 100).round();
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
            onAmountChanged:
                (value) => setState(() => _originalAmount = value),
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
            onAmountChanged:
                (value) => setState(() => _originalAmount = value),
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
          ),

          const SizedBox(height: AppSpacing.space8),
        ],
      ),
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

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: FilledButton(
          onPressed:
              widget.isBatchMode ? issueBatchSubscription : issueSubscription,
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
}
