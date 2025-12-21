import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/practice_repository.dart';

/// Practice repository provider
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  return MockPracticeRepository();
});
