import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/router/routes/student_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/students/domain/entities/teacher_announcement.dart';
import 'package:lessonaza/features/students/domain/repositories/teacher_announcement_repository.dart';
import 'package:lessonaza/features/students/presentation/providers/teacher_announcement_providers.dart';
import 'package:lessonaza/features/students/presentation/screens/announcement_history_screen.dart';
import 'package:lessonaza/features/students/presentation/screens/student_detail_screen.dart';

/// Route-shadowing regression gate (수강관리 공지 아이콘 → 학생 상세 오배송).
///
/// `/students/announcement-history` was declared AFTER `/students/:id`, so
/// go_router (first-match-wins, declaration order) resolved it to
/// StudentDetailScreen(studentId: 'announcement-history'). The static route
/// scan in route_integrity_test.dart cannot catch this class — the target IS
/// registered, just shadowed — so this file asserts runtime resolution and
/// the ordering invariant directly.
class _FakeAnnouncementRepository implements TeacherAnnouncementRepository {
  @override
  Future<TeacherAnnouncement> create(TeacherAnnouncement announcement) async =>
      announcement;

  @override
  Future<List<TeacherAnnouncement>> getByTeacherId(String teacherId) async =>
      const [];

  @override
  Future<TeacherAnnouncement> update(TeacherAnnouncement announcement) async =>
      announcement;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<DateTime>> getDayOffs({
    required String teacherId,
    required DateTime from,
    required DateTime to,
  }) async => const [];
}

void main() {
  testWidgets('announcement-history resolves to AnnouncementHistoryScreen, '
      'not StudentDetailScreen', (tester) async {
    final router = GoRouter(
      routes: studentRoutes,
      initialLocation: AppRoutes.announcementHistory,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('t1'),
          teacherAnnouncementRepositoryProvider.overrideWithValue(
            _FakeAnnouncementRepository(),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    // Two plain pumps (not pumpAndSettle): if the route mis-resolves to
    // StudentDetailScreen its providers never settle in this harness.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AnnouncementHistoryScreen), findsOneWidget);
    expect(find.byType(StudentDetailScreen), findsNothing);
  });

  test('static /students/* routes are declared before /students/:id '
      '(shadowing invariant)', () {
    final paths = studentRoutes.map((r) => r.path).toList();
    final detailIndex = paths.indexOf(AppRoutes.studentDetail);
    expect(detailIndex, isNot(-1));

    final staticStudentPaths = paths.where(
      (p) =>
          p != AppRoutes.studentDetail &&
          RegExp(r'^/students/[^:/]+$').hasMatch(p),
    );
    for (final path in staticStudentPaths) {
      expect(
        paths.indexOf(path),
        lessThan(detailIndex),
        reason:
            '$path is shadowed by ${AppRoutes.studentDetail} — go_router '
            'matches in declaration order, so static /students/* routes '
            'must be declared before the :id route.',
      );
    }
  });
}
