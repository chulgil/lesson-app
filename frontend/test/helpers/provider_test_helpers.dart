// Utilities for testing Riverpod providers without widget pumping.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lessonaza/features/lessons/domain/repositories/teaching_resource_repository.dart';

/// Mock for TeachingResourceRepository
class MockTeachingResourceRepository extends Mock
    implements TeachingResourceRepository {}

/// Creates a ProviderContainer with optional overrides.
/// Remember to call container.dispose() in tearDown.
ProviderContainer createTestContainer({
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(overrides: overrides);
  return container;
}
