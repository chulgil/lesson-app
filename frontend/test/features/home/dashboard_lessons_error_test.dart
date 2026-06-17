// 대시보드 "오늘의 레슨" 로드 실패 — 빨간 에러가 아니라 부드러운 재시도 상태로
// 표시되는지 검증. (빈 데이터는 data 경로의 EmptyStateWidget 이 담당하므로 별개)
//
// 실 라우터(harness) + lessonsProvider 를 error 로 override 해 실패 상태를 주입.

import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart';

import '../../e2e/helpers/e2e_harness.dart';

void main() {
  setUpAll(initE2eEnvironment);
  tearDownAll(disposeE2eEnvironment);

  testWidgets('레슨 로드 실패 — 빨간 에러 대신 부드러운 재시도 상태', (tester) async {
    await bootAsRole(
      tester,
      DevAccount.teacher,
      overrides: [
        lessonsProvider.overrideWith(
          (ref) => Future<List<Lesson>>.error(Exception('boom')),
        ),
      ],
    );
    await settle(tester);

    // 부드러운 안내 타이틀 + 다시 시도 액션 노출.
    expect(
      find.text(AppStrings.dashboardLessonsLoadErrorTitle),
      findsOneWidget,
      reason: '로드 실패 시 부드러운 재시도 상태 타이틀이 보여야 함',
    );
    expect(
      find.text(AppStrings.retry),
      findsWidgets,
      reason: '다시 시도 액션이 있어야 함',
    );

    // 과거의 알람성 에러 문구("레슨을 불러올 수 없습니다")는 더 이상 노출 안 됨.
    expect(
      find.text(AppStrings.dashboardLessonsLoadError),
      findsNothing,
      reason: '빨간 에러 카드 문구는 노출되지 않아야 함',
    );
  });
}
