import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
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

  void issueSubscription() async {
    if (formKey.currentState?.validate() != true) return;
    if (selectedMembershipId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('레슨을 선택해주세요')));
      return;
    }
    if (startDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('시작일을 선택해주세요')));
      return;
    }

    if (bonusLessons > 0 && effectiveBonusReason == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('보너스 사유를 선택해주세요')));
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
      discountReason: discountPercent > 0 ? '$discountPercent% 할인' : null,
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
          studentId: primaryStudentId,
          subscriptionId: subscription.id,
        );
      }

      // Create schedule confirmation card for student (Issue #62)
      await _createScheduleConfirmationCard(subscription);

      // Update lesson request status to proposalSent
      if (lessonRequestId != null) {
        await ref
            .read(lessonRequestActionsProvider.notifier)
            .sendProposal(
              requestId: lessonRequestId!,
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
      studentMembershipsProvider(primaryStudentId),
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
      studentProvider(primaryStudentId).future,
    );
    return student?.name ?? '';
  }

  Future<void> _createScheduleConfirmationCard(
    Subscription subscription,
  ) async {
    final memberships = ref.read(
      studentMembershipsProvider(primaryStudentId),
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
            studentId: primaryStudentId,
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

  void issueBatchSubscription() async {
    if (formKey.currentState?.validate() != true) return;
    if (startDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('시작일을 선택해주세요')));
      return;
    }

    if (bonusLessons > 0 && effectiveBonusReason == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('보너스 사유를 선택해주세요')));
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
                discountPercent > 0 ? '$discountPercent% 할인' : null,
          );
          await repository.create(subscription);

          if (i < lessonRequestIds.length) {
            await ref
                .read(lessonRequestActionsProvider.notifier)
                .sendProposal(
                  requestId: lessonRequestIds[i],
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
                  failCount == allStudentIds.length
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
