// AppStrings ratchet — 신규 문자열 부채 유입 차단 (글로벌 확장 단계 0).
//
// 전략 (옵시디언 56-글로벌-확장-전략, 2026-08-21): AppStrings 한국어 상수는
// ARB 이관 대상 부채다 (docs/specs/architecture/i18n_migration_spec.md 단계 2).
// 이관이 끝나기 전까지 부채가 더 늘지 않도록, 멤버 수를 baseline 이하로만
// 허용한다. 신규 사용자-facing 문자열은 ARB + AppLocalizations 로 추가한다:
//
//   1. lib/core/l10n/arb/app_ko.arb 에 키 추가 (한국어)
//   2. lib/core/l10n/arb/app_en.arb 에 같은 키 추가 (영어 best-effort)
//   3. flutter gen-l10n (빌드 시 자동) → AppLocalizations.of(context).키
//
// baseline 하향(이관 진행)은 환영 — 아래 상수를 실측값으로 내려서 래칫을
// 조인다. 상향은 금지: 예외가 필요하면 이 테스트가 아니라 정책
// (.claude/rules/i18n-l10n.md)을 먼저 바꿀 것.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 2026-08-21 실측: static const 4,108 + static String 538.
const int appStringsMemberBaseline = 4646;

void main() {
  test('AppStrings 멤버 수는 baseline 이하 — 신규 문자열은 ARB 로 추가한다', () {
    final source = File('lib/core/l10n/app_strings.dart').readAsStringSync();
    final count = RegExp(
      r'^  static (?:const|String) ',
      multiLine: true,
    ).allMatches(source).length;

    expect(
      count,
      lessThanOrEqualTo(appStringsMemberBaseline),
      reason:
          'AppStrings 멤버가 baseline($appStringsMemberBaseline)을 넘었습니다 '
          '(현재 $count). 신규 사용자-facing 문자열은 AppStrings 상수가 아니라 '
          'ARB(app_ko.arb + app_en.arb) 키 + AppLocalizations 로 추가하세요. '
          '가이드: docs/specs/architecture/i18n_migration_spec.md 단계 0, '
          '.claude/rules/i18n-l10n.md',
    );

    if (count < appStringsMemberBaseline) {
      // 이관이 진행돼 실측이 줄었다 — 래칫을 조일 때다. 실패는 아니고 안내만.
      // ignore: avoid_print
      print(
        'app_strings_ratchet: 실측 $count < baseline $appStringsMemberBaseline — '
        'appStringsMemberBaseline 을 $count 로 내려 래칫을 조이세요.',
      );
    }
  });
}
