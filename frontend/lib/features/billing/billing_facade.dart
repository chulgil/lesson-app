// #415 R4 — Billing feature 공개 API.
//
// 다른 feature 는 본 facade 만 import 한다 (presentation/data 직접 import 금지).

export 'domain/entities/app_billing_snapshot.dart';
export 'domain/entities/billing_plan.dart';
export 'domain/entities/billing_status.dart';
export 'domain/repositories/app_billing_repository.dart';
export 'domain/services/billing_guard.dart';
export 'presentation/providers/app_billing_provider.dart'
    show appBillingRepositoryProvider, appBillingSnapshotProvider;
