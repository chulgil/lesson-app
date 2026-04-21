import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Notebook × Score 종이 스캐폴드.
///
/// 크림색 종이 배경 + **왼쪽 붉은 여백선**.
/// 스펙: `docs/specs/design/notebook/README.md` §3
///
/// 여백선은 기본 `left: 14, width: 3` 로 화면 모서리에서 떨어져 배치되어
/// 기기 베젤/SafeArea 에 가려지지 않고 확실히 보이도록 한다.
///
/// 사용:
/// ```dart
/// PaperScaffold(
///   child: SafeArea(child: SingleChildScrollView(...)),
/// )
/// ```
///
/// [child] 는 `top: 0` 부터 깔리므로 상단 여백은 SafeArea / Padding 으로 처리한다.
/// 콘텐츠 좌측 padding 은 [marginLineRight] 이상이어야 텍스트가 선과 겹치지 않는다.
class PaperScaffold extends StatelessWidget {
  final Widget child;

  /// 여백선 왼쪽 offset. 기본 14px.
  final double marginLineLeft;

  /// 여백선 너비. 기본 3px.
  final double marginLineWidth;

  const PaperScaffold({
    super.key,
    required this.child,
    this.marginLineLeft = 14,
    this.marginLineWidth = 3,
  });

  /// 여백선 우측 끝 좌표 — 콘텐츠 좌측 padding 의 최소값.
  double get marginLineRight => marginLineLeft + marginLineWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 크림색 종이 배경
        const Positioned.fill(child: ColoredBox(color: AppColors.paper)),

        // 2. 왼쪽 붉은 여백선 (CRITICAL — §3 규칙)
        //    left 는 모서리에서 살짝 떨어뜨려 베젤/라운드 코너에 가려지지 않게.
        Positioned(
          left: marginLineLeft,
          top: 0,
          bottom: 0,
          width: marginLineWidth,
          child: const IgnorePointer(
            child: ColoredBox(color: AppColors.paperMargin),
          ),
        ),

        // 3. 콘텐츠
        Positioned.fill(child: child),
      ],
    );
  }
}
