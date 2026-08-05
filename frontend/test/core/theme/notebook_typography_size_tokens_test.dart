import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/notebook_typography.dart';

/// #1221 후속 — 하단 네비게이션이 `NotebookTypography.x.copyWith(fontSize: y)` 로만
/// 쓰던 크기 변형에 이름을 부여한다.
///
/// #1221 이 굵기(fontWeight) 축을 이름 붙였다면 이 토큰은 **크기(fontSize) 축**이다.
/// 이름 없는 조합은 Figma 미러에서 어떤 텍스트 스타일에도 바인딩되지 않아
/// 디자인 토큰으로 추적되지 않는다.
///
/// 이 테스트의 목적은 **값 동등성**이다. 신규 토큰이 기존 표현식과 완전히 같은
/// TextStyle 이어야 픽셀 변화 0 이 보장된다.
///
/// `roman` 은 GoogleFonts 기반이라 바인딩이 필요하다. 따라서 스타일은 group 본문이
/// 아니라 각 test 안에서 lazy 하게 만든다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('size variant tokens == 기존 copyWith 표현식', () {
    test('romanLarge 는 roman.copyWith(fontSize: 18) 과 동일하다', () {
      expect(
        NotebookTypography.romanLarge,
        NotebookTypography.roman.copyWith(fontSize: 18),
      );
    });

    test('sectionLabelSmall 은 sectionLabel.copyWith(fontSize: 10) 과 동일하다', () {
      expect(
        NotebookTypography.sectionLabelSmall,
        NotebookTypography.sectionLabel.copyWith(fontSize: 10),
      );
    });
  });

  test('romanLarge 는 base 의 크기만 바꾼다', () {
    final base = NotebookTypography.roman;
    final large = NotebookTypography.romanLarge;
    expect(base.fontSize, 14);
    expect(large.fontSize, 18);
    expect(large.fontWeight, base.fontWeight);
    expect(large.fontStyle, base.fontStyle);
    expect(large.fontFamily, base.fontFamily);
  });

  test('sectionLabelSmall 은 base 의 크기만 바꾼다', () {
    final base = NotebookTypography.sectionLabel;
    final small = NotebookTypography.sectionLabelSmall;
    expect(base.fontSize, 13);
    expect(small.fontSize, 10);
    expect(small.fontWeight, base.fontWeight);
    expect(small.letterSpacing, base.letterSpacing);
    expect(small.color, base.color);
  });
}
