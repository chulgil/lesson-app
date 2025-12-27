import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/parent_repository.dart';

/// Parent repository provider
final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return MockParentRepository();
});
