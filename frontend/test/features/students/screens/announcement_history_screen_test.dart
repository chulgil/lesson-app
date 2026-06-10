import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/students/domain/entities/teacher_announcement.dart';
import 'package:lessonaza/features/students/domain/repositories/teacher_announcement_repository.dart';
import 'package:lessonaza/features/students/presentation/providers/teacher_announcement_providers.dart';
import 'package:lessonaza/features/students/presentation/screens/announcement_history_screen.dart';

/// Widget smoke test (HARD-GATE) for [AnnouncementHistoryScreen]
/// (issue #669 — swipe consistency v2 D7).
///
/// Verifies:
/// - The popup menu (편집/삭제) is gone — replaced with row-tap (편집) +
///   SwipeActionTile [삭제] (3원칙 ①, ②).
/// - Renders without RenderBox / BoxConstraints crash.
class _FakeAnnouncementRepository implements TeacherAnnouncementRepository {
  _FakeAnnouncementRepository(this._items);

  final List<TeacherAnnouncement> _items;
  final List<String> deletedIds = <String>[];

  @override
  Future<TeacherAnnouncement> create(TeacherAnnouncement announcement) async =>
      announcement;

  @override
  Future<List<TeacherAnnouncement>> getByTeacherId(String teacherId) async =>
      _items;

  @override
  Future<TeacherAnnouncement> update(TeacherAnnouncement announcement) async =>
      announcement;

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
  }

  @override
  Future<List<DateTime>> getDayOffs({
    required String teacherId,
    required DateTime from,
    required DateTime to,
  }) async => const [];
}

void main() {
  TeacherAnnouncement fakeAnnouncement() => TeacherAnnouncement(
    id: 'a_test_1',
    teacherId: 't1',
    type: AnnouncementType.general,
    dates: const [],
    message: '6월 둘째 주 일정 안내드립니다.',
    createdAt: DateTime(2026, 6, 1),
  );

  testWidgets('AnnouncementHistoryScreen renders without popup menu', (
    tester,
  ) async {
    final repo = _FakeAnnouncementRepository([fakeAnnouncement()]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('t1'),
          teacherAnnouncementRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AnnouncementHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('6월 둘째 주 일정 안내드립니다.'), findsOneWidget);

    // PopupMenuButton (more_vert) 가 사라졌는지 확인.
    expect(find.byIcon(Icons.more_vert), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AnnouncementHistoryScreen swipe reveals destructive [삭제] action',
    (tester) async {
      final repo = _FakeAnnouncementRepository([fakeAnnouncement()]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('t1'),
            teacherAnnouncementRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const AnnouncementHistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag the announcement card to reveal swipe action.
      await tester.drag(find.text('6월 둘째 주 일정 안내드립니다.'), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.swipeActionDelete), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );
}
