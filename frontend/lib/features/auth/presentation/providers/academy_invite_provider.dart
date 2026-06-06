import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../academy/data/repositories/mock_academy_invite_repository.dart';
import '../../../academy/data/repositories/remote_academy_invite_repository.dart';
import '../../../academy/domain/repositories/academy_invite_repository.dart';

part 'academy_invite_provider.g.dart';

/// Academy invite repository provider — mock/remote switch by data mode (#554).
@riverpod
AcademyInviteRepository academyInviteRepository(
  AcademyInviteRepositoryRef ref,
) {
  return createRepository<AcademyInviteRepository>(
    ref: ref,
    mock: () => MockAcademyInviteRepository(),
    remote: (apiClient) => RemoteAcademyInviteRepository(apiClient),
  );
}

/// Academy invite preview provider — loads invite details by token
@riverpod
Future<AcademyInvitePreview> academyInvitePreview(
  AcademyInvitePreviewRef ref,
  String token,
) async {
  final repository = ref.watch(academyInviteRepositoryProvider);
  return repository.getInvitePreview(token);
}

/// Academy invite accept provider — accepts invite and creates membership
@riverpod
Future<void> academyInviteAccept(
  AcademyInviteAcceptRef ref,
  String token,
) async {
  final repository = ref.watch(academyInviteRepositoryProvider);
  // Note: public page consent defaults to false for now
  return repository.acceptInvite(token, publicPageConsent: false);
}

/// Academy invite reject provider — rejects invite
@riverpod
Future<void> academyInviteReject(
  AcademyInviteRejectRef ref,
  String token,
) async {
  final repository = ref.watch(academyInviteRepositoryProvider);
  return repository.rejectInvite(token);
}
