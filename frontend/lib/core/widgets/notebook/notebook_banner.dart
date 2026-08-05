import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/notebook_typography.dart';

/// Notebook × Score "마지널리아 스트립" 배너 공통 셸.
///
/// 크림 종이 위에 적은 손글씨 주석 메타포:
/// - 배경: 투명 (paper 직접 노출)
/// - 좌측: 3px [accent] 세로선 (4대 시그니처 — Vermillion 기본)
/// - 본문: Gaegu 손글씨 ([NotebookTypography.hand] 기본)
///
/// **시각 셸만 제공한다.** 메시지 텍스트·표시 조건 같은 도메인 로직은
/// 호출부(예: `TimeContextBanner`)가 소유하고 이 위젯을 조립한다.
///
/// 채워진 프로모/상태 카드(예: paywall 배너)는 이 원형이 아니다 —
/// `NotebookCard` 또는 본 셸로 refit 한다. 스펙: `docs/_components/notebook_banner.md`.
@immutable
class NotebookBanner extends StatelessWidget {
  const NotebookBanner({
    super.key,
    required this.message,
    this.messageStyle,
    this.leadingIcon,
    this.accent = AppColors.paperAccent,
    this.background,
    this.border,
    this.trailing,
    this.margin = const EdgeInsets.only(bottom: AppSpacing.space4),
    this.padding = const EdgeInsets.all(AppSpacing.space3),
  });

  /// 배너 본문 문구 (손글씨 주석).
  final String message;

  /// 본문 스타일 override. 기본은 [NotebookTypography.hand] (Gaegu).
  final TextStyle? messageStyle;

  /// 좌측 리딩 아이콘. null 이면 본문만 표시.
  final IconData? leadingIcon;

  /// 좌측 3px 세로선 색. 기본 Vermillion ([AppColors.paperAccent]).
  final Color accent;

  /// 채움 배경. null 이면 종이(투명) 그대로.
  final Color? background;

  /// 테두리 override. 주면 기본 좌측 3px 세로선 대신 이 테두리를 쓴다.
  final BoxBorder? border;

  /// 우측 인라인 액션/닫기 위젯 (옵션).
  final Widget? trailing;

  /// 외곽 margin. 기본은 하단 [AppSpacing.space4].
  final EdgeInsetsGeometry margin;

  /// 내부 padding. 기본 [AppSpacing.space3] 전방향.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        border: border ?? Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 20, color: AppColors.ink),
            const SizedBox(width: AppSpacing.space3),
          ],
          Expanded(
            child: Text(
              message,
              style: messageStyle ?? NotebookTypography.hand,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.space2),
            trailing!,
          ],
        ],
      ),
    );
  }
}
