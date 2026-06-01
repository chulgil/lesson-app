import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pending_invite.dart';
import 'invite_provider.dart';

/// 선생님의 active + 만료 전 초대 목록 — #5 D-G3.
final pendingInviteListProvider =
    FutureProvider.autoDispose<List<PendingInvite>>((ref) async {
      final repo = ref.watch(inviteRepositoryProvider);
      return repo.getPendingInvites();
    });

/// 홈 카드용 카운트 — pendingInviteListProvider 의 length.
/// 별도 endpoint 가 없으므로 list 를 watch + 변환.
final pendingInviteCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final list = await ref.watch(pendingInviteListProvider.future);
  return list.length;
});

/// Resend / refresh actions — list/count provider 를 invalidate 해서 UI 갱신.
final invitePendingActionsProvider = Provider<InvitePendingActions>(
  (ref) => InvitePendingActions(ref),
);

class InvitePendingActions {
  InvitePendingActions(this._ref);

  final Ref _ref;

  Future<void> resend(String inviteId) async {
    final repo = _ref.read(inviteRepositoryProvider);
    await repo.resendInvite(inviteId);
    _ref.invalidate(pendingInviteListProvider);
    _ref.invalidate(pendingInviteCountProvider);
  }

  void refresh() {
    _ref.invalidate(pendingInviteListProvider);
    _ref.invalidate(pendingInviteCountProvider);
  }
}
