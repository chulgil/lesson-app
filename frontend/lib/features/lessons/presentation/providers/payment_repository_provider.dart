import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../repositories/payment_repository.dart';

/// Payment repository provider - switches between Mock and Remote.
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  if (EnvironmentConfig.useMockData) {
    return MockPaymentRepository();
  }
  // No remote API yet — use empty mock to avoid dummy data
  return MockPaymentRepository(empty: true);
});
