import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/issue_form_membership_widgets.dart';

/// #72 회귀 가드 — 빈 membership 목록에서 `firstWhere(orElse: () => first)` 가
/// 빈 리스트의 `.first` 로 StateError 를 던지던 문제. 빈 목록이면 SizedBox.shrink.
void main() {
  testWidgets('MembershipInfoCard: 빈 목록에서 StateError 없이 렌더', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MembershipInfoCard(
              memberships: [],
              selectedMembershipId: 'x',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
