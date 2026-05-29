// #415 R4 — Billing feature 공개 API.
//
// 다른 feature 는 본 facade 만 import 한다 (presentation/data 직접 import 금지).

export 'billing_constants.dart' show proMonthlyProductId;
export 'data/services/iap_service.dart'
    show
        IapPurchaseCancelled,
        IapPurchaseFailure,
        IapPurchaseOutcome,
        IapPurchaseSuccess,
        IapService,
        StoreKitIapService;
export 'domain/entities/app_billing_snapshot.dart';
export 'domain/entities/billing_plan.dart';
export 'domain/entities/billing_status.dart';
export 'domain/entities/iap_validation_result.dart';
export 'domain/entities/trial_activation_result.dart';
export 'domain/repositories/app_billing_repository.dart';
export 'domain/services/billing_guard.dart';
export 'presentation/providers/app_billing_provider.dart'
    show
        appBillingRepositoryProvider,
        appBillingSnapshotProvider,
        iapServiceProvider;
export 'presentation/utils/billing_guard_actions.dart'
    show guardAddStudentNavigation;
export 'presentation/widgets/free_limit_sheet.dart'
    show FreeLimitSheet, showFreeLimitSheet;
