// #415 R4 — 앱 결제 스냅샷 provider.
//
// Phase A 는 read-only. trial 시작/IAP 검증은 Phase B/C 에서 notifier 로 확장.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_app_billing_repository.dart';
import '../../data/repositories/remote_app_billing_repository.dart';
import '../../domain/entities/app_billing_snapshot.dart';
import '../../domain/repositories/app_billing_repository.dart';

/// AppBillingRepository — mock/remote 자동 분기.
final appBillingRepositoryProvider = Provider<AppBillingRepository>((ref) {
  return createRepository<AppBillingRepository>(
    ref: ref,
    mock: () => MockAppBillingRepository(),
    remote: (apiClient) => RemoteAppBillingRepository(apiClient),
  );
});

/// 현재 선생님의 결제 스냅샷.
final appBillingSnapshotProvider = FutureProvider<AppBillingSnapshot>((
  ref,
) async {
  final repo = ref.watch(appBillingRepositoryProvider);
  return repo.fetchSnapshot();
});
