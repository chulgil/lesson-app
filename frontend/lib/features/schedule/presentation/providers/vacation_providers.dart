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
  /// Committed segments. Each carries its own disposition (보상옵션 구간별).
  final List<VacationSegment> segments;

  // Draft editor — the segment currently being composed.
  final DateTime? draftStart;
  final DateTime? draftEnd;
  final VacationDisposition draftDisposition;

  // Shared across every segment (사유/학생별 예외 공통).
  final String reason;
  // spec §4.2 — per-student override. Absent key = "follow default".
  final Map<String, VacationDisposition> perStudentOverrides;

  // Impact preview for the draft range (informational).
  final VacationImpactPreview? impact;
  final bool isLoadingImpact;
  final bool isSubmitting;
  final String? errorMessage;

  const VacationFormState({
    this.segments = const [],
    this.draftStart,
    this.draftEnd,
    this.draftDisposition = VacationDisposition.rollForward,
    this.reason = '',
    this.perStudentOverrides = const {},
    this.impact,
    this.isLoadingImpact = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// Whether the draft range is valid (non-null, non-inverted, not in the past).
  bool get hasValidDraft {
    final s = draftStart;
    final e = draftEnd;
    if (s == null || e == null || e.isBefore(s)) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(s.year, s.month, s.day);
    return !startDay.isBefore(today);
  }

  /// The draft as a segment, or null when [hasValidDraft] is false.
  VacationSegment? get draftSegment => hasValidDraft
      ? VacationSegment(
          startDate: draftStart!,
          endDate: draftEnd!,
          disposition: draftDisposition,
        )
      : null;

  /// Whether a valid draft overlaps any already-committed segment.
  bool get draftOverlaps {
    final d = draftSegment;
    if (d == null) return false;
    return vacationSegmentsOverlap([...segments, d]);
  }

  /// Segments that would actually be submitted: committed segments plus the
  /// draft when it is valid and non-overlapping (single-segment teachers never
  /// need to press "구간 추가").
  List<VacationSegment> get effectiveSegments {
    final d = draftSegment;
    if (d != null && !draftOverlaps) return [...segments, d];
    return segments;
  }

  /// Whether registration can proceed (at least one effective segment).
  bool get canSubmit => effectiveSegments.isNotEmpty;

  VacationFormState copyWith({
    List<VacationSegment>? segments,
    DateTime? draftStart,
    DateTime? draftEnd,
    VacationDisposition? draftDisposition,
    String? reason,
    Map<String, VacationDisposition>? perStudentOverrides,
    VacationImpactPreview? impact,
    bool? isLoadingImpact,
    bool? isSubmitting,
    String? errorMessage,
    bool clearImpact = false,
    bool clearError = false,
    bool clearOverrides = false,
    bool clearDraft = false,
  }) {
    return VacationFormState(
      segments: segments ?? this.segments,
      draftStart: clearDraft ? null : (draftStart ?? this.draftStart),
      draftEnd: clearDraft ? null : (draftEnd ?? this.draftEnd),
      draftDisposition: clearDraft
          ? VacationDisposition.rollForward
          : (draftDisposition ?? this.draftDisposition),
      reason: reason ?? this.reason,
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

  VacationRepository get _repository => ref.read(vacationRepositoryProvider);

  void setDraftStart(DateTime date) {
    state = state.copyWith(
      draftStart: date,
      clearImpact: true,
      clearError: true,
    );
  }

  void setDraftEnd(DateTime date) {
    state = state.copyWith(draftEnd: date, clearImpact: true, clearError: true);
  }

  void setDraftDisposition(VacationDisposition value) {
    state = state.copyWith(draftDisposition: value);
  }

  void setReason(String value) {
    state = state.copyWith(reason: value);
  }

  /// spec §4.2 — Set or clear (`null`) the override for one student (shared).
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

  /// Commit the current draft as a segment. Returns false when the draft is
  /// invalid or overlaps an existing segment (caller surfaces the reason via
  /// [VacationFormState.hasValidDraft] / [VacationFormState.draftOverlaps]).
  bool addSegment() {
    final draft = state.draftSegment;
    if (draft == null) return false;
    if (vacationSegmentsOverlap([...state.segments, draft])) return false;
    final next = [...state.segments, draft]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    state = state.copyWith(
      segments: next,
      clearDraft: true,
      clearImpact: true,
      clearError: true,
    );
    return true;
  }

  void removeSegment(int index) {
    if (index < 0 || index >= state.segments.length) return;
    final next = [...state.segments]..removeAt(index);
    state = state.copyWith(segments: next);
  }

  Future<void> loadImpact() async {
    if (!state.hasValidDraft) return;
    final requestedStart = state.draftStart;
    final requestedEnd = state.draftEnd;
    state = state.copyWith(isLoadingImpact: true, clearError: true);
    try {
      final impact = await _repository.previewImpact(
        startDate: requestedStart!,
        endDate: requestedEnd!,
      );
      // The draft may have changed while this request was in flight (auto-load
      // re-fires on every date change) — drop a stale response instead of
      // overwriting the fresher (possibly still-loading) state.
      final isStale =
          state.draftStart != requestedStart || state.draftEnd != requestedEnd;
      state = state.copyWith(
        impact: isStale ? null : impact,
        isLoadingImpact: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingImpact: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Register all effective segments as one batch (#768 ②). Returns the created
  /// periods, or null on failure / nothing to submit.
  Future<List<VacationPeriod>?> submit() async {
    final segments = state.effectiveSegments;
    if (segments.isEmpty || state.isSubmitting) return null;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final periods = await _repository.registerVacationBatch(
        segments: segments,
        reason: state.reason.trim().isEmpty ? null : state.reason.trim(),
        perStudentDisposition: state.perStudentOverrides.isEmpty
            ? null
            : state.perStudentOverrides,
      );
      state = state.copyWith(isSubmitting: false);
      ref.invalidate(vacationListProvider);
      return periods;
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
