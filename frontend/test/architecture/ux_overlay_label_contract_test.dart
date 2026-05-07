import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UX 라벨 규칙 문서에 닫기/취소 분리 규칙이 반영돼야 한다', () {
    final uxGuidelines = File('../docs/specs/design/ux_guidelines.md').readAsStringSync();
    final bottomSheetComponent =
        File('../docs/_components/bottom_sheet.md').readAsStringSync();
    final confirmDialogComponent =
        File('../docs/_components/confirm_dialog.md').readAsStringSync();

    expect(
      uxGuidelines,
      contains('**닫기**: 팝업/시트/모달을 단순히 닫거나 현재 기능 진입점을 종료할 때 사용한다.'),
      reason: 'ux_guidelines.md should distinguish close from action cancel.',
    );
    expect(
      uxGuidelines,
      contains('**취소**: 사용자가 의도한 비즈니스 액션 자체를 되돌리거나 철회할 때 사용한다.'),
      reason: 'ux_guidelines.md should define action-cancel use case clearly.',
    );

    expect(
      bottomSheetComponent,
      contains('헤더에 닫기(X)가 이미 있는 경우, 하단에 별도 `닫기` 버튼을 추가하지 않는다.'),
      reason:
          'Bottom sheet component spec must keep close-button duplication rule.',
    );
    expect(
      confirmDialogComponent,
      contains('`취소` 라벨은 **액션 취소**(요청/제안/변경 철회)일 때만 사용하고,'),
      reason:
          'Confirm dialog spec must keep close-vs-cancel semantic separation.',
    );
  });

  test('바텀시트/다이얼로그 오버레이에서 닫기 중복 라벨이 있어서는 안 된다', () {
    final violations = <String>[];

    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'));

    final overlayPattern =
        RegExp(r'showNotebookBottomSheet|showNotebookDialog|showModalBottomSheet|showDialog');
    final headerClosePattern = RegExp(r'Icons\.close|closeAction|close action');
    final closeLabelPattern =
        RegExp(r'Text\s*\(\s*(?:const\s+)?(?:AppStrings\.closeAction|[\'\"]닫기[\'\"])\s*\)');
    final closeCancelArgPattern =
        RegExp(r'cancelLabel:\s*(?:AppStrings\.closeAction|[\'\"]닫기[\'\"])');

    for (final file in dartFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final content = file.readAsStringSync();

      if (!overlayPattern.hasMatch(content)) {
        continue;
      }

      if (headerClosePattern.hasMatch(content) &&
          (closeLabelPattern.hasMatch(content) ||
              closeCancelArgPattern.hasMatch(content))) {
        violations.add(normalizedPath);
      }

      if (RegExp(r'cancelLabel:\s*AppStrings\.closeAction').hasMatch(content) ||
          RegExp(r'cancelLabel:\s*[\'\"]닫기[\'\"]')
              .hasMatch(content)) {
        violations.add('$normalizedPath (cancelLabel close misuse)');
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'When an overlay already exposes a close icon, do not add a redundant [닫기] action button; use close action only when intent is dismiss-only.',
    );
  });
}
