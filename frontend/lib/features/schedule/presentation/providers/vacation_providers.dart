import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_vacation_repository.dart';
import '../../data/repositories/remote_vacation_repository.dart';
import '../../domain/entities/vacation_period.dart';
import '../../domain/repositories/vacation_repository.dart';

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
  final VacationImpactPreview? impact;
  final bool isLoadingImpact;
  final bool isSubmitting;
  final String? errorMessage;

  const VacationFormState({
    this.startDate,
    this.endDate,
    this.reason = '',
    this.disposition = VacationDisposition.rollForward,
    this.impact,
    this.isLoadingImpact = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  bool get hasValidRange {
    final s = startDate;
    final e = endDate;
    return s != null && e != null && !e.isBefore(s);
  }

  VacationFormState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    VacationDisposition? disposition,
    VacationImpactPreview? impact,
    bool? isLoadingImpact,
    bool? isSubmitting,
    String? errorMessage,
    bool clearImpact = false,
    bool clearError = false,
  }) {
    return VacationFormState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      disposition: disposition ?? this.disposition,
      impact: clearImpact ? null : (impact ?? this.impact),
      isLoadingImpact: isLoadingImpact ?? this.isLoadingImpact,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class VacationFormNotifier extends StateNotifier<VacationFormState> {
  VacationFormNotifier(this._repository) : super(const VacationFormState());

  final VacationRepository _repository;

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
      );
      state = state.copyWith(isSubmitting: false);
      return period;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return null;
    }
  }
}

final vacationFormProvider =
    StateNotifierProvider.autoDispose<VacationFormNotifier, VacationFormState>((
      ref,
    ) {
      return VacationFormNotifier(ref.watch(vacationRepositoryProvider));
    });
