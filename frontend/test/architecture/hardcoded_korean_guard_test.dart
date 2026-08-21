// i18n 단계 1 — 인라인 한글 UI 문자열 가드 (하드코딩 박멸 회귀 방지).
//
// docs/specs/architecture/i18n_migration_spec.md §2: Text(...)/InputDecoration
// 파라미터에 한글 리터럴을 직접 박으면 ARB 이관(단계 2)에서 누락된다. 편집
// 시점 감지는 .claude/hooks/scripts/i18n-l10n-guard.py, CI/스위트 강제는 이
// 테스트가 담당한다 (같은 패턴 정의를 공유).
//
// 신규 문자열은 ARB(app_ko.arb + app_en.arb) + AppLocalizations 로 추가한다
// (단계 0 라체트 — app_strings_ratchet_test.dart).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 디버그 전용 화면 — spec §2.2 "디버그/로그 문자열은 이관 제외 (개발자 전용)".
const _debugOnlyFiles = {
  'lib/core/widgets/debug_role_switcher.dart',
  'lib/core/widgets/recording_diagnostic_screen.dart',
};

final _uiTextPattern = RegExp(
  '''\\b(?:Text|SelectableText|RichText)\\s*\\(\\s*(?:const\\s+)?['"][^'"]*[가-힣]''',
);
final _inputDecorationPattern = RegExp(
  '''(?:labelText|hintText|helperText|errorText)\\s*:\\s*['"][^'"]*[가-힣]''',
);

void main() {
  test('production 위젯에 인라인 한글 UI 문자열이 없다 (i18n 단계 1)', () {
    final violations = <String>[];
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart') ||
          path.endsWith('.g.dart') ||
          path.endsWith('.freezed.dart')) {
        continue;
      }
      if (path.contains('/l10n/')) continue;
      if (_debugOnlyFiles.contains(path)) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (_uiTextPattern.hasMatch(line) ||
            _inputDecorationPattern.hasMatch(line)) {
          violations.add('$path:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          '인라인 한글 UI 문자열 금지 — ARB(app_ko.arb + app_en.arb) 키 + '
          'AppLocalizations 로 추가하세요 (기존 AppStrings 상수 재사용은 허용). '
          '가이드: docs/specs/architecture/i18n_migration_spec.md §1.5·§2. 위반:\n'
          '${violations.join('\n')}',
    );
  });
}
