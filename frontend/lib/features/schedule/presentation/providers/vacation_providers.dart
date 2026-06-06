import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_vacation_repository.dart';
import '../../data/repositories/remote_vacation_repository.dart';
import '../../domain/entities/vacation_period.dart';
import '../../domain/repositories/vacation_repository.dart';

part 'vacation_providers.g.dart';

/// Repository provider — switches between Mock and Remote (#431).
///
/// 후속 PR 에서 codegen `@Riverpod(keepAlive: true)` 로 마이그레이션 예정.
/// 본 PR 은 진입 화면 골격만 구현하므로 plain Provider 로 유지.
final vacationRepositoryProvider = Provider<VacationRepository>((ref) {
  return createRepository<VacationRepository>(
    ref: ref,
    mock: () => MockVacationRepository(),
    remote: (api) => RemoteVacationRepository(api),
  );
});

// ──────────────────────────────────────────────────────────────
// Vacation form state — bound to the registration page (skeleton).
// ──────────────────────────────────────────────────────────────

class VacationFormState {
  final DateTime? startDate;
  final DateTime? endDate;
  final String reason;
  final VacationDisposition disposition;
  // spec §4.2 — per-student override. Absent key = "follow default".
  final Map<String, VacationDisposition> perStudentOverrides;
  final VacationImpactPreview? impact;
  final bool isLoadingImpact;
  final bool isSubmitting;
  final String? errorMessage;

  const VacationFormState({
    this.startDate,
    this.endDate,
    this.reason = '',
    this.disposition = VacationDisposition.rollForward,
    this.perStudentOverrides = const {},
    this.impact,
    this.isLoadingImpact = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  bool get hasValidRange {
    final s = startDate;
    final e = endDate;
    if (s == null || e == null || e.isBefore(s)) return false;
    // Start date must not be in the past (date-only comparison).
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(s.year, s.month, s.day);
    return !startDay.isBefore(today);
  }

  VacationFormState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    VacationDisposition? disposition,
    Map<String, VacationDisposition>? perStudentOverrides,
    VacationImpactPreview? impact,
    bool? isLoadingImpact,
    bool? isSubmitting,
    String? errorMessage,
    bool clearImpact = false,
    bool clearError = false,
    bool clearOverrides = false,
  }) {
    return VacationFormState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      disposition: disposition ?? this.disposition,
      perStudentOverrides: clearOverrides
          ? const {}
          : (perStudentOverrides ?? this.perStudentOverrides),
      impact: clearImpact ? null : (impact ?? this.impact),
      isLoadingImpact: isLoadingImpact ?? this.isLoadingImpact,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

@riverpod
class VacationForm extends _$VacationForm {
  @override
  VacationFormState build() => const VacationFormState();

  VacationRepository get _repository =>
      ref.read(vacationRepositoryProvider);

  void setStartDate(DateTime date) {
    state = state.copyWith(
      startDate: date,
      clearImpact: true,
      clearError: true,
    );
  }

  void setEndDate(DateTime date) {
    state = state.copyWith(endDate: date, clearImpact: true, clearError: true);
  }

  void setReason(String value) {
    state = state.copyWith(reason: value);
  }

  void setDisposition(VacationDisposition value) {
    state = state.copyWith(disposition: value);
  }

  /// spec §4.2 — Set or clear (`null`) the override for one student.
  void setStudentOverride(String studentId, VacationDisposition? override) {
    final next = Map<String, VacationDisposition>.from(
      state.perStudentOverrides,
    );
    if (override == null) {
      next.remove(studentId);
    } else {
      next[studentId] = override;
    }
    state = state.copyWith(perStudentOverrides: next);
  }

  Future<void> loadImpact() async {
    if (!state.hasValidRange) return;
    state = state.copyWith(isLoadingImpact: true, clearError: true);
    try {
      final impact = await _repository.previewImpact(
        startDate: state.startDate!,
        endDate: state.endDate!,
      );
      state = state.copyWith(impact: impact, isLoadingImpact: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingImpact: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<VacationPeriod?> submit() async {
    if (!state.hasValidRange || state.isSubmitting) return null;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final period = await _repository.registerVacation(
        startDate: state.startDate!,
        endDate: state.endDate!,
        reason: state.reason.trim().isEmpty ? null : state.reason.trim(),
        defaultDisposition: state.disposition,
        perStudentDisposition: state.perStudentOverrides.isEmpty
            ? null
            : state.perStudentOverrides,
      );
      state = state.copyWith(isSubmitting: false);
      ref.invalidate(vacationListProvider);
      return period;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return null;
    }
  }
}

// ──────────────────────────────────────────────────────────────
// Vacation list + Recovery (spec §7 + §9.1) — H-001 FE Phase 3.
// ──────────────────────────────────────────────────────────────

/// Active vacations for the signed-in teacher.
final vacationListProvider = FutureProvider.autoDispose<List<VacationPeriod>>((
  ref,
) async {
  final repository = ref.watch(vacationRepositoryProvider);
  return repository.listVacations();
});

/// Actions used by the active vacation card — cancel + invalidate.
final vacationActionsProvider = Provider<VacationActions>(
  (ref) => VacationActions(ref),
);

class VacationActions {
  VacationActions(this._ref);

  final Ref _ref;

  /// Cancel a vacation. Throws on server error; UI maps message → friendly text.
  Future<void> cancel(String periodId) async {
    final repo = _ref.read(vacationRepositoryProvider);
    await repo.cancelVacation(periodId);
    _ref.invalidate(vacationListProvider);
  }

  void refresh() => _ref.invalidate(vacationListProvider);
}
