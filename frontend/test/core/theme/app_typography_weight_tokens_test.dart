import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_typography.dart';

/// #1221 — 앱 전반에서 `AppTypography.x.copyWith(fontWeight: y)` 로만 존재하던
/// 굵기 조합에 이름을 부여한다.
///
/// 이 테스트의 목적은 **값 동등성**이다. 신규 토큰이 기존 표현식과 완전히 같은
/// TextStyle 이어야 픽셀 변화 0 이 보장되고, Figma 미러의 텍스트 스타일도
/// 기존 프레임에 그대로 붙는다.
void main() {
  group('weight variant tokens == 기존 copyWith 표현식', () {
    final cases = <String, (TextStyle, TextStyle)>{
      'bodyLargeW600': (
        AppTypography.bodyLargeW600,
        AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
      ),
      'bodyLargeW700': (
        AppTypography.bodyLargeW700,
        AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
      ),
      'bodyMediumW500': (
        AppTypography.bodyMediumW500,
        AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
      ),
      'bodyMediumW600': (
        AppTypography.bodyMediumW600,
        AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      'bodyMediumW700': (
        AppTypography.bodyMediumW700,
        AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
      ),
      'bodySmallW500': (
        AppTypography.bodySmallW500,
        AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500),
      ),
      'bodySmallW600': (
        AppTypography.bodySmallW600,
        AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
      ),
      'captionW500': (
        AppTypography.captionW500,
        AppTypography.caption.copyWith(fontWeight: FontWeight.w500),
      ),
      'captionW600': (
        AppTypography.captionW600,
        AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
      ),
      'captionSmallW600': (
        AppTypography.captionSmallW600,
        AppTypography.captionSmall.copyWith(fontWeight: FontWeight.w600),
      ),
      'headingSmallW700': (
        AppTypography.headingSmallW700,
        AppTypography.headingSmall.copyWith(fontWeight: FontWeight.w700),
      ),
    };

    cases.forEach((name, pair) {
      test(name, () {
        final (token, expected) = pair;
        expect(token, expected, reason: '$name 이 기존 표현식과 다르면 픽셀이 바뀐다');
      });
    });
  });

  test('신규 토큰은 base 의 fontSize/height 를 바꾸지 않는다', () {
    expect(
      AppTypography.bodyMediumW600.fontSize,
      AppTypography.bodyMedium.fontSize,
    );
    expect(
      AppTypography.bodyMediumW600.height,
      AppTypography.bodyMedium.height,
    );
    expect(AppTypography.captionW600.fontSize, AppTypography.caption.fontSize);
    expect(
      AppTypography.headingSmallW700.fontSize,
      AppTypography.headingSmall.fontSize,
    );
  });
}
