import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum SwipeActionTone { normal, destructive }

/// Swipe-to-reveal action tile.
///
/// 사용 정책 (3원칙 + 방향 정책):
/// 1. swipe = destructive 단일 (`SwipeActionTone.destructive`)
/// 2. 다중 액션 = 행 탭 → BottomSheet (`showModalBottomSheet`)
/// 3. 모든 destructive 는 확인 다이얼로그 (`showDialog<AlertDialog>`)
/// 4. **방향 (2026-06-12)**: 오른쪽→왼쪽 스와이프 = 삭제·편집 등 관리
///    액션 ([SwipeActionTile.actions], 오른쪽에서 노출). 왼쪽→오른쪽 =
///    편의 기능 ([SwipeActionTile.startActions], 왼쪽에서 노출 — 선택적).
///    iOS/Android trailing 삭제 관행과 일치.
///
/// SSOT: docs/_components/swipe_action.md, .claude/rules/ux-rules.md
class SwipeAction {
  const SwipeAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tone = SwipeActionTone.normal,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final SwipeActionTone tone;
}

/// Swipe-to-reveal 행 단위 액션 타일.
///
/// 사용 정책 (3원칙 + 방향 정책) — 상세는 [SwipeAction] dartdoc 및 SSOT 참조.
///
/// - [actions]: **오른쪽→왼쪽** 스와이프로 노출 (오른쪽 정렬). 삭제·편집 등
///   관리/destructive 액션 전용.
/// - [startActions]: **왼쪽→오른쪽** 스와이프로 노출 (왼쪽 정렬). 다른
///   편의 기능 전용 (선택적 — 없으면 좌→우 스와이프는 닫기만 수행).
///
/// SSOT: docs/_components/swipe_action.md, .claude/rules/ux-rules.md
class SwipeActionTile extends StatefulWidget {
  const SwipeActionTile({
    super.key,
    required this.child,
    required this.actions,
    this.startActions = const [],
    this.actionWidth = 72,
  });

  final Widget child;

  /// 우→좌 스와이프로 노출되는 관리 액션 (삭제·편집 등) — 오른쪽 정렬.
  final List<SwipeAction> actions;

  /// 좌→우 스와이프로 노출되는 편의 액션 — 왼쪽 정렬 (선택적).
  final List<SwipeAction> startActions;

  final double actionWidth;

  @override
  State<SwipeActionTile> createState() => _SwipeActionTileState();
}

class _SwipeActionTileState extends State<SwipeActionTile> {
  /// 노출 상태: 0 = 닫힘, -1 = 우→좌 (trailing/관리), +1 = 좌→우 (편의).
  var _revealSide = 0;
  var _dragDelta = 0.0;

  double get _endWidth => widget.actionWidth * widget.actions.length;
  double get _startWidth => widget.actionWidth * widget.startActions.length;

  void _settleDrag(double velocity) {
    final effective = velocity != 0 ? velocity : _dragDelta;
    if (effective < 0 || _dragDelta < -48) {
      // 우→좌: 편의 패널이 열려 있었다면 먼저 닫고, 아니면 관리 패널 노출.
      setState(() => _revealSide = _revealSide == 1 ? 0 : -1);
    } else if (effective > 0 || _dragDelta > 48) {
      // 좌→우: 관리 패널이 열려 있으면 닫기, 아니면 편의 패널(있을 때) 노출.
      setState(() {
        if (_revealSide == -1) {
          _revealSide = 0;
        } else if (widget.startActions.isNotEmpty) {
          _revealSide = 1;
        }
      });
    }
    _dragDelta = 0;
  }

  bool _isPrimaryMouseDrag(PointerEvent event) {
    return event.kind == PointerDeviceKind.mouse &&
        (event.buttons & kPrimaryMouseButton) != 0;
  }

  double get _childOffsetX {
    switch (_revealSide) {
      case -1:
        return -_endWidth;
      case 1:
        return _startWidth;
      default:
        return 0;
    }
  }

  void _closeAndRun(VoidCallback onPressed) {
    setState(() => _revealSide = 0);
    onPressed();
  }

  Widget _buildPanel(List<SwipeAction> actions, Alignment alignment) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: actions
              .map(
                (action) => _SwipeActionButton(
                  action: action,
                  width: widget.actionWidth,
                  onPressed: () => _closeAndRun(action.onPressed),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          if (_revealSide == -1)
            _buildPanel(widget.actions, Alignment.centerRight),
          if (_revealSide == 1)
            _buildPanel(widget.startActions, Alignment.centerLeft),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_childOffsetX, 0, 0),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerMove: (event) {
                if (_isPrimaryMouseDrag(event)) {
                  _dragDelta += event.delta.dx;
                }
              },
              onPointerUp: (event) {
                if (event.kind == PointerDeviceKind.mouse) {
                  _settleDrag(0);
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  _settleDrag(details.primaryVelocity ?? 0);
                },
                onHorizontalDragUpdate: (details) {
                  _dragDelta += details.primaryDelta ?? 0;
                },
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.action,
    required this.width,
    required this.onPressed,
  });

  final SwipeAction action;
  final double width;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDestructive = action.tone == SwipeActionTone.destructive;
    final color = isDestructive ? AppColors.paperAccent : AppColors.ink;

    return SizedBox(
      width: width,
      child: Material(
        color: color,
        child: InkWell(
          onTap: onPressed,
          child: Semantics(
            button: true,
            label: action.label,
            hint: AppStrings.swipeActionHint,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: AppColors.paper, size: 20),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  action.label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.paper,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
