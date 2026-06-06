import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_context_switch_repository.dart';
import '../../data/repositories/remote_context_switch_repository.dart';
import '../../domain/repositories/context_switch_repository.dart';

part 'context_switch_provider.g.dart';

/// Context switch repository — mock vs remote based on runtime data mode.
///
/// Remote: `academy_context.py` (GET /auth/context, POST /auth/context/switch).
@Riverpod(keepAlive: true)
ContextSwitchRepository contextSwitchRepository(Ref ref) {
  return createRepository<ContextSwitchRepository>(
    ref: ref,
    mock: () => MockContextSwitchRepository(),
    remote: (apiClient) => RemoteContextSwitchRepository(apiClient),
  );
}

/// Current context + the contexts the user can toggle into (GET /auth/context).
///
/// Returns null callers nothing special — UI hides the toggle when
/// [ContextInfo.canToggle] is false (single-context users).
@riverpod
Future<ContextInfo> currentContext(Ref ref) {
  final repository = ref.watch(contextSwitchRepositoryProvider);
  return repository.getContext();
}
