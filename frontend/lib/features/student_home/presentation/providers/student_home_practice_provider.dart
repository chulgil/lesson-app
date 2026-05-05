import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../practice/practice_facade.dart';

final studentHomePracticeLogsProvider = FutureProvider.autoDispose
    .family<List<PracticeLog>, String>((ref, studentId) {
      return ref.watch(practiceLogsProvider(studentId).future);
    });
