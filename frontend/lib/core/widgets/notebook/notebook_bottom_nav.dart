import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/notebook_typography.dart';

/// One tab of [NotebookBottomNav].
///
/// [icon] renders while inactive, [activeIcon] while selected — the Material
/// outlined/filled pair carries the selection state alongside the accent color.
@immutable
class NotebookBottomNavItem {
  const NotebookBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.itemKey,
  });

  /// Inactive glyph (outlined variant).
  final IconData icon;

  /// Active glyph (filled variant).
  final IconData activeIcon;

  /// Tab label — must come from `AppStrings`.
  final String label;

  /// Optional key on the tab root, used by coach marks to target the tab.
  final Key? itemKey;
}

/// Notebook × Score 하단 네비게이션 — 교사·학생·학부모 셸 공통 (Hyen 표준 H9).
///
/// 아이콘 24px + 라벨 10px. 선택 = [AppColors.paperAccent],
/// 비선택 = [AppColors.inkTertiary]. 배경 [AppColors.paperNav] 위에
/// 상단 2px 잉크 라인 — 기존 로마숫자 네비의 셸 시그니처를 그대로 유지한다.
///
/// [centerAction] 을 주면 탭 목록 한가운데(앞쪽 `items.length ~/ 2` 개 뒤)에
/// 삽입한다. 학생 셸의 연습 버튼처럼 탭이 아닌 액션 전용 슬롯이다.
class NotebookBottomNav extends StatelessWidget {
  const NotebookBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.centerAction,
  });

  /// Tabs in display order. Index matches [currentIndex] / [onTap].
  final List<NotebookBottomNavItem> items;

  /// Currently selected tab index.
  final int currentIndex;

  /// Called with the tapped tab index.
  final ValueChanged<int> onTap;

  /// Optional non-tab action rendered in the middle of the row.
  final Widget? centerAction;

  @override
  Widget build(BuildContext context) {
    final centerSlot = items.length ~/ 2;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paperNav,
        border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (centerAction != null && index == centerSlot) centerAction!,
                Expanded(
                  child: _NavItem(
                    item: items[index],
                    isSelected: index == currentIndex,
                    onTap: () => onTap(index),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final NotebookBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = isSelected
        ? AppColors.paperAccent
        : AppColors.inkTertiary;

    return InkWell(
      key: item.itemKey,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? item.activeIcon : item.icon,
            size: 24,
            color: accentColor,
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: NotebookTypography.sectionLabelSmall.copyWith(
              color: accentColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
