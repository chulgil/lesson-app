import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../repositories/practice_repertoire_repository.dart';

/// Practice repertoire repository provider - switches between Mock and Remote.
final practiceRepertoireRepositoryProvider =
    Provider<PracticeRepertoireRepository>((ref) {
      if (EnvironmentConfig.useMockData) {
        return MockPracticeRepertoireRepository();
      }
      // TODO: Replace with Remote repository when API is ready
      return MockPracticeRepertoireRepository();
    });
