import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/notebook_typography.dart';
import 'thin_rule.dart';

/// Notebook × Score 섹션 헤더 — uppercase 라벨 + 얇은 잉크 rule.
///
/// 레이아웃:
/// ```
/// LABEL                         [trailing]
/// ─────────────────────────────────────────
/// ```
///
/// 스펙: `docs/specs/design/notebook/README.md` §5.1 · §6
class NotebookSectionHeader extends StatelessWidget {
  /// 왼쪽 라벨. 자동으로 대문자로 렌더된다.
  final String label;

  /// 오른쪽에 배치되는 액션 위젯(선택). 보통 "더보기" 텍스트 버튼.
  final Widget? trailing;

  /// 하단 1px 잉크 라인 표시 여부. 기본 true.
  final bool showRule;

  const NotebookSectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.showRule = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: NotebookTypography.sectionLabel,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (showRule) ...[
          const SizedBox(height: AppSpacing.space1),
          const ThinRule(),
        ],
      ],
    );
  }
}
