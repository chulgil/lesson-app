import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_growth_report_share_repository.dart';
import '../../data/repositories/remote_growth_report_share_repository.dart';
import '../../domain/repositories/growth_report_share_repository.dart';

/// #1217 — 자녀 성장 리포트 공유 토큰 repository provider. mock/remote 분기.
///
/// 단순 발급 API 1개라 codegen 대신 수동 Provider 로 둔다(기본 keepAlive).
final growthReportShareRepositoryProvider =
    Provider<GrowthReportShareRepository>(
      (ref) => createRepository<GrowthReportShareRepository>(
        ref: ref,
        mock: () => MockGrowthReportShareRepository(),
        remote: (apiClient) => RemoteGrowthReportShareRepository(apiClient),
      ),
    );
