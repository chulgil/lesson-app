import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Notebook × Score 얇은 잉크 라인 — 섹션 구분용.
///
/// 기본 1px `AppColors.inkQuaternary`. 기존 카드 그림자/구분 라인을
/// 대체하여 "종이 위의 자 선" 메타포를 유지한다.
///
/// 스펙: `docs/specs/design/notebook/README.md` §5.1 · §6
class ThinRule extends StatelessWidget {
  /// 라인 두께. 기본 1px.
  final double height;

  /// 라인 색상. 기본 `AppColors.inkQuaternary`.
  final Color? color;

  const ThinRule({super.key, this.height = 1, this.color});

  @override
  Widget build(BuildContext context) =>
      Container(height: height, color: color ?? AppColors.inkQuaternary);
}
