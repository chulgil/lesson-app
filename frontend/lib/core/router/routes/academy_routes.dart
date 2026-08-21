// Academy route definitions
//
// G15 일괄 휴강 강사 시점 + 활동 타임라인.
// 정책 SSOT: docs/specs/web/academy/owner_bulk_closure_spec.md §5,
// docs/specs/academy/academy_master.md §6.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/notebook/notebook_surfaces.dart';
import '../../../features/academy/domain/entities/bulk_closure.dart';
import '../../../features/academy/presentation/providers/bulk_closure_provider.dart';
import '../../../features/academy/presentation/screens/academy_activity_timeline_screen.dart';
import '../../../features/academy/presentation/screens/bulk_closure_detail_screen.dart';
import '../../../features/schedule/presentation/screens/makeup_lesson_input_screen.dart';
import '../app_routes.dart';
import '../../l10n/generated/app_localizations.dart';

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
        return NotebookScreenScaffold(
          body: Center(
            child: Text(AppLocalizations.of(context).academyClosureLoadError),
          ),
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
      // 진입 부모(BulkClosureDetailScreen)가 closure + teacherMemberId 를
      // [MakeupRouteExtra] 로 전달한다. 실제 저장은 BulkClosureNotifier 가
      // 수행하며, router 빌더가 ProviderScope 를 통해 호출한다 (placeholder 금지).
      final extra = state.extra;
      if (extra is! MakeupRouteExtra) {
        return NotebookScreenScaffold(
          body: Center(
            child: Text(AppLocalizations.of(context).academyClosureLoadError),
          ),
        );
      }
      final container = ProviderScope.containerOf(context);
      return MakeupLessonInputScreen(
        closure: extra.closure,
        onSaveAll: (Map<String, DateTime> makeupByLessonId) async {
          await container
              .read(bulkClosureNotifierProvider.notifier)
              .submitMakeupSchedule(
                closureId: extra.closure.id,
                makeupByLessonId: makeupByLessonId,
                teacherMemberId: extra.teacherMemberId,
              );
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
