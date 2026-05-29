// #415 R4 — 앱 결제 스냅샷 provider.
//
// Phase A: 스냅샷 read-only.
// Phase C: IapService provider (in_app_purchase wrap) 추가 — 테스트는 override.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_app_billing_repository.dart';
import '../../data/repositories/remote_app_billing_repository.dart';
import '../../data/services/iap_service.dart';
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

/// StoreKit2 / PlayBilling wrap.
///
/// 테스트는 [FakeIapService] 또는 mocktail 로 override. production 은
/// [StoreKitIapService] 하나만 사용 (in_app_purchase 패키지가 플랫폼 분기 담당).
final iapServiceProvider = Provider<IapService>((ref) {
  return StoreKitIapService();
});
