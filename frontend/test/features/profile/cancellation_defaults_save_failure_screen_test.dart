// #1184 — 저장 실패 시 화면 피드백 (SnackBar) + 토글 복구.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/profile/domain/entities/cancellation_defaults.dart';
import 'package:lessonaza/features/profile/domain/repositories/cancellation_defaults_repository.dart';
import 'package:lessonaza/features/profile/presentation/providers/cancellation_defaults_provider.dart';
import 'package:lessonaza/features/profile/presentation/screens/cancellation_defaults_screen.dart';

class _ThrowingUpdateRepository implements CancellationDefaultsRepository {
  @override
  Future<CancellationDefaults> getCancellationDefaults() async =>
      CancellationDefaults(
        id: 'teacher_001',
        studentCompensationExtraMinutesEnabled: true,
        createdAt: DateTime.utc(2026, 7, 11),
      );

  @override
  Future<CancellationDefaults> updateCancellationDefaults(
    CancellationDefaults defaults,
  ) async {
    throw Exception('network down');
  }
}

void main() {
  testWidgets('저장 실패 시 SnackBar 안내 + 토글이 이전 값으로 복구된다', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cancellationDefaultsRepositoryProvider.overrideWithValue(
            _ThrowingUpdateRepository(),
          ),
        ],
        child: const MaterialApp(home: CancellationDefaultsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 첫 번째 SwitchListTile = 학생 취소 시 보상 제공 (초기 true)
    final firstSwitch = find.byType(SwitchListTile).first;
    expect(tester.widget<SwitchListTile>(firstSwitch).value, isTrue);

    await tester.tap(firstSwitch);
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.settingsSaveFailed),
      findsOneWidget,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      isTrue,
      reason: '실패한 토글은 이전 값(true)으로 복구되어야 한다',
    );
    expect(tester.takeException(), isNull);
  });
}
