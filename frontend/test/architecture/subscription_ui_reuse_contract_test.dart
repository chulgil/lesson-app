import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('student and teacher subscription sections share the same card widget', () {
    final sharedWidget = File(
      'lib/features/subscription/presentation/widgets/subscription_membership_card.dart',
    );
    final studentList = File(
      'lib/features/subscription/presentation/screens/subscription_list_screen.dart',
    );
    final teacherStudentDetail = File(
      'lib/features/students/presentation/widgets/student_detail/student_subscription_section.dart',
    );
    final studentHomeSummary = File(
      'lib/features/student_home/presentation/widgets/student_subscription_summary.dart',
    );

    expect(
      sharedWidget.existsSync(),
      isTrue,
      reason: '수강권 카드 UI는 학생/선생님 화면이 함께 쓰는 subscription 기능의 공개 위젯이어야 합니다.',
    );

    final studentListSource = studentList.readAsStringSync();
    final teacherStudentDetailSource = teacherStudentDetail.readAsStringSync();
    final studentHomeSummarySource = studentHomeSummary.readAsStringSync();

    expect(
      studentListSource,
      contains('SubscriptionMembershipCard('),
      reason: '학생 화면의 내 수강권도 공용 수강권 카드 위젯을 사용해야 합니다.',
    );
    expect(
      teacherStudentDetailSource,
      contains('SubscriptionMembershipCard('),
      reason: '선생님 화면의 학생상세 수강권도 공용 수강권 카드 위젯을 사용해야 합니다.',
    );
    expect(
      studentHomeSummarySource,
      contains('SubscriptionMembershipCard('),
      reason: '학생 홈 수강권 요약도 선생님 학생상세와 같은 공용 카드 위젯을 사용해야 합니다.',
    );
    expect(
      studentListSource,
      isNot(contains('class _SubscriptionCardWithClass')),
      reason: '학생 수강권 화면에 private 중복 카드 조립 위젯을 두지 않습니다.',
    );
    expect(
      studentHomeSummarySource,
      isNot(contains('class _SubscriptionMiniCard')),
      reason: '학생 홈에 별도 수강권 카드 디자인을 다시 만들지 않습니다.',
    );
  });

  test('student home subscription summary uses its own application provider', () {
    final studentHomeSummary = File(
      'lib/features/student_home/presentation/widgets/student_subscription_summary.dart',
    );
    final source = studentHomeSummary.readAsStringSync();

    expect(
      source,
      isNot(contains('/students/presentation/providers/')),
      reason:
          '학생 홈 수강권 요약은 students feature의 presentation provider를 직접 참조하지 않고 student_home application provider를 통해 읽어야 합니다.',
    );
    expect(
      source,
      isNot(contains('lessonClassProvider(')),
      reason: '학생 홈 위젯은 수업명 조회 provider 조합을 직접 수행하지 않습니다.',
    );
    expect(
      source,
      contains('studentHomeSubscriptionSummariesProvider('),
      reason: '학생 홈 수강권 요약은 화면 전용 application provider를 사용해야 합니다.',
    );
  });
}
