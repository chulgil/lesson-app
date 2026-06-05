import 'package:lessonaza/features/academy/domain/entities/academy_billing_rule.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_teacher_payout_override.dart';
import 'package:lessonaza/features/academy/domain/entities/billing_enums.dart';
import 'package:lessonaza/features/academy/domain/repositories/academy_billing_rule_repository.dart';

/// Mock implementation of AcademyBillingRuleRepository.
class MockAcademyBillingRuleRepository implements AcademyBillingRuleRepository {
  MockAcademyBillingRuleRepository({
    Map<String, AcademyBillingRule>? seedRules,
    List<AcademyTeacherPayoutOverride>? seedOverrides,
  }) : _rules = Map.of(seedRules ?? const {}),
       _overrides = List.of(seedOverrides ?? const []);

  final Map<String, AcademyBillingRule> _rules;
  final List<AcademyTeacherPayoutOverride> _overrides;
  int _idSeq = 0;

  String _nextId(String prefix) {
    _idSeq++;
    return '${prefix}_$_idSeq';
  }

  // ------------------------------------------------------------------
  // BillingRule
  // ------------------------------------------------------------------

  @override
  Future<AcademyBillingRule> getForAcademy(String academyId) async {
    await _delay();
    final existing = _rules[academyId];
    if (existing != null) return existing;
    final created = AcademyBillingRule(
      id: _nextId('rule'),
      academyId: academyId,
      createdAt: DateTime.now(),
    );
    _rules[academyId] = created;
    return created;
  }

  @override
  Future<AcademyBillingRule> update(AcademyBillingRule rule) async {
    await _delay();
    _rules[rule.academyId] = rule;
    return rule;
  }

  // ------------------------------------------------------------------
  // TeacherPayoutOverride
  // ------------------------------------------------------------------

  @override
  Future<List<AcademyTeacherPayoutOverride>> listOverrides(
    String academyId,
  ) async {
    await _delay();
    final filtered =
        _overrides.where((o) => o.academyId == academyId).toList()
          ..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
    return filtered;
  }

  @override
  Future<AcademyTeacherPayoutOverride?> getActiveForTeacher({
    required String teacherMemberId,
    DateTime? asOf,
  }) async {
    await _delay();
    final t = asOf ?? DateTime.now();
    return _overrides.cast<AcademyTeacherPayoutOverride?>().firstWhere(
      (o) => o!.teacherMemberId == teacherMemberId && o.isActiveAt(t),
      orElse: () => null,
    );
  }

  @override
  Future<AcademyTeacherPayoutOverride> upsertOverride({
    required String academyId,
    required String teacherMemberId,
    required TeacherDistributionType distributionType,
    required Map<String, dynamic> distributionConfig,
    required DateTime effectiveFrom,
    String? note,
  }) async {
    await _delay();
    // 이전 활성 override 의 effectiveUntil = 새 effectiveFrom 으로 close.
    for (var i = 0; i < _overrides.length; i++) {
      final o = _overrides[i];
      if (o.teacherMemberId == teacherMemberId &&
          o.isOpen &&
          o.effectiveFrom.isBefore(effectiveFrom)) {
        _overrides[i] = o.copyWith(effectiveUntil: effectiveFrom);
      }
    }
    final created = AcademyTeacherPayoutOverride(
      id: _nextId('override'),
      academyId: academyId,
      teacherMemberId: teacherMemberId,
      distributionType: distributionType,
      distributionConfig: distributionConfig,
      effectiveFrom: effectiveFrom,
      note: note,
      createdAt: DateTime.now(),
    );
    _overrides.add(created);
    return created;
  }

  Future<void> _delay() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
}
