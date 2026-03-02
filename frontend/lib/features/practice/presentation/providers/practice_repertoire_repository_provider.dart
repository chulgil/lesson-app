import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../repositories/practice_repertoire_repository.dart';

/// Practice repertoire repository provider - switches between Mock and Remote.
final practiceRepertoireRepositoryProvider =
    Provider<PracticeRepertoireRepository>((ref) {
      if (EnvironmentConfig.useMockData) {
        return MockPracticeRepertoireRepository();
      }
      // Mock already starts empty — safe to use in remote mode
      return MockPracticeRepertoireRepository();
    });
