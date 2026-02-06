import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../repositories/payment_repository.dart';

/// Payment repository provider
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return MockPaymentRepository();
});
