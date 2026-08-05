// J13 — 그룹 수강권 표시 정합 (spec §4 표시 규칙 2분기, P1-4·P1-5).
//
// 계약:
//   ① groupClassId 有            → 그룹 클래스명 + 그룹 배지
//   ② groupClassId 無 + group    → "그룹 수강권" 라벨 + 그룹 배지
//   ③ 그룹 수강권에는 "개인레슨" 폴백이 어떤 경로로도 뜨지 않는다
//   ④ 만료 임박 카드·알림에 수강권 종류(클래스명/그룹 라벨) 명시
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/students/presentation/providers/student_crud_provider.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_template.dart';
import 'package:lessonaza/features/subscription/domain/services/subscription_expiry_monitor.dart';
import 'package:lessonaza/features/subscription/presentation/extensions/subscription_scope_visuals.dart';
import 'package:lessonaza/features/subscription/presentation/extensions/subscription_visuals.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/expiring_subscriptions_screen.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/subscription_badge.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/subscription_membership_card.dart';

void main() {
  Subscription buildSubscription({
    SubscriptionAppliesTo? appliesTo,
    String? groupClassId,
    int totalLessons = 8,
    int usedLessons = 0,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    return Subscription(
      id: 'sub_group_1',
      studentId: 'student_1',
      membershipId: 'cm_001',
      type: SubscriptionType.package,
      totalLessons: totalLessons,
      usedLessons: usedLessons,
      startDate: now,
      endDate: endDate ?? now.add(const Duration(days: 30)),
      amount: 200000,
      status: SubscriptionStatus.active,
      createdAt: now,
      appliesTo: appliesTo,
      groupClassId: groupClassId,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required Subscription subscription,
    required AsyncValue<String?> classNameAsync,
    String? groupClassName,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SubscriptionMembershipCard(
              subscription: subscription,
              classNameAsync: classNameAsync,
              instrument: '바이올린',
              groupClassName: groupClassName,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('그룹 수강권 표시 규칙 (P1-4)', () {
    testWidgets('① groupClassId 有 → 그룹 클래스명 + 그룹 배지', (tester) async {
      await pumpCard(
        tester,
        subscription: buildSubscription(
          appliesTo: SubscriptionAppliesTo.group,
          groupClassId: 'gc_ensemble',
        ),
        // 멤버십 수업명이 해석되지 않아도(=1:1 폴백 조건) 그룹 경로가 우선한다.
        classNameAsync: const AsyncValue.data(null),
        groupClassName: '앙상블반',
      );

      expect(find.textContaining('앙상블반'), findsOneWidget);
      expect(find.byType(GroupSubscriptionBadge), findsOneWidget);
    });

    testWidgets('② groupClassId 無 + appliesTo=group → "그룹 수강권" 라벨 + 그룹 배지', (
      tester,
    ) async {
      await pumpCard(
        tester,
        subscription: buildSubscription(appliesTo: SubscriptionAppliesTo.group),
        classNameAsync: const AsyncValue.data(null),
      );

      expect(
        find.textContaining(AppStrings.subscriptionGroupTicketLabel),
        findsOneWidget,
      );
      expect(find.byType(GroupSubscriptionBadge), findsOneWidget);
    });

    testWidgets('회귀: 1:1 수강권은 멤버십 수업명 유지 + 그룹 배지 없음', (tester) async {
      await pumpCard(
        tester,
        subscription: buildSubscription(
          appliesTo: SubscriptionAppliesTo.oneToOne,
        ),
        classNameAsync: const AsyncValue.data('바이올린 정규반'),
      );

      expect(find.textContaining('바이올린 정규반'), findsOneWidget);
      expect(find.byType(GroupSubscriptionBadge), findsNothing);
    });

    testWidgets('회귀: appliesTo=null(레거시)은 universal 로 해석 — 기존 1:1 표시 유지', (
      tester,
    ) async {
      final legacy = buildSubscription();

      expect(legacy.effectiveAppliesTo, SubscriptionAppliesTo.universal);

      await pumpCard(
        tester,
        subscription: legacy,
        classNameAsync: const AsyncValue.data(null),
      );

      expect(find.textContaining(AppStrings.individualLesson), findsOneWidget);
      expect(find.byType(GroupSubscriptionBadge), findsNothing);
    });
  });

  group('③ 개인레슨 폴백 0건 (P1-5)', () {
    for (final entry
        in <String, AsyncValue<String?>>{
          '수업명 미해결(data null)': const AsyncValue.data(null),
          '수업명 로딩중': const AsyncValue.loading(),
          '수업명 조회 실패': AsyncValue<String?>.error('boom', StackTrace.empty),
        }.entries) {
      testWidgets('그룹 수강권 — ${entry.key} 에도 개인레슨 폴백 미표시', (tester) async {
        await pumpCard(
          tester,
          subscription: buildSubscription(
            appliesTo: SubscriptionAppliesTo.group,
            groupClassId: 'gc_ensemble',
          ),
          classNameAsync: entry.value,
        );

        expect(find.textContaining('개인레슨'), findsNothing);
        expect(find.textContaining('개인 레슨'), findsNothing);
        // 로딩/에러 폴백('...', '레슨')도 아닌, 그룹 라벨이 그대로 나와야 한다.
        expect(
          find.textContaining(AppStrings.subscriptionGroupTicketLabel),
          findsOneWidget,
        );
        expect(find.byType(GroupSubscriptionBadge), findsOneWidget);
      });
    }

    test('학부모 결제 탭에 개인레슨 리터럴 폴백이 남아 있지 않다', () {
      final source =
          File(
            'lib/features/parent_home/presentation/screens/parent_payments_tab.dart',
          ).readAsStringSync();

      expect(
        source,
        isNot(contains("'개인레슨'")),
        reason: '학부모 결제 탭은 하드코딩 폴백 대신 공용 표시 규칙(displayClassName)을 사용해야 합니다.',
      );
      expect(
        source,
        contains('displayClassName('),
        reason: '학부모 결제 탭도 그룹/1:1 2분기 표시 규칙 SSOT 를 거쳐야 합니다.',
      );
    });
  });

  group('④ 만료 임박에 수강권 종류 명시 (P1-5)', () {
    test('expiryKindLabel — 그룹은 클래스명, 없으면 그룹 라벨, 1:1 은 수강권 종류', () {
      final group = buildSubscription(
        appliesTo: SubscriptionAppliesTo.group,
        groupClassId: 'gc_ensemble',
      );
      final groupNoClass = buildSubscription(
        appliesTo: SubscriptionAppliesTo.group,
      );
      final oneToOne = buildSubscription(
        appliesTo: SubscriptionAppliesTo.oneToOne,
      );

      expect(group.expiryKindLabel(groupClassName: '앙상블반'), '앙상블반');
      expect(
        groupNoClass.expiryKindLabel(),
        AppStrings.subscriptionGroupTicketLabel,
      );
      expect(oneToOne.expiryKindLabel(), oneToOne.typeLabel);
    });

    testWidgets('만료 임박 화면 카드가 그룹 수강권 종류를 표시한다', (tester) async {
      final groupSub = buildSubscription(
        appliesTo: SubscriptionAppliesTo.group,
        usedLessons: 7,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expiringSoonSubscriptionsProvider.overrideWith(
              (ref) async => [groupSub],
            ),
            expiredSubscriptionsProvider.overrideWith((ref) async => []),
            studentsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(home: ExpiringSubscriptionsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.subscriptionGroupTicketLabel),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    test('만료 임박·잔여 소진 알림 본문에 수강권 종류가 들어간다', () async {
      final groupSub = buildSubscription(
        appliesTo: SubscriptionAppliesTo.group,
        usedLessons: 7,
        endDate: DateTime.now().add(const Duration(days: 7, hours: 12)),
      );
      final lowSub = buildSubscription(
        appliesTo: SubscriptionAppliesTo.group,
        usedLessons: 7,
        endDate: DateTime.now().add(const Duration(days: 20)),
      );

      final monitor = SubscriptionExpiryMonitor(
        loadExpiringSoonSubscriptions: () async => [groupSub, lowSub],
        loadExpiredSubscriptions: () async => [],
        triggerSubscriptionRenewal: (_) {},
        copy: SubscriptionExpiryCopy(
          expiringTitle: AppStrings.subscriptionExpiringTitle,
          expiringBody: AppStrings.subscriptionExpiringBody,
          viewActionLabel: AppStrings.subscriptionViewAction,
          lessonsExhaustedTitle: AppStrings.subscriptionLessonsExhaustedTitle,
          lastLessonTitle: AppStrings.subscriptionLastLessonTitle,
          renewalRequestBody: AppStrings.subscriptionRenewalRequestBody,
          renewalActionLabel: AppStrings.subscriptionRenewalAction,
          expiredTitle: AppStrings.subscriptionExpiredTitle,
          subscriptionKindLabel: (sub) => sub.expiryKindLabel(),
        ),
      );

      final alerts = await monitor.checkAndGenerateAlerts();

      expect(alerts, hasLength(2));
      for (final alert in alerts) {
        expect(
          alert.body,
          contains(AppStrings.subscriptionGroupTicketLabel),
          reason: '만료 임박 알림은 어느 수강권인지 본문에 밝혀야 합니다.',
        );
      }
    });
  });

  group('BE wire 계약 (J2)', () {
    Map<String, dynamic> baseJson() => <String, dynamic>{
      'id': 'sub_1',
      'student_id': 'student_1',
      'membership_id': 'cm_001',
      'type': 'package',
      'total_lessons': 8,
      'amount': 200000,
      'status': 'active',
      'created_at': DateTime(2026, 7, 31).toIso8601String(),
    };

    test('applies_to / group_class_id 가 그대로 역직렬화된다', () {
      final parsed = Subscription.fromJson(
        baseJson()
          ..['applies_to'] = 'group'
          ..['group_class_id'] = 'gc_ensemble',
      );

      expect(parsed.appliesTo, SubscriptionAppliesTo.group);
      expect(parsed.groupClassId, 'gc_ensemble');
      expect(parsed.isGroupScoped, isTrue);
    });

    test('applies_to 누락(레거시 행)은 universal 로 해석되고 그룹 취급하지 않는다', () {
      final parsed = Subscription.fromJson(baseJson());

      expect(parsed.appliesTo, isNull);
      expect(parsed.effectiveAppliesTo, SubscriptionAppliesTo.universal);
      expect(parsed.isGroupScoped, isFalse);
    });

    test('toJson 이 BE camelCase enum 라벨을 유지한다', () {
      final json =
          Subscription.fromJson(
            baseJson()..['applies_to'] = 'oneToOne',
          ).toJson();

      expect(json['applies_to'], 'oneToOne');
    });

    test('SubscriptionTemplate 도 같은 2필드를 왕복한다', () {
      final template = SubscriptionTemplate.fromJson(<String, dynamic>{
        'id': 'tpl_1',
        'owner_id': 'teacher_1',
        'owner_type': 'teacher',
        'name': '앙상블 8회권',
        'total_lessons': 8,
        'lesson_duration_minutes': 60,
        'validity_days': 90,
        'price': 140000,
        'created_at': DateTime(2026, 7, 31).toIso8601String(),
        'applies_to': 'group',
        'group_class_id': 'gc_ensemble',
      });

      expect(template.appliesTo, SubscriptionAppliesTo.group);
      expect(template.groupClassId, 'gc_ensemble');
      expect(template.toJson()['applies_to'], 'group');
    });
  });
}
