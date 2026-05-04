import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/mock/mock_lesson_data_ids.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/students/presentation/providers/membership_providers.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/subscription_detail_screen.dart';

void main() {
  testWidgets('uses the same paper background as lesson request detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionProvider(
            'sub_1',
          ).overrideWith((ref) async => _activeSubscription()),
          subscriptionUsageHistoryProvider(
            'sub_1',
          ).overrideWith((ref) async => const []),
          subscriptionSessionEventsProvider(
            subscriptionId: 'sub_1',
            sessionNumber: 3,
          ).overrideWith((ref) async => const []),
          membershipProvider('membership_1').overrideWith((ref) async => null),
          studentNameMapProvider.overrideWithValue({'student_1': '김민준'}),
          teacherNameMapProvider.overrideWithValue({
            MockLessonDataIds.teacherPrimary: '김선아',
          }),
        ],
        child: const MaterialApp(
          home: SubscriptionDetailScreen(
            subscriptionId: 'sub_1',
            viewerRole: 'teacher',
            initialSelectedSession: 3,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppColors.paper);
  });
}

Subscription _activeSubscription() {
  return Subscription(
    id: 'sub_1',
    studentId: 'student_1',
    membershipId: 'membership_1',
    type: SubscriptionType.monthly,
    lessonsPerMonth: 4,
    usedLessons: 2,
    amount: 280000,
    status: SubscriptionStatus.active,
    createdAt: DateTime(2026, 4, 1),
  );
}
