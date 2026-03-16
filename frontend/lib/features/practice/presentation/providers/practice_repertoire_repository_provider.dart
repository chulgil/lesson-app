import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../repositories/practice_repertoire_repository.dart';

/// Practice repertoire repository provider - switches between Mock and Remote.
final practiceRepertoireRepositoryProvider =
    Provider<PracticeRepertoireRepository>((ref) {
      if (EnvironmentConfig.useMockData) {
        return MockPracticeRepertoireRepository();
      }
      // Hive 로컬 저장소 의존 (녹음 파일 관리) — Remote 전환 시 파일 동기화 설계 필요
      return MockPracticeRepertoireRepository();
    });
