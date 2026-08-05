import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_payment_repository.dart';
import '../../domain/repositories/payment_repository.dart';

part 'payment_repository_provider.g.dart';

/// Payment repository provider — intentionally local-only.
///
/// No RemotePaymentRepository by design (deferred, not missing):
/// tuition is recorded on Subscription state only and the backend exposes
/// no `/payments/*` API. See docs/specs/subscription/payment_architecture.md
/// §2 and docs/schema/entities/payment.md (Payment entity is legacy).
/// Do not add a Remote implementation without reopening that spec.
@Riverpod(keepAlive: true)
PaymentRepository paymentRepository(PaymentRepositoryRef ref) {
  return createLocalFallbackRepository<PaymentRepository>(
    ref: ref,
    mock: () => MockPaymentRepository(),
    fallback: () => MockPaymentRepository(empty: true),
  );
}
