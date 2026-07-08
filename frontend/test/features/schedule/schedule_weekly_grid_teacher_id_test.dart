import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression guard (2026-07-08 FE audit C1).
///
/// 주간 그리드가 teacherAvailability / teacherDayOffs 를 하드코딩 'teacher_1' 로
/// 조회해, beta/remote(원격 repo 가 URL path 에 id 사용)에서 로그인 교사가 아닌
/// 유령 교사의 휴무·휴가·근무시간 음영을 표시하던 버그의 가드. 형제
/// schedule_timeline_view 는 #703 에서 이미 currentUserIdProvider 로 고쳤다.
void main() {
  test('주간 그리드는 하드코딩 teacher_1 이 아닌 currentUserIdProvider 로 교사 id 를 해소한다 (C1)', () {
    final src =
        File(
          'lib/features/schedule/presentation/widgets/schedule_weekly_grid_view.dart',
        ).readAsStringSync();

    expect(
      src.contains("teacherAvailabilityProvider('teacher_1')"),
      isFalse,
      reason: 'beta/remote 에서 유령 교사(teacher_1) 가용시간을 조회하면 안 된다.',
    );
    expect(
      RegExp(r"teacherId:\s*'teacher_1'").hasMatch(src),
      isFalse,
      reason: 'beta/remote 에서 유령 교사(teacher_1) 휴무를 조회하면 안 된다.',
    );
    expect(
      src.contains('currentUserIdProvider'),
      isTrue,
      reason:
          '로그인 교사 id 는 currentUserIdProvider 로 해소해야 한다 (형제 timeline_view #703 과 동일).',
    );
  });
}
