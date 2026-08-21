// i18n 단계 1 — 인라인 한글 UI 문자열 가드 (하드코딩 회귀 방지 라체트).
//
// docs/specs/architecture/i18n_migration_spec.md §2: Text(...)/InputDecoration
// 파라미터에 한글 리터럴을 직접 박으면 ARB 이관(단계 2)에서 누락된다.
//
// 리뷰 0821: 초기 버전은 "같은 줄" 정규식이라 dart-format 이 인자를 줄바꿈한
// 멀티라인 호출(예: `Text(\n  '한글',\n  style: ...)`)을 놓쳤다. 이제 파일
// 전문(full-content)을 스캔하며, 실측 잔존(멀티라인 형태 — 단계 2 이관 대상)
// 은 baseline 라체트로 봉인한다: 증가 = FAIL, 감소 = baseline 을 조인다.
//
// 신규 문자열은 ARB(app_ko.arb + app_en.arb) + AppLocalizations 로 추가한다
// (단계 0 — app_strings_ratchet_test.dart).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 2026-08-21 전문 스캔 실측 (단계 1 직후). 멀티라인 잔존분 — 단계 2에서
/// 이관하며 내려간다. 증가는 새 하드코딩 유입이므로 금지.
const int hardcodedKoreanBaseline = 253;

/// 디버그 전용 화면 — spec §2.2 "디버그/로그 문자열은 이관 제외 (개발자 전용)".
/// `.claude/hooks/scripts/i18n-l10n-guard.py` 의 DEBUG_ONLY_FILES 와 동기 유지.
const _debugOnlyFiles = {
  'lib/core/widgets/debug_role_switcher.dart',
  'lib/core/widgets/recording_diagnostic_screen.dart',
};

/// Text 계열 위젯의 첫 인자가 한글 리터럴 — `\s` 가 개행을 포함하므로
/// 멀티라인 호출도 잡는다.
final _uiTextPattern = RegExp(
  '''\\b(?:Text|SelectableText|RichText)\\s*\\(\\s*(?:const\\s+)?['"][^'"]*[가-힣]''',
);

/// InputDecoration 계열 파라미터 뒤 48자 안에 한글 리터럴 — 조건식
/// (`hintText: cond ? '한글' : '한글'`) 과 줄바꿈된 형태를 포함해 잡는다.
final _inputDecorationPattern = RegExp(
  '''(?:labelText|hintText|helperText|errorText)\\s*:[\\s\\S]{0,48}?['"][^'"]*[가-힣]''',
);

void main() {
  test('인라인 한글 UI 문자열은 baseline 이하 — 신규는 ARB 로 추가한다', () {
    final hits = <String>[];
    for (final file
        in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart') ||
          path.endsWith('.g.dart') ||
          path.endsWith('.freezed.dart')) {
        continue;
      }
      if (path.contains('/l10n/')) continue;
      if (_debugOnlyFiles.contains(path)) continue;

      final source = file.readAsStringSync();
      for (final pattern in [_uiTextPattern, _inputDecorationPattern]) {
        for (final match in pattern.allMatches(source)) {
          final line =
              '\n'.allMatches(source.substring(0, match.start)).length + 1;
          final snippet = match.group(0)!.split(RegExp(r'\s+')).join(' ');
          hits.add('$path:$line: $snippet');
        }
      }
    }

    expect(
      hits.length,
      lessThanOrEqualTo(hardcodedKoreanBaseline),
      reason:
          '인라인 한글 UI 문자열이 baseline($hardcodedKoreanBaseline)을 넘었습니다 '
          '(현재 ${hits.length}). 신규 문자열은 ARB(app_ko.arb + app_en.arb) 키 + '
          'AppLocalizations 로 추가하세요 (기존 AppStrings 상수 재사용 허용). '
          '가이드: docs/specs/architecture/i18n_migration_spec.md §1.5·§2. '
          '최근 항목 예시:\n${hits.take(15).join('\n')}',
    );

    if (hits.length < hardcodedKoreanBaseline) {
      // 이관이 진행돼 실측이 줄었다 — 라체트를 조일 때다.
      // ignore: avoid_print
      print(
        'hardcoded_korean_guard: 실측 ${hits.length} < baseline '
        '$hardcodedKoreanBaseline — hardcodedKoreanBaseline 을 '
        '${hits.length} 로 내려 라체트를 조이세요.',
      );
    }
  });
}
