import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../relationship/presentation/providers/relationship_providers.dart';
import '../../../students/domain/entities/class_membership.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../../../schedule/domain/entities/schedule_confirmation_card.dart';
import '../../../schedule/domain/entities/unified_lesson_request.dart';
import '../../../schedule/presentation/providers/unified_lesson_request_providers.dart';
import '../../../schedule/presentation/providers/schedule_confirmation_card_providers.dart';
import '../../../settings/presentation/providers/teacher_settings_provider.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';

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

  void issueSubscription() async {
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

    DateTime? endDate;
    int? computedTotalLessons;

    if (selectedType == SubscriptionType.monthly) {
      endDate = DateTime(
        startDate!.year,
        startDate!.month + monthsCount,
        startDate!.day,
      );
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

    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      await repository.create(subscription);

      // Update membership with location and travel time if set
      if (selectedLocationId != null || travelTimeMinutes > 0) {
        await _updateMembershipLocationTravel(
          membershipId: selectedMembershipId!,
          locationId: selectedLocationId,
          travelTime: travelTimeMinutes,
        );
      }

      // Transition relationship to active (Issue #59)
      final teacherId = await _getTeacherIdFromMembership(
        subscription.membershipId,
      );
      if (teacherId != null) {
        final relationRepo = ref.read(teacherStudentRelationRepositoryProvider);
        await relationRepo.onSubscriptionIssued(
          teacherId: teacherId,
          studentId: primaryStudentId,
          subscriptionId: subscription.id,
        );
      }

      // Create schedule confirmation card for student (Issue #62)
      await _createScheduleConfirmationCard(subscription);

      // Update lesson request: link proposal and set status
      if (lessonRequestId != null) {
        final repo = ref.read(unifiedLessonRequestRepositoryProvider);
        final request = await repo.getById(lessonRequestId!);
        if (request != null) {
          await repo.update(
            request.copyWith(
              proposalId: subscription.id,
              status: UnifiedRequestStatus.proposalSent,
            ),
          );
        }
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

  Future<String?> _getTeacherIdFromMembership(String membershipId) async {
    final memberships = ref.read(studentMembershipsProvider(primaryStudentId));
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
    final student = await ref.read(studentProvider(primaryStudentId).future);
    return student?.name ?? '';
  }

  /// Update the membership's lesson location and travel time.
  Future<void> _updateMembershipLocationTravel({
    required String membershipId,
    String? locationId,
    required int travelTime,
  }) async {
    try {
      final memberships = ref.read(
        studentMembershipsProvider(primaryStudentId),
      );
      final membership = memberships.valueOrNull?.firstWhere(
        (m) => m.id == membershipId,
        orElse: () => throw Exception('Membership not found'),
      );
      if (membership == null) return;

      final updated = membership.copyWith(
        lessonLocationId: locationId,
        travelTimeMinutes: travelTime,
      );

      final membershipRepo = ref.read(membershipRepositoryProvider);
      await membershipRepo.update(updated);
    } catch (e) {
      debugPrint('Failed to update membership location/travel: $e');
    }
  }

  Future<void> _createScheduleConfirmationCard(
    Subscription subscription,
  ) async {
    final memberships = ref.read(studentMembershipsProvider(primaryStudentId));
    final membership = memberships.valueOrNull?.firstWhere(
      (m) => m.id == subscription.membershipId,
      orElse: () => throw Exception('Membership not found'),
    );

    if (membership == null) return;

    final lessonClassAsync = await ref.read(
      lessonClassProvider(membership.lessonClassId).future,
    );

    final cardType = await _detectScheduleCardType(subscription, membership);

    final suggestedDay =
        membership.primarySlot != null
            ? membership.primarySlot!.dayOfWeek + 1
            : null;
    final suggestedTime = membership.primarySlot?.startTime;
    final lessonDuration = membership.lessonDuration;

    // Generate up to 2 alternative time slots from teacher's available schedule
    final alternatives = await _getAlternativeSlots(
      teacherId: lessonClassAsync?.teacherId ?? '',
      primaryDay: suggestedDay,
      primaryTime: suggestedTime,
    );

    try {
      await ref
          .read(scheduleConfirmationCardNotifierProvider.notifier)
          .createCard(
            studentId: primaryStudentId,
            teacherId: lessonClassAsync?.teacherId ?? '',
            teacherName: lessonClassAsync?.name ?? AppStrings.teacher,
            instrument: membership.instrument,
            subscriptionId: subscription.id,
            cardType: cardType,
            totalLessons: subscription.totalLessons,
            suggestedDay: suggestedDay,
            suggestedTime: suggestedTime,
            lessonDuration: lessonDuration,
            suggestedDay2: alternatives.isNotEmpty ? alternatives[0].day : null,
            suggestedTime2:
                alternatives.isNotEmpty ? alternatives[0].time : null,
            suggestedDay3: alternatives.length > 1 ? alternatives[1].day : null,
            suggestedTime3:
                alternatives.length > 1 ? alternatives[1].time : null,
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
        studentSubscriptionsProvider(primaryStudentId).future,
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

  /// Get up to 2 alternative time slots from teacher's weekly schedule.
  /// Excludes the primary suggestion to avoid duplicates.
  Future<List<({int day, String time})>> _getAlternativeSlots({
    required String teacherId,
    int? primaryDay,
    String? primaryTime,
  }) async {
    try {
      if (teacherId.isEmpty) return [];

      // Use teacher's availability settings to find alternative slots
      final settingsAsync = ref.read(teacherSettingsByIdProvider(teacherId));
      final settings = settingsAsync.valueOrNull;
      if (settings == null) return [];

      final alternatives = <({int day, String time})>[];

      // Collect unique day/time pairs from available slots
      for (final slot in settings.availableSlots) {
        if (!slot.isActive) continue;

        final slotDay = slot.dayOfWeek;
        final slotTimeStr =
            '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}';

        // Skip the primary suggestion
        if (slotDay == primaryDay && slotTimeStr == primaryTime) continue;

        // Avoid duplicates
        final isDuplicate = alternatives.any(
          (a) => a.day == slotDay && a.time == slotTimeStr,
        );
        if (isDuplicate) continue;

        alternatives.add((day: slotDay, time: slotTimeStr));
        if (alternatives.length >= 2) break;
      }

      return alternatives;
    } catch (e) {
      debugPrint('Failed to get alternative slots: $e');
      return [];
    }
  }

  void issueBatchSubscription() async {
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

    if (selectedType == SubscriptionType.monthly) {
      endDate = DateTime(
        startDate!.year,
        startDate!.month + monthsCount,
        startDate!.day,
      );
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
      for (int i = 0; i < allStudentIds.length; i++) {
        final studentId = allStudentIds[i];
        try {
          final subscription = Subscription(
            id: const Uuid().v4(),
            studentId: studentId,
            membershipId: '',
            type: selectedType,
            totalLessons: computedTotalLessons,
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
          await repository.create(subscription);

          if (i < lessonRequestIds.length) {
            final repo = ref.read(unifiedLessonRequestRepositoryProvider);
            final req = await repo.getById(lessonRequestIds[i]);
            if (req != null) {
              await repo.update(
                req.copyWith(
                  proposalId: subscription.id,
                  status: UnifiedRequestStatus.proposalSent,
                ),
              );
            }
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
