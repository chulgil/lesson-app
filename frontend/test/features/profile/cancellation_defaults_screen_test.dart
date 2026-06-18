import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';

import 'package:lessonaza/features/profile/data/repositories/mock_cancellation_defaults_repository.dart';
import 'package:lessonaza/features/profile/domain/entities/cancellation_defaults.dart';
import 'package:lessonaza/features/profile/presentation/providers/cancellation_defaults_provider.dart';
import 'package:lessonaza/features/profile/presentation/screens/cancellation_defaults_screen.dart';

void main() {
  group('CancellationDefaultsScreen', () {
    testWidgets('renders screen with default values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: CancellationDefaultsScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('취소 정책 기본값'), findsWidgets);
      // #801: 역할 안내 노트(취소/노쇼 정책 교차참조)가 표시된다.
      expect(find.textContaining('취소/노쇼 정책'), findsWidgets);
    });

    testWidgets('displays all 5 field sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: CancellationDefaultsScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('취소 페널티 없는 시간'), findsWidgets);
      expect(find.text('학생 취소 시 보상 제공'), findsWidgets);
      expect(find.text('마감 후 취소 시 알림 (학원 강사만)'), findsWidgets);

      expect(tester.takeException(), isNull);
    });

    testWidgets('compensation section is collapsible', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockCancellationDefaultsRepository(
        initialData: CancellationDefaults(
          id: 'teacher_001',
          cancellationDeadlineHours: 12,
          studentCompensationExtraMinutesEnabled: false,
          includeExtraMinutesTextOnLateCancel: true,
          studentCompensationExtraMinutesMessage: null,
          notifyOwnerOnLateCancel: false,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cancellationDefaultsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CancellationDefaultsScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('보상 메시지'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('smoke test - no render crashes', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: CancellationDefaultsScreen()),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(find.byType(SwitchListTile), findsWidgets);
    });
  });

  group('#801 디폴트→기본값 rename 가드', () {
    test('취소 정책 기본값 라벨/타이틀에 디폴트 미포함', () {
      expect(AppStrings.profileCancellationDefaultsLabel, '취소 정책 기본값');
      expect(AppStrings.profileCancellationDefaultsTitle, '취소 정책 기본값');
      expect(AppStrings.profileCancellationDefaultsLabel.contains('디폴트'), isFalse);
    });

    test('override 시트 기본값 사용 라벨', () {
      expect(AppStrings.subscriptionPolicyUsingDefault, '기본값 사용');
      expect(AppStrings.subscriptionPolicyUsingDefault.contains('디폴트'), isFalse);
    });
  });
}
