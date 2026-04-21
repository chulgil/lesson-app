import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Notebook × Score 종이 스캐폴드.
///
/// 크림색 종이 배경만 제공한다.
/// 스펙: `docs/specs/design/notebook/README.md` §3
///
/// 과거에는 왼쪽에 3px 붉은 여백선을 그렸으나, 모바일에서 베젤·라운드 코너에
/// 가려 안 보이거나 콘텐츠와 겹쳐 지저분해 보이는 이슈로 2026-04-21 제거.
/// Notebook 은유는 크림색 종이 배경 + Playfair/로마숫자/Gaegu 로 유지한다.
///
/// 사용:
/// ```dart
/// PaperScaffold(
///   child: SafeArea(child: SingleChildScrollView(...)),
/// )
/// ```
class PaperScaffold extends StatelessWidget {
  final Widget child;

  const PaperScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: AppColors.paper, child: child);
  }
}
