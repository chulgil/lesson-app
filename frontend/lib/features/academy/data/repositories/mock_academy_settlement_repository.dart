import 'package:lessonaza/features/academy/domain/entities/academy_settlement.dart';
import 'package:lessonaza/features/academy/domain/entities/billing_enums.dart';
import 'package:lessonaza/features/academy/domain/repositories/academy_settlement_repository.dart';

/// Mock implementation of AcademySettlementRepository.
class MockAcademySettlementRepository implements AcademySettlementRepository {
  MockAcademySettlementRepository({List<AcademySettlement>? seed})
    : _settlements = List.of(seed ?? const []);

  final List<AcademySettlement> _settlements;
  int _idSeq = 0;

  String _nextId() {
    _idSeq++;
    return 'settlement_$_idSeq';
  }

  void clear() {
    _settlements.clear();
  }

  // ------------------------------------------------------------------
  // 조회
  // ------------------------------------------------------------------

  @override
  Future<List<AcademySettlement>> listForAcademyPeriod({
    required String academyId,
    required int periodYear,
    required int periodMonth,
  }) async {
    await _delay();
    final filtered =
        _settlements
            .where(
              (s) =>
                  s.academyId == academyId &&
                  s.periodYear == periodYear &&
                  s.periodMonth == periodMonth,
            )
            .toList()
          ..sort((a, b) => a.teacherMemberId.compareTo(b.teacherMemberId));
    return filtered;
  }

  @override
  Future<List<AcademySettlement>> listForTeacher({
    required String teacherMemberId,
    int limit = 24,
  }) async {
    await _delay();
    final filtered =
        _settlements.where((s) => s.teacherMemberId == teacherMemberId).toList()
          ..sort((a, b) {
            final yc = b.periodYear.compareTo(a.periodYear);
            if (yc != 0) return yc;
            return b.periodMonth.compareTo(a.periodMonth);
          });
    return filtered.take(limit).toList();
  }

  @override
  Future<AcademySettlement?> get(String settlementId) async {
    await _delay();
    return _settlements.cast<AcademySettlement?>().firstWhere(
      (s) => s!.id == settlementId,
      orElse: () => null,
    );
  }

  // ------------------------------------------------------------------
  // Lifecycle
  // ------------------------------------------------------------------

  @override
  Future<AcademySettlement> calculate({
    required String academyId,
    required String teacherMemberId,
    required int periodYear,
    required int periodMonth,
    required int calculatedAmount,
    List<Map<String, dynamic>>? breakdown,
  }) async {
    await _delay();
    final index = _settlements.indexWhere(
      (s) =>
          s.academyId == academyId &&
          s.teacherMemberId == teacherMemberId &&
          s.periodYear == periodYear &&
          s.periodMonth == periodMonth,
    );
    if (index < 0) {
      final created = AcademySettlement(
        id: _nextId(),
        academyId: academyId,
        teacherMemberId: teacherMemberId,
        periodYear: periodYear,
        periodMonth: periodMonth,
        calculatedAmount: calculatedAmount,
        finalAmount: calculatedAmount,
        breakdown: breakdown,
        createdAt: DateTime.now(),
      );
      _settlements.add(created);
      return created;
    }
    final existing = _settlements[index];
    if (existing.status != SettlementStatus.draft) {
      throw StateError(
        'Cannot recalculate settlement in status ${existing.status.name}: '
        '${existing.id}',
      );
    }
    final updated = existing.copyWith(
      calculatedAmount: calculatedAmount,
      finalAmount: existing.adjustedAmount ?? calculatedAmount,
      breakdown: breakdown,
    );
    _settlements[index] = updated;
    return updated;
  }

  @override
  Future<AcademySettlement> adjust({
    required String settlementId,
    required String byUserId,
    required int adjustedAmount,
    required String reason,
  }) async {
    await _delay();
    final index = _settlements.indexWhere((s) => s.id == settlementId);
    if (index < 0) {
      throw StateError('Settlement not found: $settlementId');
    }
    final current = _settlements[index];
    if (current.status != SettlementStatus.draft) {
      throw StateError(
        'Cannot adjust settlement in status ${current.status.name}: '
        '$settlementId',
      );
    }
    final logEntry = <String, dynamic>{
      'at': DateTime.now().toIso8601String(),
      'by': byUserId,
      'from': current.adjustedAmount ?? current.calculatedAmount,
      'to': adjustedAmount,
      'reason': reason,
    };
    final updated = current.copyWith(
      adjustedAmount: adjustedAmount,
      finalAmount: adjustedAmount,
      adjustmentLog: [...current.adjustmentLog, logEntry],
    );
    _settlements[index] = updated;
    return updated;
  }

  @override
  Future<AcademySettlement> confirm(String settlementId) async {
    await _delay();
    final index = _settlements.indexWhere((s) => s.id == settlementId);
    if (index < 0) {
      throw StateError('Settlement not found: $settlementId');
    }
    final current = _settlements[index];
    if (current.status != SettlementStatus.draft) {
      throw StateError(
        'Cannot confirm settlement in status ${current.status.name}',
      );
    }
    final updated = current.copyWith(
      status: SettlementStatus.confirmed,
      confirmedAt: DateTime.now(),
      finalAmount: current.adjustedAmount ?? current.calculatedAmount,
    );
    _settlements[index] = updated;
    return updated;
  }

  @override
  Future<AcademySettlement> markTransferred(String settlementId) async {
    await _delay();
    final index = _settlements.indexWhere((s) => s.id == settlementId);
    if (index < 0) {
      throw StateError('Settlement not found: $settlementId');
    }
    final current = _settlements[index];
    if (current.status != SettlementStatus.confirmed) {
      throw StateError(
        'Cannot mark transferred — settlement is ${current.status.name}, '
        'must be confirmed first',
      );
    }
    final updated = current.copyWith(
      status: SettlementStatus.transferred,
      transferredAt: DateTime.now(),
    );
    _settlements[index] = updated;
    return updated;
  }

  // ------------------------------------------------------------------
  // Teacher audit
  // ------------------------------------------------------------------

  @override
  Future<AcademySettlement> acknowledge({
    required String settlementId,
    String? disputeNote,
  }) async {
    await _delay();
    final index = _settlements.indexWhere((s) => s.id == settlementId);
    if (index < 0) {
      throw StateError('Settlement not found: $settlementId');
    }
    final current = _settlements[index];
    final updated = current.copyWith(
      teacherAcknowledgedAt: DateTime.now(),
      teacherDisputeNote: disputeNote,
    );
    _settlements[index] = updated;
    return updated;
  }

  Future<void> _delay() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
}
