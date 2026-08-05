// NoShowPolicy FE↔BE wire contract (P2-3, spec §2 / AC-10).
//
// The frontend enum must mirror the backend SSOT (#239,
// `app.models.schedule.NoShowPolicy`) value-for-value: deductCredit /
// halfCredit / noDeduction / reschedule.  Any rename on either side silently
// breaks `no_show_policy` decoding, so the wire strings are asserted literally
// here rather than derived from the enum.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/group_class.dart';
import 'package:lessonaza/features/schedule/presentation/extensions/no_show_policy_visuals.dart';

/// Backend SSOT values — kept as literals so a FE rename fails the test.
const _beWireValues = <NoShowPolicy, String>{
  NoShowPolicy.deductCredit: 'deductCredit',
  NoShowPolicy.halfCredit: 'halfCredit',
  NoShowPolicy.noDeduction: 'noDeduction',
  NoShowPolicy.reschedule: 'reschedule',
};

GroupClass _classWith(NoShowPolicy policy) => GroupClass(
  id: 'gc-1',
  teacherId: 'teacher-1',
  name: '바이올린 그룹 레슨',
  type: GroupClassType.regular,
  maxCapacity: 6,
  durationMinutes: 60,
  noShowPolicy: policy,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  group('NoShowPolicy — BE SSOT 4-value contract', () {
    test('enum carries exactly the 4 backend values', () {
      expect(NoShowPolicy.values, hasLength(4));
      expect(NoShowPolicy.values.toSet(), _beWireValues.keys.toSet());
    });

    test('serializes to the backend wire string', () {
      for (final entry in _beWireValues.entries) {
        expect(
          _classWith(entry.key).toJson()['no_show_policy'],
          entry.value,
          reason: '${entry.key} must serialize as ${entry.value}',
        );
      }
    });

    test('round-trips every value through toJson/fromJson', () {
      for (final policy in NoShowPolicy.values) {
        final decoded = GroupClass.fromJson(_classWith(policy).toJson());
        expect(decoded.noShowPolicy, policy);
      }
    });

    test('decodes a backend payload that omits no_show_policy', () {
      final json =
          _classWith(NoShowPolicy.halfCredit).toJson()
            ..remove('no_show_policy');

      // Backend column default is deductCredit (schedule.py §NoShowPolicy).
      expect(GroupClass.fromJson(json).noShowPolicy, NoShowPolicy.deductCredit);
    });
  });

  group('NoShowPolicyVisuals', () {
    test('every value has a distinct label and description', () {
      final labels = NoShowPolicy.values.map((p) => p.label).toList();
      final descriptions =
          NoShowPolicy.values.map((p) => p.description).toList();

      expect(labels.toSet(), hasLength(NoShowPolicy.values.length));
      expect(descriptions.toSet(), hasLength(NoShowPolicy.values.length));
      expect(labels.any((l) => l.trim().isEmpty), isFalse);
      expect(descriptions.any((d) => d.trim().isEmpty), isFalse);
    });

    test('labels come from AppStrings (no inline literals)', () {
      expect(
        NoShowPolicy.deductCredit.label,
        AppStrings.noShowPolicyDeductCredit,
      );
      expect(NoShowPolicy.halfCredit.label, AppStrings.noShowPolicyHalfCredit);
      expect(
        NoShowPolicy.noDeduction.label,
        AppStrings.noShowPolicyNoDeduction,
      );
      expect(NoShowPolicy.reschedule.label, AppStrings.noShowPolicyReschedule);
    });

    test('descriptions come from AppStrings', () {
      expect(
        NoShowPolicy.deductCredit.description,
        AppStrings.noShowPolicyDeductCreditDescription,
      );
      expect(
        NoShowPolicy.halfCredit.description,
        AppStrings.noShowPolicyHalfCreditDescription,
      );
      expect(
        NoShowPolicy.noDeduction.description,
        AppStrings.noShowPolicyNoDeductionDescription,
      );
      expect(
        NoShowPolicy.reschedule.description,
        AppStrings.noShowPolicyRescheduleDescription,
      );
    });
  });
}
