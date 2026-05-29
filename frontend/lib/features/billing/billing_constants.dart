// #415 R4 Phase C — Billing 상수.
//
// Store product ID 는 App Store Connect / Google Play Console 의 상품 ID 와
// 1:1 일치해야 한다 (apple-app-account-token / SKU). 변경 시 spec 갱신 필수.
// spec: docs/specs/subscription/paywall_spec.md §1 (Plans).

/// Pro 월간 구독 상품 ID.
///
/// - iOS: App Store Connect → In-App Purchases → Product ID
/// - Android: Play Console → 구독 → 기본 BasePlan ID
///
/// 백엔드 `IapValidateRequest.product_id` 와 정확히 일치해야 한다.
const String proMonthlyProductId = 'pro_monthly';
