import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/notebook_typography.dart';

/// Notebook × Score 매스트헤드.
///
/// 상단 2px 라인 + 하단 1px 라인 사이에:
/// - 좌: Playfair Display eyebrow ("LESSONAZA" 등)
/// - 우: IBM Plex Mono 메타 ("VOL. IV · NO. 18 · APR MMXXVI")
///
/// 스펙: `docs/specs/design/notebook/README.md` §6.2
class NotebookMasthead extends StatelessWidget {
  /// 좌측 로고/라벨 — 대문자 + letterSpacing 5.
  final String eyebrow;

  /// 우측 메타 — VOL·NO·DATE.
  final String meta;

  /// 우측 메타 탭 시 콜백 (알림 등).
  final VoidCallback? onMetaTap;

  /// 우측 메타 대신 아이콘을 표시할 때.
  final Widget? trailing;

  const NotebookMasthead({
    super.key,
    required this.eyebrow,
    required this.meta,
    this.onMetaTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.ink, width: 2),
          bottom: BorderSide(color: AppColors.ink, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment:
            trailing != null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.baseline,
        textBaseline: trailing != null ? null : TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(eyebrow, style: NotebookTypography.eyebrow)),
          if (trailing != null)
            trailing!
          else
            GestureDetector(
              onTap: onMetaTap,
              behavior: HitTestBehavior.opaque,
              child: Text(
                meta,
                style: NotebookTypography.metaMono,
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }
}
