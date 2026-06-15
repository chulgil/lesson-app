import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../analytics/analytics_facade.dart'
    show AnalyticsEvents, analyticsEventLoggerProvider;
import '../../../auth/auth_facade.dart';
import '../../../schedule/schedule_facade.dart';
import '../../../students/domain/entities/class_membership.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../providers/proposal_draft_provider.dart';
import '../providers/subscription_issue_flow_provider.dart';
import '../providers/subscription_providers.dart';
import '../widgets/duplicate_proposal_dialog.dart';

UnifiedRequestStatus lessonRequestStatusForIssuedSubscription() =>
    UnifiedRequestStatus.subscriptionIssued;

/// Add [months] to [from], clamping the day to the target month's last day.
///
/// `DateTime(year, month + n, day)` overflows when the source day does not
/// exist in the target month (e.g. Jan 31 + 1 month → Mar 3 instead of
/// Feb 28). This keeps the end date inside the intended month.
DateTime addMonthsClamped(DateTime from, int months) {
  final targetYear = from.year + ((from.month - 1 + months) ~/ 12);
  final targetMonth = (from.month - 1 + months) % 12 + 1;
  // Day 0 of next month = last day of target month.
  final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
  final clampedDay =
      from.day <= lastDayOfTargetMonth ? from.day : lastDayOfTargetMonth;
  return DateTime(
    targetYear,
    targetMonth,
    clampedDay,
    from.hour,
    from.minute,
    from.second,
    from.millisecond,
    from.microsecond,
  );
}

