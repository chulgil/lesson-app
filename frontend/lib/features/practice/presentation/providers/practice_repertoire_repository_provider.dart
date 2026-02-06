import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../repositories/practice_repertoire_repository.dart';

/// Practice repertoire repository provider
final practiceRepertoireRepositoryProvider =
    Provider<PracticeRepertoireRepository>((ref) {
  return MockPracticeRepertoireRepository();
});
