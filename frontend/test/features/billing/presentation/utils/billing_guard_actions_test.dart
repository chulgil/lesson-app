// #415 R4 Phase B/C — guardAddStudentNavigation + Pro 구매 + Trial 시작.
//
// Phase B: 가드 분기 (allowed → onPass, blocked → sheet 노출).
// Phase C: handleBuyPro / handleStartTrial — IAP/trial 결과별 SnackBar 안내.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/billing/billing_constants.dart';
import 'package:lessonaza/features/billing/data/services/iap_service.dart';
import 'package:lessonaza/features/billing/domain/entities/app_billing_snapshot.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_plan.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_status.dart';
import 'package:lessonaza/features/billing/domain/entities/iap_validation_result.dart';
import 'package:lessonaza/features/billing/domain/entities/trial_activation_result.dart';
import 'package:lessonaza/features/billing/domain/repositories/app_billing_repository.dart';
import 'package:lessonaza/features/billing/domain/services/billing_guard.dart';
import 'package:lessonaza/features/billing/presentation/providers/app_billing_provider.dart';
import 'package:lessonaza/features/billing/presentation/utils/billing_guard_actions.dart';
import 'package:lessonaza/features/billing/presentation/widgets/free_limit_sheet.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/domain/repositories/student_repository.dart';
import 'package:lessonaza/features/students/presentation/providers/student_repository_provider.dart';

