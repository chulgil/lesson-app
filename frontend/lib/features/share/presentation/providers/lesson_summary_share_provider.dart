import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_lesson_summary_share_repository.dart';
import '../../data/repositories/remote_lesson_summary_share_repository.dart';
import '../../domain/repositories/lesson_summary_share_repository.dart';

/// #808 — 레슨 요약 공유 토큰 repository provider. mock/remote 분기.
///
/// 단순 발급 API 1개라 codegen 대신 수동 Provider 로 둔다(기본 keepAlive).
final lessonSummaryShareRepositoryProvider =
    Provider<LessonSummaryShareRepository>(
      (ref) => createRepository<LessonSummaryShareRepository>(
        ref: ref,
        mock: () => MockLessonSummaryShareRepository(),
        remote: (apiClient) => RemoteLessonSummaryShareRepository(apiClient),
      ),
    );
