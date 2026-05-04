import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('학생 홈 셸은 모든 탭 아래에 PaperScaffold 바탕을 제공한다', () {
    final source =
        File(
          'lib/features/student_home/presentation/screens/student_home_screen.dart',
        ).readAsStringSync();

    expect(
      source,
      contains(
        "import '../../../../core/widgets/notebook/paper_scaffold.dart';",
      ),
    );
    expect(source, contains('child: PaperScaffold('));
    expect(source, contains('child: IndexedStack('));
  });
}
