import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/router/routes/academy_routes.dart';
import 'package:lessonaza/features/academy/domain/entities/bulk_closure.dart';
import 'package:lessonaza/features/academy/domain/repositories/bulk_closure_repository.dart';
import 'package:lessonaza/features/academy/presentation/providers/bulk_closure_provider.dart';
import 'package:lessonaza/features/academy/presentation/screens/bulk_closure_detail_screen.dart';

/// Regression for #546 — 보강 일정 저장 NO-OP (silent data loss).
///
/// 강사가 보강 CTA 진입 → 시각 입력 → 전체 확정 시,
/// placeholder onSaveAll 대신 실제 [BulkClosureRepository.submitMakeupSchedule]
/// 가 호출되어야 한다. 버그 시점에는 토스트만 뜨고 아무것도 저장되지 않았다.
class _FakeBulkClosureRepository implements BulkClosureRepository {
  _FakeBulkClosureRepository(this._closure);

  BulkClosure _closure;

  /// 마지막 submitMakeupSchedule 호출 인자 (null = 미호출).
  Map<String, DateTime>? lastSavedMakeup;
  String? lastSavedClosureId;

  @override
  Future<List<BulkClosure>> listByTeacherMember(String teacherMemberId) async =>
      [_closure];

  @override
  Future<BulkClosure?> getById(String closureId) async =>
      closureId == _closure.id ? _closure : null;

  @override
  Future<void> submitTeacherOpinion(String closureId, String comment) async {
    _closure = _closure.copyWith(teacherComment: comment);
  }

  @override
  Future<void> submitMakeupSchedule(
    String closureId,
    Map<String, DateTime> makeupByLessonId,
  ) async {
    lastSavedClosureId = closureId;
    lastSavedMakeup = makeupByLessonId;
    final updated =
        _closure.affectedLessons.map((l) {
          final at = makeupByLessonId[l.lessonId];
          return at == null ? l : l.copyWith(makeupAt: at);
        }).toList();
    final allFilled = updated.every((l) => l.makeupAt != null);
    _closure = _closure.copyWith(
      affectedLessons: updated,
      status: allFilled ? ClosureStatus.makeupCompleted : _closure.status,
    );
  }
}

BulkClosure _appliedClosure() => BulkClosure(
  id: 'closure-1',
  academyId: 'academy-1',
  closureDate: DateTime(2026, 8, 15),
  reason: '공휴일 휴원',
  status: ClosureStatus.applied,
  appliedAt: DateTime(2026, 8, 14),
  affectedLessons: [
    AffectedLesson(
      lessonId: 'L1',
      studentId: 's1',
      studentName: '박학생',
      originalStartAt: DateTime(2026, 8, 15, 14, 0),
      originalEndAt: DateTime(2026, 8, 15, 15, 0),
    ),
  ],
);

void main() {
  testWidgets(
    'makeup confirm saves through repository (regression #546 — no silent loss)',
    (tester) async {
      final fakeRepo = _FakeBulkClosureRepository(_appliedClosure());

      final router = GoRouter(
        initialLocation: '/academy/academy-1/closures/closure-1',
        routes: [
          GoRoute(
            path: AppRoutes.academyBulkClosureDetail,
            builder:
                (context, state) => const BulkClosureDetailScreen(
                  closureId: 'closure-1',
                  teacherMemberId: 'tm-1',
                ),
          ),
          ...academyRoutes,
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bulkClosureRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // 보강 입력 화면으로 진입.
      await tester.tap(find.text('보강 일정 입력하기'));
      await tester.pumpAndSettle();

      // 시각 선택: 날짜 picker OK → 시간 picker OK.
      await tester.tap(find.byType(OutlinedButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 전체 확정 → 실제 저장 경로 호출되어야 함.
      await tester.tap(find.text('전체 확정'));
      await tester.pumpAndSettle();

      // #829 확인 요약 다이얼로그(NotebookAlertDialog) → confirm('전체 확정')
      // 탭해야 submitMakeupSchedule 저장. (하단 버튼과 동일 라벨이라 .last)
      await tester.tap(find.text('전체 확정').last);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastSavedMakeup, isNotNull,
          reason: 'submitMakeupSchedule must be invoked on confirm');
      expect(fakeRepo.lastSavedClosureId, 'closure-1');
      expect(fakeRepo.lastSavedMakeup!.containsKey('L1'), isTrue);
    },
  );
}
