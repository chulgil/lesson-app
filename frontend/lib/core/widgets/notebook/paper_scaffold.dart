import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Notebook × Score 종이 스캐폴드.
///
/// 크림색 종이 배경 + **왼쪽 3px 고정 붉은 여백선**.
/// 스펙: `docs/specs/design/notebook/README.md` §3
///
/// 사용:
/// ```dart
/// PaperScaffold(
///   child: SafeArea(child: SingleChildScrollView(...)),
/// )
/// ```
///
/// [child]는 `top: 0`부터 깔리므로 상단 여백은 SafeArea / Padding으로 처리한다.
class PaperScaffold extends StatelessWidget {
  final Widget child;

  const PaperScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 크림색 종이 배경
        const Positioned.fill(child: ColoredBox(color: AppColors.paper)),

        // 2. 왼쪽 3px 고정 붉은 여백선 (CRITICAL — 불가침 규칙)
        //    스펙: docs/specs/design/notebook/README.md §3
        const Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 3,
          child: IgnorePointer(child: ColoredBox(color: AppColors.paperMargin)),
        ),

        // 3. 콘텐츠
        Positioned.fill(child: child),
      ],
    );
  }
}
