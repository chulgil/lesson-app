// A2 (audit 2026-07-10) — `issueSubscription` creates a Subscription through
// the repository directly, so it MUST invalidate the subscription read
// providers. Otherwise the teacher issues a subscription and the student's
// list / payment-pending badges keep serving the cached (stale) value.
//
// Oracle: a real write through the actions class, observed by a LIVE listener
// on the read provider. The listener is what makes the cache stick — without
// it an autoDispose provider refetches on the next read and the test would
// pass even with the bug.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';

void main() {
  const requestId = 'ulr_1';
  const studentId = 'student_1';
  const teacherId = 'teacher_1';

  test('수강권 발급 후 학생 수강권 목록 provider 가 재요청된다', () async {
    final container = ProviderContainer(
      overrides: [mockDataModeProvider.overrideWithValue(true)],
    );
    addTearDown(container.dispose);

    // Live listener — mirrors a screen watching the list (keeps the cache).
    final sub = container.listen(
      studentSubscriptionsProvider(studentId),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);

    final before =
        (await container.read(studentSubscriptionsProvider(studentId).future))
            .length;

    await UnifiedLessonRequestActions(container).issueSubscription(
      requestId,
      teacherId,
      studentId,
      paymentConfirmed: true,
    );

    final after =
        (await container.read(studentSubscriptionsProvider(studentId).future))
            .length;

    expect(
      after,
      before + 1,
      reason: '발급이 studentSubscriptions 를 무효화하지 않으면 화면이 stale (A2)',
    );
  });
}
