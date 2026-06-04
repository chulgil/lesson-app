// Academy route definitions
//
// G15 일괄 휴강 강사 시점 + 활동 타임라인.
// 정책 SSOT: docs/specs/web/academy/owner_bulk_closure_spec.md §5,
// docs/specs/academy/academy_master.md §6.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/notebook/notebook_surfaces.dart';
import '../../../features/academy/domain/entities/bulk_closure.dart';
import '../../../features/academy/presentation/screens/academy_activity_timeline_screen.dart';
import '../../../features/academy/presentation/screens/bulk_closure_detail_screen.dart';
import '../../../features/schedule/presentation/screens/makeup_lesson_input_screen.dart';
import '../app_routes.dart';

/// Academy routes (G15 일괄 휴강 + 활동 타임라인).
///
/// 기존 academy 진입 라우트(초대 수락/공지/문의)는 각각
/// `auth_routes.dart`, `notification_routes.dart` 에 분산되어 있다.
/// 본 파일은 academy feature 자체가 화면을 소유한 경로만 모은다.
List<GoRoute> academyRoutes = [
  // 강사 시점 — 학원장이 발동한 휴강 상세 (의견 입력 + 보강 입력 진입)
  GoRoute(
    path: AppRoutes.academyBulkClosureDetail,
    name: 'academyBulkClosureDetail',
    builder: (context, state) {
      final closureId = state.pathParameters['closureId'] ?? '';
      final teacherMemberId =
          (state.uri.queryParameters['teacherMemberId'] ?? '').trim();
      if (closureId.isEmpty) {
        return const NotebookScreenScaffold(
          body: Center(child: Text('휴강 정보를 불러올 수 없습니다.')),
        );
      }
      return BulkClosureDetailScreen(
        closureId: closureId,
        teacherMemberId: teacherMemberId,
      );
    },
  ),

  // 강사 시점 — 적용된 휴강의 영향 레슨에 보강 일정 일괄 입력
  GoRoute(
    path: AppRoutes.academyMakeupInput,
    name: 'academyMakeupInput',
    builder: (context, state) {
      final extra = state.extra;
      if (extra is! BulkClosure) {
        return const NotebookScreenScaffold(
          body: Center(child: Text('휴강 정보를 불러올 수 없습니다.')),
        );
      }
      return MakeupLessonInputScreen(
        closure: extra,
        // 저장 콜백은 router 가 직접 책임 — push 한 화면이
        // pop 후 부모(BulkClosureDetail)가 invalidate 함.
        onSaveAll: (Map<String, DateTime> makeupByLessonId) async {
          // 실제 저장은 BulkClosureNotifier 가 수행 — 진입 부모에서 처리.
          // 본 라우트 빌더는 Repository 호출 책임을 가지지 않는다.
          //
          // 따라서 BulkClosureDetailScreen 에서 push 할 때 onSaveAll 을
          // 갈아끼우거나, 본 화면을 ProviderScope 안에서 ConsumerWidget 으로
          // 직접 호출하는 방식으로 확장한다. 현 시점은 placeholder.
        },
      );
    },
  ),

  // 강사 시점 — 학원 내 본인 활동 로그 타임라인
  GoRoute(
    path: AppRoutes.academyActivityTimeline,
    name: 'academyActivityTimeline',
    builder: (context, state) {
      final academyId = state.pathParameters['academyId'] ?? '';
      final actorMemberId = state.pathParameters['actorMemberId'] ?? '';
      final actorName = state.uri.queryParameters['actorName'] ?? '';
      return AcademyActivityTimelineScreen(
        academyId: academyId,
        actorMemberId: actorMemberId,
        actorName: actorName,
      );
    },
  ),
];
