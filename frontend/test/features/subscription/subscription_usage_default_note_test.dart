import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_usage.dart';
import 'package:lessonaza/features/subscription/presentation/extensions/subscription_usage_visuals.dart';

/// Regression guard (2026-07-08 FE audit D4).
///
/// UsageType.studentAbsent 의 defaultNote 가 라벨('학생 결석')을 그대로 반환해,
/// lateCancellation(실제 설명 노트)과 종류가 어긋나던 버그의 가드.
void main() {
  test('studentAbsent defaultNote 는 라벨이 아니라 설명 노트다 (#D4)', () {
    expect(
      UsageType.studentAbsent.defaultNote,
      AppStrings.usageNoteStudentAbsent,
    );
    expect(
      UsageType.studentAbsent.defaultNote,
      isNot(AppStrings.usageTypeStudentAbsent),
    );
  });

  test('lateCancellation defaultNote 는 실제 설명 노트 (형제 일관성)', () {
    expect(
      UsageType.lateCancellation.defaultNote,
      AppStrings.usageNoteLateCancellation,
    );
  });
}
