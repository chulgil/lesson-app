import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_payment_repository.dart';
import '../../domain/repositories/payment_repository.dart';

part 'payment_repository_provider.g.dart';

/// Payment repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
PaymentRepository paymentRepository(PaymentRepositoryRef ref) {
  return createLocalFallbackRepository<PaymentRepository>(
    ref: ref,
    mock: () => MockPaymentRepository(),
    fallback: () => MockPaymentRepository(empty: true),
  );
}