class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository(this._count);
  final int _count;

  @override
  Future<List<Student>> getStudents() async {
    return List.generate(
      _count,
      (i) => Student(
        id: 's$i',
        name: 'student_$i',
        instrument: 'violin',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AppBillingSnapshot _snapshot({
  required BillingPlan plan,
  required BillingStatus status,
  bool trialUsed = false,
}) {
  return AppBillingSnapshot(
    id: 'p',
    userId: 'u',
    plan: plan,
    status: status,
    startedAt: DateTime.utc(2026, 1, 1),
    expiresAt: null,
    source: 'test',
    originalTransactionId: null,
    trialUsed: trialUsed,
  );
}

Widget _harness({
  required AppBillingSnapshot snapshot,
  required int studentCount,
  required void Function(BuildContext, WidgetRef) onTap,
  _FakeBillingRepository? repository,
  IapService? iapService,
}) {
  return ProviderScope(
    overrides: [
      appBillingRepositoryProvider.overrideWithValue(
        repository ?? _FakeBillingRepository(snapshot),
      ),
      studentRepositoryProvider.overrideWithValue(
        _FakeStudentRepository(studentCount),
      ),
      if (iapService != null) iapServiceProvider.overrideWithValue(iapService),
    ],
    child: MaterialApp(
      home: Consumer(
        builder: (context, ref, _) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => onTap(context, ref),
                child: const Text('go'),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _FakeBillingRepository implements AppBillingRepository {
  _FakeBillingRepository(
    this._snapshot, {
    this.startTrialResult,
    this.validatePurchaseResult,
    this.startTrialError,
    this.validatePurchaseError,
  });

  final AppBillingSnapshot _snapshot;
  final TrialActivationResult? startTrialResult;
  final IapValidationResult? validatePurchaseResult;
  final Object? startTrialError;
  final Object? validatePurchaseError;

  int startTrialCalls = 0;
  int validatePurchaseCalls = 0;
  String? lastReceipt;
  String? lastPlatform;

  @override
  Future<AppBillingSnapshot> fetchSnapshot() async => _snapshot;

  @override
  Future<TrialActivationResult> startTrial() async {
    startTrialCalls++;
    if (startTrialError != null) throw startTrialError!;
    return startTrialResult ??
        const TrialActivationResult(
          success: true,
          message: 'mock_trial_started',
        );
  }

  @override
  Future<IapValidationResult> validatePurchase({
    required String platform,
    required String receipt,
    required String productId,
  }) async {
    validatePurchaseCalls++;
    lastPlatform = platform;
    lastReceipt = receipt;
    if (validatePurchaseError != null) throw validatePurchaseError!;
    return validatePurchaseResult ??
        const IapValidationResult(granted: true, message: 'ok');
  }
}

/// 테스트용 IapService. outcomes/products/available 를 주입.
class FakeIapService implements IapService {
  FakeIapService({
    this.available = true,
    this.products = const [],
    this.outcome = const IapPurchaseFailure('not_set'),
    this.platformName = 'apple',
  });

  bool available;
  List<ProductDetails> products;
  IapPurchaseOutcome outcome;
  final String platformName;

  int completePurchaseCalls = 0;

  @override
  String get platform => platformName;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<ProductDetails>> queryProducts(Set<String> productIds) async =>
      products;

  @override
  Future<IapPurchaseOutcome> purchase(ProductDetails product) async => outcome;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completePurchaseCalls++;
  }
}

/// 단위 테스트용 PurchaseDetails. verificationData 의 server token 만 사용.
PurchaseDetails _purchaseDetails({
  required String productId,
  required String receipt,
}) {
  return PurchaseDetails(
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: receipt,
      serverVerificationData: receipt,
      source: 'apple',
    ),
    transactionDate: '2026-05-29T00:00:00Z',
    status: PurchaseStatus.purchased,
  );
}

ProductDetails _productDetails(String id) {
  return ProductDetails(
    id: id,
    title: 'Pro 월간',
    description: '학생 무제한',
    price: '₩9,900',
    rawPrice: 9900,
    currencyCode: 'KRW',
  );
}

/// 표준 테스트 surface(800x600) 는 BottomSheet 내용을 다 못 담아 RenderFlex
/// overflow 가 난다. 모바일 세로 사이즈로 키워 sheet 가 정상 렌더되도록 한다.
Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('guardAddStudentNavigation (Phase B)', () {
    testWidgets('free + count < 5 → onPass 즉시 실행, sheet 미노출', (tester) async {
      await _useTallSurface(tester);
      var pass = 0;
      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 3,
          onTap: (ctx, ref) async {
            await guardAddStudentNavigation(
              context: ctx,
              ref: ref,
              onPass: () => pass++,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(pass, 1);
      expect(find.byKey(FreeLimitSheet.buyProButtonKey), findsNothing);
    });

    testWidgets('free + count == 5 → sheet 노출, onPass 미실행', (tester) async {
      await _useTallSurface(tester);
      var pass = 0;
      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 5,
          onTap: (ctx, ref) async {
            await guardAddStudentNavigation(
              context: ctx,
              ref: ref,
              onPass: () => pass++,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(pass, 0);
      expect(find.text(AppStrings.paywallFreeLimitTitle), findsOneWidget);
      expect(find.byKey(FreeLimitSheet.buyProButtonKey), findsOneWidget);

      await tester.tap(find.byKey(FreeLimitSheet.laterButtonKey));
      await tester.pumpAndSettle();
      expect(pass, 0);
    });

    testWidgets('pro 무제한 → 개수 무관 통과', (tester) async {
      await _useTallSurface(tester);
      var pass = 0;
      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.pro,
            status: BillingStatus.active,
          ),
          studentCount: 50,
          onTap: (ctx, ref) async {
            await guardAddStudentNavigation(
              context: ctx,
              ref: ref,
              onPass: () => pass++,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(pass, 1);
    });

    testWidgets('expired → 만료 sheet 노출 (trial 카드 숨김)', (tester) async {
      await _useTallSurface(tester);
      var pass = 0;
      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.pro,
            status: BillingStatus.expired,
          ),
          studentCount: 10,
          onTap: (ctx, ref) async {
            await guardAddStudentNavigation(
              context: ctx,
              ref: ref,
              onPass: () => pass++,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(pass, 0);
      expect(find.text(AppStrings.paywallPlanExpiredTitle), findsOneWidget);
      expect(find.byKey(FreeLimitSheet.startTrialButtonKey), findsNothing);
    });
  });

  group('guardProFeatureNavigation (Phase A1 #415)', () {
    testWidgets('pro + active, required=pro → onPass 실행, sheet 미노출', (
      tester,
    ) async {
      await _useTallSurface(tester);
      var pass = 0;
      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.pro,
            status: BillingStatus.active,
          ),
          studentCount: 0,
          onTap: (ctx, ref) {
            guardProFeatureNavigation(
              context: ctx,
              ref: ref,
              required: TierRequirement.pro,
              featureName: AppStrings.featureLockedMonthlyStats,
              onPass: () => pass++,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(pass, 1);
      expect(find.text(AppStrings.featureLockedProTitle), findsNothing);
    });

    testWidgets(
      'free, required=pro → FeatureLockedSheet 노출 (tierTooLow), onPass 미호출',
      (tester) async {
        await _useTallSurface(tester);
        var pass = 0;
        await tester.pumpWidget(
          _harness(
            snapshot: _snapshot(
              plan: BillingPlan.free,
              status: BillingStatus.active,
            ),
            studentCount: 0,
            onTap: (ctx, ref) {
              guardProFeatureNavigation(
                context: ctx,
                ref: ref,
                required: TierRequirement.pro,
                featureName: AppStrings.featureLockedMonthlyStats,
                onPass: () => pass++,
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();

        expect(pass, 0);
        expect(find.text(AppStrings.featureLockedProTitle), findsOneWidget);
        // sheet 본문에 featureName prefix 가 노출되어야 한다.
        expect(
          find.textContaining(AppStrings.featureLockedMonthlyStats),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'pro + expired, required=pro → planExpired sheet 노출, onPass 미호출',
      (tester) async {
        await _useTallSurface(tester);
        var pass = 0;
        await tester.pumpWidget(
          _harness(
            snapshot: _snapshot(
              plan: BillingPlan.pro,
              status: BillingStatus.expired,
            ),
            studentCount: 0,
            onTap: (ctx, ref) {
              guardProFeatureNavigation(
                context: ctx,
                ref: ref,
                required: TierRequirement.pro,
                featureName: AppStrings.featureLockedMonthlyStats,
                onPass: () => pass++,
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();

        expect(pass, 0);
        expect(find.text(AppStrings.featureLockedProTitle), findsOneWidget);
      },
    );

    testWidgets('studio + active, required=pro → onPass 실행 (상위 tier)', (
      tester,
    ) async {
      await _useTallSurface(tester);
      var pass = 0;
      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.studio,
            status: BillingStatus.active,
          ),
          studentCount: 0,
          onTap: (ctx, ref) {
            guardProFeatureNavigation(
              context: ctx,
              ref: ref,
              required: TierRequirement.pro,
              featureName: AppStrings.featureLockedMonthlyStats,
              onPass: () => pass++,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(pass, 1);
    });

    testWidgets(
      'lifetime, required=studio → Studio sheet 노출 (lifetime != studio)',
      (tester) async {
        await _useTallSurface(tester);
        var pass = 0;
        await tester.pumpWidget(
          _harness(
            snapshot: _snapshot(
              plan: BillingPlan.lifetime,
              status: BillingStatus.active,
            ),
            studentCount: 0,
            onTap: (ctx, ref) {
              guardProFeatureNavigation(
                context: ctx,
                ref: ref,
                required: TierRequirement.studio,
                featureName: '학원 다중 강사',
                onPass: () => pass++,
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();

        expect(pass, 0);
        expect(find.text(AppStrings.featureLockedStudioTitle), findsOneWidget);
      },
    );

    testWidgets('snapshot 로딩 실패 → fail-open, onPass 실행 (server SSOT 정책)', (
      tester,
    ) async {
      await _useTallSurface(tester);
      var pass = 0;
      final repo = _FakeBillingRepository(
        _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appBillingRepositoryProvider.overrideWithValue(repo),
            studentRepositoryProvider.overrideWithValue(
              _FakeStudentRepository(0),
            ),
            appBillingSnapshotProvider.overrideWith(
              (ref) => Future<AppBillingSnapshot>.error(
                Exception('snapshot load failed'),
              ),
            ),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed:
                          () => guardProFeatureNavigation(
                            context: context,
                            ref: ref,
                            required: TierRequirement.pro,
                            featureName: AppStrings.featureLockedMonthlyStats,
                            onPass: () => pass++,
                          ),
                      child: const Text('go'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      // fail-open: 차단하지 않고 onPass 실행. 백엔드가 server-side 가드.
      expect(pass, 1);
      expect(find.text(AppStrings.featureLockedProTitle), findsNothing);
    });
  });

  group('handleBuyPro (Phase C)', () {
    testWidgets('store unavailable → 안내 SnackBar, 검증 미호출', (tester) async {
      await _useTallSurface(tester);
      final repo = _FakeBillingRepository(
        _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
      );
      final iap = FakeIapService(available: false);

      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 0,
          repository: repo,
          iapService: iap,
          onTap: (ctx, ref) async {
            await handleBuyPro(context: ctx, ref: ref);
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.paywallStoreUnavailable), findsOneWidget);
      expect(repo.validatePurchaseCalls, 0);
    });

    testWidgets('product 조회 0건 → product_not_found SnackBar', (tester) async {
      await _useTallSurface(tester);
      final repo = _FakeBillingRepository(
        _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
      );
      final iap = FakeIapService(products: const []);

      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 0,
          repository: repo,
          iapService: iap,
          onTap: (ctx, ref) async {
            await handleBuyPro(context: ctx, ref: ref);
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.paywallProductNotFound), findsOneWidget);
      expect(repo.validatePurchaseCalls, 0);
    });

    testWidgets('구매 취소 → cancelled SnackBar', (tester) async {
      await _useTallSurface(tester);
      final repo = _FakeBillingRepository(
        _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
      );
      final iap = FakeIapService(
        products: [_productDetails(proMonthlyProductId)],
        outcome: const IapPurchaseCancelled(),
      );

      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 0,
          repository: repo,
          iapService: iap,
          onTap: (ctx, ref) async {
            await handleBuyPro(context: ctx, ref: ref);
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.paywallPurchaseCancelled), findsOneWidget);
      expect(repo.validatePurchaseCalls, 0);
      expect(iap.completePurchaseCalls, 0);
    });

    testWidgets('구매 실패 (store error) → failed SnackBar', (tester) async {
      await _useTallSurface(tester);
      final repo = _FakeBillingRepository(
        _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
      );
      final iap = FakeIapService(
        products: [_productDetails(proMonthlyProductId)],
        outcome: const IapPurchaseFailure('store_error'),
      );

      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 0,
          repository: repo,
          iapService: iap,
          onTap: (ctx, ref) async {
            await handleBuyPro(context: ctx, ref: ref);
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.paywallPurchaseFailed), findsOneWidget);
      expect(repo.validatePurchaseCalls, 0);
      expect(iap.completePurchaseCalls, 0);
    });

    testWidgets(
      '구매 성공 + 검증 granted → success SnackBar + complete + receipt 전송',
      (tester) async {
        await _useTallSurface(tester);
        final repo = _FakeBillingRepository(
          _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
          validatePurchaseResult: const IapValidationResult(
            granted: true,
            message: 'ok',
            planId: 'plan-1',
            tier: 'pro',
          ),
        );
        final iap = FakeIapService(
          products: [_productDetails(proMonthlyProductId)],
          outcome: IapPurchaseSuccess(
            _purchaseDetails(
              productId: proMonthlyProductId,
              receipt: 'apple-receipt-xyz',
            ),
          ),
          platformName: 'apple',
        );

        await tester.pumpWidget(
          _harness(
            snapshot: _snapshot(
              plan: BillingPlan.free,
              status: BillingStatus.active,
            ),
            studentCount: 0,
            repository: repo,
            iapService: iap,
            onTap: (ctx, ref) async {
              await handleBuyPro(context: ctx, ref: ref);
            },
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.paywallPurchaseSuccess), findsOneWidget);
        expect(repo.validatePurchaseCalls, 1);
        expect(repo.lastPlatform, 'apple');
        expect(repo.lastReceipt, 'apple-receipt-xyz');
        expect(iap.completePurchaseCalls, 1);
      },
    );

    testWidgets('구매 성공 + 검증 pending → pending SnackBar + complete 호출', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final repo = _FakeBillingRepository(
        _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
        validatePurchaseResult: const IapValidationResult(
          granted: false,
          message: 'pending_validation',
        ),
      );
      final iap = FakeIapService(
        products: [_productDetails(proMonthlyProductId)],
        outcome: IapPurchaseSuccess(
          _purchaseDetails(
            productId: proMonthlyProductId,
            receipt: 'apple-receipt-pending',
          ),
        ),
      );

      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 0,
          repository: repo,
          iapService: iap,
          onTap: (ctx, ref) async {
            await handleBuyPro(context: ctx, ref: ref);
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.paywallPurchasePending), findsOneWidget);
      expect(iap.completePurchaseCalls, 1);
    });

    testWidgets('구매 성공 + 백엔드 검증 예외 → failed SnackBar + complete 미호출', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final repo = _FakeBillingRepository(
        _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
        validatePurchaseError: Exception('network'),
      );
      final iap = FakeIapService(
        products: [_productDetails(proMonthlyProductId)],
        outcome: IapPurchaseSuccess(
          _purchaseDetails(
            productId: proMonthlyProductId,
            receipt: 'apple-receipt-fail',
          ),
        ),
      );

      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 0,
          repository: repo,
          iapService: iap,
          onTap: (ctx, ref) async {
            await handleBuyPro(context: ctx, ref: ref);
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.paywallPurchaseFailed), findsOneWidget);
      expect(iap.completePurchaseCalls, 0);
    });
  });

  group('handleStartTrial (Phase C)', () {
    testWidgets('성공 → started SnackBar', (tester) async {
      await _useTallSurface(tester);
      final repo = _FakeBillingRepository(
        _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
        startTrialResult: TrialActivationResult(
          success: true,
          message: 'trial_started',
          planId: 'plan-1',
          expiresAt: DateTime.utc(2026, 6, 12),
        ),
      );

      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 0,
          repository: repo,
          onTap: (ctx, ref) async {
            await handleStartTrial(context: ctx, ref: ref);
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.paywallTrialStarted), findsOneWidget);
      expect(repo.startTrialCalls, 1);
    });

    testWidgets('이미 사용 (409 → success=false) → already_used SnackBar', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final repo = _FakeBillingRepository(
        _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
        startTrialResult: const TrialActivationResult(
          success: false,
          message: 'trial_already_used',
        ),
      );

      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 0,
          repository: repo,
          onTap: (ctx, ref) async {
            await handleStartTrial(context: ctx, ref: ref);
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.paywallTrialAlreadyUsed), findsOneWidget);
    });

    testWidgets('예외 → failed SnackBar', (tester) async {
      await _useTallSurface(tester);
      final repo = _FakeBillingRepository(
        _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
        startTrialError: Exception('network'),
      );

      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 0,
          repository: repo,
          onTap: (ctx, ref) async {
            await handleStartTrial(context: ctx, ref: ref);
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.paywallTrialFailed), findsOneWidget);
    });
  });

  group('handleBuyLifetime (Phase C2)', () {
    testWidgets('store unavailable → lifetime unavailable SnackBar', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final repo = _FakeBillingRepository(
        _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
      );
      final iap = FakeIapService(available: false);

      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 0,
          repository: repo,
          iapService: iap,
          onTap: (ctx, ref) async {
            await handleBuyLifetime(context: ctx, ref: ref);
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.paywallLifetimeStoreUnavailable),
        findsOneWidget,
      );
      expect(repo.validatePurchaseCalls, 0);
    });

    testWidgets('구매 취소 → lifetime cancelled SnackBar', (tester) async {
      await _useTallSurface(tester);
      final repo = _FakeBillingRepository(
        _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
      );
      final iap = FakeIapService(
        products: [_productDetails(lifetimeProductId)],
        outcome: const IapPurchaseCancelled(),
      );

      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 0,
          repository: repo,
          iapService: iap,
          onTap: (ctx, ref) async {
            await handleBuyLifetime(context: ctx, ref: ref);
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.paywallLifetimePurchaseCancelled),
        findsOneWidget,
      );
      expect(repo.validatePurchaseCalls, 0);
      expect(iap.completePurchaseCalls, 0);
    });

    testWidgets(
      '구매 성공 + 검증 granted → lifetime success SnackBar + complete + receipt 전송',
      (tester) async {
        await _useTallSurface(tester);
        final repo = _FakeBillingRepository(
          _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
          validatePurchaseResult: const IapValidationResult(
            granted: true,
            message: 'ok',
            planId: 'plan-lifetime',
            tier: 'lifetime',
          ),
        );
        final iap = FakeIapService(
          products: [_productDetails(lifetimeProductId)],
          outcome: IapPurchaseSuccess(
            _purchaseDetails(
              productId: lifetimeProductId,
              receipt: 'apple-receipt-lifetime',
            ),
          ),
          platformName: 'apple',
        );

        await tester.pumpWidget(
          _harness(
            snapshot: _snapshot(
              plan: BillingPlan.free,
              status: BillingStatus.active,
            ),
            studentCount: 0,
            repository: repo,
            iapService: iap,
            onTap: (ctx, ref) async {
              await handleBuyLifetime(context: ctx, ref: ref);
            },
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();

        expect(
          find.text(AppStrings.paywallLifetimePurchaseSuccess),
          findsOneWidget,
        );
        expect(repo.validatePurchaseCalls, 1);
        expect(repo.lastPlatform, 'apple');
        expect(repo.lastReceipt, 'apple-receipt-lifetime');
        expect(iap.completePurchaseCalls, 1);
      },
    );

    testWidgets('구매 성공 + 백엔드 검증 예외 → lifetime failed SnackBar + complete 미호출', (
      tester,
    ) async {
      await _useTallSurface(tester);
      final repo = _FakeBillingRepository(
        _snapshot(plan: BillingPlan.free, status: BillingStatus.active),
        validatePurchaseError: Exception('network'),
      );
      final iap = FakeIapService(
        products: [_productDetails(lifetimeProductId)],
        outcome: IapPurchaseSuccess(
          _purchaseDetails(
            productId: lifetimeProductId,
            receipt: 'apple-receipt-lifetime-fail',
          ),
        ),
      );

      await tester.pumpWidget(
        _harness(
          snapshot: _snapshot(
            plan: BillingPlan.free,
            status: BillingStatus.active,
          ),
          studentCount: 0,
          repository: repo,
          iapService: iap,
          onTap: (ctx, ref) async {
            await handleBuyLifetime(context: ctx, ref: ref);
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.paywallLifetimePurchaseFailed),
        findsOneWidget,
      );
      expect(iap.completePurchaseCalls, 0);
    });
  });
}
