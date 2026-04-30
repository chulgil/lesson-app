import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// §7.X — Sliver sticky 헤더 delegate.
///
/// CompactWeekStrip + DateHeader 를 스크롤 영역 상단에 고정시키기 위한
/// SliverPersistentHeaderDelegate. 외부 CustomScrollView 의 pinned sliver 로
/// 사용해 본문이 스크롤되어도 요일 막대가 항상 보이도록 한다.
///
/// 헤더 높이는 호출 측에서 측정해 [height] 로 전달 (CompactWeekStrip 약 80,
/// DateHeader 약 40 → 합산 ≈ 120).
class StickyScheduleHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const StickyScheduleHeaderDelegate({
    required this.height,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // SizedBox.expand 로 child 가 선언된 [height] 만큼 채우도록 강제.
    // 그렇지 않으면 Column(MainAxisSize.min) 의 실제 높이가 [height] 보다 작을 때
    // SliverGeometry assertion(paintExtent < layoutExtent) 으로 크래시.
    return Container(
      color: AppColors.paper,
      child: SizedBox.expand(child: child),
    );
  }

  @override
  bool shouldRebuild(covariant StickyScheduleHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