mixin IssueSubscriptionActions<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  String get primaryStudentId;
  List<String> get allStudentIds;
  bool get isBatchMode;
  String? get lessonRequestId;
  List<String> get lessonRequestIds;

  GlobalKey<FormState> get formKey;
  SubscriptionType get selectedType;
  String? get selectedMembershipId;
  bool get isPaymentConfirmed;
  SubscriptionPaymentMethod get selectedPaymentMethod;
  int get totalLessons;
  int get validityDays;
  int get monthsCount;
  int get lessonsPerMonth;
  int get originalAmount;
  int get discountPercent;
  int get bonusLessons;
  String? get effectiveBonusReason;
  DateTime? get startDate;
  int get finalAmount;
  int get rescheduleAllowance;
  int get rescheduleDeadlineHours;
  String? get selectedLocationId;
  int get travelTimeMinutes;

  /// #695 — template applied to the form (saved into the proposal draft).
  String? get appliedTemplateId;

  Future<void> issueSubscription() async {
    if (formKey.currentState?.validate() != true) return;
    if (selectedMembershipId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.chooseLessonValidation)),
      );
      return;
    }
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.chooseStartDateValidation)),
      );
      return;
    }

    if (bonusLessons > 0 && effectiveBonusReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.chooseBonusReasonValidation)),
      );
      return;
    }

    // #696 §3.1.5 — block issuance while the student already has a
    // pending/paymentNotified proposal from this teacher (double-payment risk).
    final studentNameForGuard = await _getStudentName();
    if (!mounted) return;
    final canProceed = await ensureNoDuplicateProposal(
      context: context,
      ref: ref,
      teacherId: ref.read(currentUserIdProvider),
      studentId: primaryStudentId,
      studentName: studentNameForGuard,
    );
    if (!canProceed || !mounted) return;

    DateTime? endDate;
    int? computedTotalLessons;
    int? computedLessonsPerMonth;

    if (selectedType == SubscriptionType.monthly) {
      endDate = addMonthsClamped(startDate!, monthsCount);
      computedLessonsPerMonth = lessonsPerMonth;
    } else if (selectedType == SubscriptionType.trial) {
      computedTotalLessons = 1;
      endDate = startDate!.add(const Duration(days: 7));
    } else {
      computedTotalLessons = totalLessons;
      endDate = startDate!.add(Duration(days: validityDays));
    }

    final now = DateTime.now();
    final subscription = Subscription(
      id: const Uuid().v4(),
      studentId: primaryStudentId,
      membershipId: selectedMembershipId!,
      type: selectedType,
      totalLessons: computedTotalLessons,
      lessonsPerMonth: computedLessonsPerMonth,
      usedLessons: 0,
      bonusCount: bonusLessons,
      bonusReason: effectiveBonusReason,
      startDate: startDate,
      endDate: endDate,
      amount: finalAmount,
      status: SubscriptionStatus.active,
      createdAt: now,
      paymentConfirmed: isPaymentConfirmed,
      paymentMethod: isPaymentConfirmed ? selectedPaymentMethod : null,
      paymentConfirmedAt: isPaymentConfirmed ? now : null,
      originalAmount: discountPercent > 0 ? originalAmount : null,
      discountAmount:
          discountPercent > 0 ? (originalAmount - finalAmount) : null,
      discountReason:
          discountPercent > 0
              ? AppStrings.discountPercentReason(discountPercent)
              : null,
      totalRescheduleAllowance: rescheduleAllowance,
      rescheduleDeadlineHours: rescheduleDeadlineHours,
    );

    final repository = ref.read(subscriptionRepositoryProvider);
    String? teacherId;
    String? createdSubscriptionId;

    try {
      // create() reassigns the id (mock: new uuid / remote: server id), so the
      // returned subscription is the source of truth — never the local one.
      final created = await repository.create(subscription);
      createdSubscriptionId = created.id;

      // Refresh list/detail providers so the newly issued subscription is
      // visible immediately (repository.create bypasses the notifier).
      invalidateSubscriptionListsForStudent(
        ref,
        primaryStudentId,
        membershipId: selectedMembershipId,
      );

      // Update membership with location and travel time if set
      if (selectedLocationId != null || travelTimeMinutes > 0) {
        await _updateMembershipLocationTravel(
          membershipId: selectedMembershipId!,
          locationId: selectedLocationId,
          travelTime: travelTimeMinutes,
        );
      }

      // Transition relationship to active (Issue #59)
      teacherId = await _getTeacherIdFromMembership(created.membershipId);
      if (teacherId != null) {
        // Refresh teacher-scoped lists (e.g. unpaid summary) now that the
        // teacher is known.
        invalidateSubscriptionListsForStudent(
          ref,
          primaryStudentId,
          membershipId: selectedMembershipId,
          teacherId: teacherId,
        );
        await ref
            .read(subscriptionIssueFlowControllerProvider)
            .activateRelationshipForSubscription(
              teacherId: teacherId,
              studentId: primaryStudentId,
              subscriptionId: created.id,
            );
      }

      // Create schedule confirmation card for student (Issue #62)
      await _createScheduleConfirmationCard(created);

      // Update lesson request: link proposal and set status
      if (lessonRequestId != null) {
        await ref
            .read(subscriptionIssueFlowControllerProvider)
            .updateLessonRequestForIssuedSubscription(
              lessonRequestId: lessonRequestId!,
              subscriptionId: created.id,
              status: lessonRequestStatusForIssuedSubscription(),
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.subscriptionIssueSuccess),
            backgroundColor: AppColors.paperAccent,
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
              'teacherName': AppStrings.teacher,
              'studentId': primaryStudentId,
              'studentName': studentName,
            },
          );
        } else {
          context.pop();
        }
      }
    } on PhoneVerificationRequiredException catch (_) {
      // A post-create step hit the gate — clean up the orphan so it never
      // surfaces as an active, unconfirmed subscription (proposal_confirm parity).
      await _deactivateOrphanSubscription(repository, createdSubscriptionId);
      // #430 G1 §4.3 — E3 게이트. 백엔드가 미인증 선생님에게 발급 차단 시
      // 안내 다이얼로그 + 인증 화면 진입 옵션을 제공한다.
      // #695 §4.4 — "나중에" 선택 시 입력값을 draft 로 저장하여 복구 경로 제공.
      if (mounted) {
        await _showGateWithDraftSave();
      }
    } catch (e) {
      // A post-create step failed after the subscription was created —
      // deactivate the orphan so a retry does not duplicate issuance.
      await _deactivateOrphanSubscription(repository, createdSubscriptionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.subscriptionIssueFailRetry),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }

  /// #695 — show the E3 gate with instrumentation and draft save on "나중에".
  ///
  /// Events (spec §5.5): `gate_shown` on display, `gate_later_selected`
  /// (with `draftSaved`) when the teacher defers verification.
  Future<void> _showGateWithDraftSave() async {
    final logger = ref.read(analyticsEventLoggerProvider);
    final userId = ref.read(currentUserIdProvider);
    logger.log(AnalyticsEvents.phoneVerificationGateShown, {
      'userId': userId,
      'subscriptionDraftId': primaryStudentId,
    });

    final chosen = await PhoneVerificationGate.show(context);
    if (chosen == true) return;

    // "나중에" — persist the in-progress form so the recovery banner appears
    // on re-entry. The form itself stays as-is (spec §4.4: screen retained).
    var draftSaved = false;
    try {
      await ref
          .read(proposalDraftStorageProvider)
          .save(
            userId: userId,
            studentId: primaryStudentId,
            templateId: appliedTemplateId,
            amount: originalAmount,
            totalLessons: totalLessons,
            validityDays: validityDays,
            membershipId: selectedMembershipId,
          );
      ref.invalidate(proposalDraftProvider(userId, primaryStudentId));
      draftSaved = true;
    } catch (e) {
      debugPrint('Failed to save proposal draft: $e');
    }
    logger.log(AnalyticsEvents.gateLaterSelected, {
      'userId': userId,
      'subscriptionDraftId': primaryStudentId,
      'draftSaved': draftSaved,
    });
  }

  /// Deactivate a subscription that was created but whose post-create wiring
  /// (relationship / lesson-request link) failed, preventing an orphaned active
  /// subscription. There is no hard delete, so we mark it expired (inactive).
  Future<void> _deactivateOrphanSubscription(
    SubscriptionRepository repo,
    String? subscriptionId,
  ) async {
    if (subscriptionId == null) return;
    try {
      await repo.updateStatus(subscriptionId, SubscriptionStatus.expired);
    } catch (e) {
      debugPrint('Failed to deactivate orphan subscription: $e');
    }
  }

  Future<String?> _getTeacherIdFromMembership(String membershipId) async {
    return ref
        .read(subscriptionIssueFlowControllerProvider)
        .teacherIdForMembership(
          studentId: primaryStudentId,
          membershipId: membershipId,
        );
  }

  Future<String> _getStudentName() async {
    return ref
        .read(subscriptionIssueFlowControllerProvider)
        .studentName(primaryStudentId);
  }

  /// Update the membership's lesson location and travel time.
  Future<void> _updateMembershipLocationTravel({
    required String membershipId,
    String? locationId,
    required int travelTime,
  }) async {
    try {
      await ref
          .read(subscriptionIssueFlowControllerProvider)
          .updateMembershipLocationTravel(
            studentId: primaryStudentId,
            membershipId: membershipId,
            locationId: locationId,
            travelTime: travelTime,
          );
    } catch (e) {
      debugPrint('Failed to update membership location/travel: $e');
    }
  }

  Future<void> _createScheduleConfirmationCard(
    Subscription subscription,
  ) async {
    final flow = ref.read(subscriptionIssueFlowControllerProvider);
    final membership = await flow.membershipForStudent(
      studentId: primaryStudentId,
      membershipId: subscription.membershipId,
    );
    if (membership == null) return;

    final lessonClass = await flow.lessonClassInfoForMembership(membership);
    final teacherId = lessonClass?.teacherId ?? '';

    final cardType = await _detectScheduleCardType(subscription, membership);

    final suggestedDay =
        membership.primarySlot != null
            ? membership.primarySlot!.dayOfWeek + 1
            : null;
    final suggestedTime = membership.primarySlot?.startTime;
    final lessonDuration = membership.lessonDuration;

    // Generate up to 2 alternative time slots from teacher's available schedule
    final alternatives = await _getAlternativeSlots(
      teacherId: teacherId,
      primaryDay: suggestedDay,
      primaryTime: suggestedTime,
    );

    try {
      await flow.createScheduleConfirmationCard(
        studentId: primaryStudentId,
        teacherId: teacherId,
        teacherName: lessonClass?.teacherName ?? AppStrings.teacher,
        instrument: membership.instrument,
        subscriptionId: subscription.id,
        cardType: cardType,
        totalLessons: subscription.totalLessons,
        suggestedDay: suggestedDay,
        suggestedTime: suggestedTime,
        lessonDuration: lessonDuration,
        suggestedDay2: alternatives.isNotEmpty ? alternatives[0].day : null,
        suggestedTime2: alternatives.isNotEmpty ? alternatives[0].time : null,
        suggestedDay3: alternatives.length > 1 ? alternatives[1].day : null,
        suggestedTime3: alternatives.length > 1 ? alternatives[1].time : null,
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
      final allSubscriptions = await ref
          .read(subscriptionIssueFlowControllerProvider)
          .studentSubscriptions(primaryStudentId);

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

  /// Get up to 2 alternative time slots from teacher's weekly schedule.
  /// Excludes the primary suggestion to avoid duplicates.
  Future<List<({int day, String time})>> _getAlternativeSlots({
    required String teacherId,
    int? primaryDay,
    String? primaryTime,
  }) async {
    try {
      return ref
          .read(subscriptionIssueFlowControllerProvider)
          .alternativeSlots(
            teacherId: teacherId,
            primaryDay: primaryDay,
            primaryTime: primaryTime,
          );
    } catch (e) {
      debugPrint('Failed to get alternative slots: $e');
      return [];
    }
  }

  Future<void> issueBatchSubscription() async {
    if (formKey.currentState?.validate() != true) return;
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.chooseStartDateValidation)),
      );
      return;
    }

    if (bonusLessons > 0 && effectiveBonusReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.chooseBonusReasonValidation)),
      );
      return;
    }

    DateTime? endDate;
    int? computedTotalLessons;
    int? computedLessonsPerMonth;

    if (selectedType == SubscriptionType.monthly) {
      endDate = addMonthsClamped(startDate!, monthsCount);
      computedLessonsPerMonth = lessonsPerMonth;
    } else if (selectedType == SubscriptionType.trial) {
      computedTotalLessons = 1;
      endDate = startDate!.add(const Duration(days: 7));
    } else {
      computedTotalLessons = totalLessons;
      endDate = startDate!.add(Duration(days: validityDays));
    }

    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      int successCount = 0;
      int failCount = 0;

      final now = DateTime.now();
      final flow = ref.read(subscriptionIssueFlowControllerProvider);
      for (int i = 0; i < allStudentIds.length; i++) {
        final studentId = allStudentIds[i];
        try {
          // Resolve the student's membership (and teacher) so batch-issued
          // subscriptions carry a membership id and surface in teacher-scoped
          // lists / unpaid summary (getByTeacherId filters by membership).
          final membership = await flow.firstMembershipForStudent(studentId);
          final membershipId = membership?.id ?? '';
          final teacherId =
              membershipId.isEmpty
                  ? null
                  : await flow.teacherIdForMembership(
                    studentId: studentId,
                    membershipId: membershipId,
                  );

          final subscription = Subscription(
            id: const Uuid().v4(),
            studentId: studentId,
            membershipId: membershipId,
            type: selectedType,
            totalLessons: computedTotalLessons,
            lessonsPerMonth: computedLessonsPerMonth,
            usedLessons: 0,
            bonusCount: bonusLessons,
            bonusReason: effectiveBonusReason,
            startDate: startDate,
            endDate: endDate,
            amount: finalAmount,
            status: SubscriptionStatus.active,
            createdAt: now,
            paymentConfirmed: isPaymentConfirmed,
            paymentMethod: isPaymentConfirmed ? selectedPaymentMethod : null,
            paymentConfirmedAt: isPaymentConfirmed ? now : null,
            originalAmount: discountPercent > 0 ? originalAmount : null,
            discountAmount:
                discountPercent > 0 ? (originalAmount - finalAmount) : null,
            discountReason:
                discountPercent > 0
                    ? AppStrings.discountPercentReason(discountPercent)
                    : null,
            totalRescheduleAllowance: rescheduleAllowance,
            rescheduleDeadlineHours: rescheduleDeadlineHours,
          );
          // create() reassigns the id — link the lesson request to the
          // persisted subscription, never the discarded local one.
          final created = await repository.create(subscription);

          // Refresh per-student + teacher-scoped list providers (batch
          // bypasses the notifier).
          invalidateSubscriptionListsForStudent(
            ref,
            studentId,
            membershipId: membershipId,
            teacherId: teacherId,
          );

          if (i < lessonRequestIds.length) {
            await flow.updateLessonRequestForIssuedSubscription(
              lessonRequestId: lessonRequestIds[i],
              subscriptionId: created.id,
              status: lessonRequestStatusForIssuedSubscription(),
            );
          }

          successCount++;
        } on PhoneVerificationRequiredException {
          // #430 G1 §4.3 — batch 중 게이트 발생 시 전체 흐름 중단하고
          // outer catch 로 위임. 가입자 본인 인증이 완료되어야 batch 의
          // 다른 학생도 의미가 있으므로 한 번 노출 후 종료.
          rethrow;
        } catch (e) {
          failCount++;
          debugPrint('Failed to issue subscription for student $studentId: $e');
        }
      }

      if (mounted) {
        if (failCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.batchSubscriptionIssueSuccess(successCount),
              ),
              backgroundColor: AppColors.paperAccent,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.batchSubscriptionIssuePartial(
                  successCount,
                  failCount,
                ),
              ),
              backgroundColor:
                  failCount == allStudentIds.length
                      ? AppColors.paperAccent
                      : AppColors.paperAccent,
            ),
          );
        }
        context.pop();
      }
    } on PhoneVerificationRequiredException catch (_) {
      if (mounted) {
        await PhoneVerificationGate.show(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.subscriptionIssueFailRetry),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }
}
