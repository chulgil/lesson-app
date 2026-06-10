import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/swipe_action_tile.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/time_exception_screen.dart';

/// Widget smoke + behavior tests for TimeExceptionScreen.
///
/// Covers swipe consistency audit (2026-06-10):
/// - 휴무 카드는 SwipeActionTile 로 destructive 단일 액션 노출
/// - trailing IconButton 과 중복 배치 없음 (audit §2 원칙 1)
void main() {
  const teacherId = 'teacher_swipe';
  // 화면이 DateTime.now() 로 upcoming/past 분류하므로 테스트도 현재 시각 기준으로 만든다.
  final referenceDay = DateTime.now();

  Future<void> pumpScreen(
    WidgetTester tester, {
    required TeacherAvailability availability,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => teacherId),
          teacherAvailabilityProvider(
            teacherId,
          ).overrideWith((ref) async => availability),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const TimeExceptionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  TeacherAvailability buildAvailability(List<TimeException> exceptions) {
    return TeacherAvailability(
      id: 'availability_$teacherId',
      teacherId: teacherId,
      createdAt: referenceDay,
      exceptions: exceptions,
    );
  }

  testWidgets('renders without crash and shows SwipeActionTile for upcoming', (
    tester,
  ) async {
    final upcoming = TimeException(
      id: 'ex_upcoming',
      type: ExceptionType.vacation,
      startDate: referenceDay.add(const Duration(days: 7)),
      endDate: referenceDay.add(const Duration(days: 10)),
      createdAt: referenceDay,
    );
    await pumpScreen(tester, availability: buildAvailability([upcoming]));

    expect(tester.takeException(), isNull);
    expect(find.byType(SwipeActionTile), findsOneWidget);
    // 중복 액션 금지: 카드(ListTile) 내부에는 trailing IconButton 이 없어야 한다.
    // AppBar 의 add IconButton 등 화면 다른 영역의 IconButton 은 허용.
    final trailingIconButton = find.descendant(
      of: find.byType(ListTile),
      matching: find.byType(IconButton),
    );
    expect(
      trailingIconButton,
      findsNothing,
      reason: 'trailing IconButton 은 SwipeAction 으로 통일되어야 한다.',
    );
    // destructive 액션의 휴지통 아이콘은 swipe reveal 안에서 표시 (초기에는 숨김).
    // 카드 내부 ListTile 에 직접 표시되는 휴지통 아이콘이 없는지 확인.
    final cardDeleteIcon = find.descendant(
      of: find.byType(ListTile),
      matching: find.byIcon(Icons.delete_outline),
    );
    expect(
      cardDeleteIcon,
      findsNothing,
      reason: '카드 본문에 휴지통 아이콘 잔재 없음 (swipe reveal 로만 노출).',
    );
  });

  testWidgets('past exception 은 SwipeActionTile 없이 렌더링', (tester) async {
    final past = TimeException(
      id: 'ex_past',
      type: ExceptionType.holiday,
      startDate: referenceDay.subtract(const Duration(days: 14)),
      endDate: referenceDay.subtract(const Duration(days: 13)),
      createdAt: referenceDay.subtract(const Duration(days: 20)),
    );
    await pumpScreen(tester, availability: buildAvailability([past]));

    expect(tester.takeException(), isNull);
    expect(find.byType(SwipeActionTile), findsNothing);
    expect(find.text(AppStrings.pastExceptions), findsOneWidget);
  });
}
