import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_makeup_credit_repository.dart';
import '../../data/repositories/remote_makeup_credit_repository.dart';
import '../../domain/entities/makeup_credit.dart';
import '../../domain/repositories/makeup_credit_repository.dart';

part 'makeup_credit_providers.g.dart';

/// Repository provider — switches between Mock and Remote (#432).
@Riverpod(keepAlive: true)
MakeupCreditRepository makeupCreditRepository(Ref ref) =>
    createRepository<MakeupCreditRepository>(
      ref: ref,
      mock: () => MockMakeupCreditRepository(),
      remote: (api) => RemoteMakeupCreditRepository(api),
    );

/// Student-side: all of the signed-in student's makeup credits (used + unused).
@riverpod
Future<List<MakeupCredit>> studentMakeupCredits(Ref ref) async {
  final repository = ref.watch(makeupCreditRepositoryProvider);
  return repository.listStudentCredits();
}

/// Student-side: spendable balance (not used, not expired) for booking flows.
@riverpod
Future<MakeupCreditBalance> studentMakeupCreditBalance(Ref ref) async {
  final credits = await ref.watch(studentMakeupCreditsProvider.future);
  return MakeupCreditBalance.fromCredits(credits, DateTime.now());
}

/// Teacher-side: makeup credits issued for one student.
@riverpod
Future<List<MakeupCredit>> teacherMakeupCredits(
  Ref ref,
  String studentId,
) async {
  final repository = ref.watch(makeupCreditRepositoryProvider);
  return repository.listTeacherCredits(studentId: studentId);
}

/// Teacher-side actions — grant (§4.4) + revoke, with cache invalidation.
@riverpod
MakeupCreditActions makeupCreditActions(Ref ref) => MakeupCreditActions(ref);

class MakeupCreditActions {
  MakeupCreditActions(this._ref);

  final Ref _ref;

  Future<MakeupCredit> grant({
    required String studentId,
    String? sourceSubscriptionId,
    String? reasonNote,
    MakeupCreditReason reason = MakeupCreditReason.manualGrant,
    String? lessonId,
  }) async {
    final repo = _ref.read(makeupCreditRepositoryProvider);
    final credit = await repo.grantCredit(
      studentId: studentId,
      sourceSubscriptionId: sourceSubscriptionId,
      reasonNote: reasonNote,
      reason: reason,
      lessonId: lessonId,
    );
    _ref.invalidate(teacherMakeupCreditsProvider(studentId));
    _ref.invalidate(studentMakeupCreditsProvider);
    return credit;
  }

  Future<void> revoke({
    required String creditId,
    required String studentId,
  }) async {
    final repo = _ref.read(makeupCreditRepositoryProvider);
    await repo.revokeCredit(creditId);
    _ref.invalidate(teacherMakeupCreditsProvider(studentId));
    _ref.invalidate(studentMakeupCreditsProvider);
  }

  /// Student-side: spend the earliest-expiring available credit on [lessonId]
  /// at booking time (spec §5.3 / #928). Returns true when a credit was spent,
  /// false when the student has none available (caller falls back to regular).
  Future<bool> useOldestCredit({required String lessonId}) async {
    final balance = await _ref.read(studentMakeupCreditBalanceProvider.future);
    if (!balance.hasAny) return false;
    // `available` is pre-sorted earliest-expiry first (fromCredits) — spend that
    // one so soon-to-expire credits are consumed before they lapse.
    final credit = balance.available.first;
    final repo = _ref.read(makeupCreditRepositoryProvider);
    await repo.useCredit(creditId: credit.id, lessonId: lessonId);
    _ref.invalidate(studentMakeupCreditsProvider);
    return true;
  }
}
