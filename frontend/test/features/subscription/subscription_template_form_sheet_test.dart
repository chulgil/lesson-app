// 수강권 템플릿 작성 시트 — 가격표 연동 자동입력 + 할인 미리보기 + 스모크.
// HARD-GATE: design-principles.md (widget-smoke-test) — 신규 top-level 위젯.
//
// Verifies:
// - 가격표 없음 → 악기 드롭다운 숨김, 정가/판매가 필드만 (스모크, 예외 없음)
// - 가격표 있음 → 악기·레벨 선택 시 정가 자동입력 (회당가 × 횟수)
// - 판매가 < 정가 → "정가 대비 N% 할인" 미리보기

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/l10n/generated/app_localizations.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/settings/settings_facade.dart';
import 'package:lessonaza/features/subscription/presentation/screens/subscription_template_form_sheet.dart';

class _StubSettingsNotifier extends TeacherSettingsNotifier {
  _StubSettingsNotifier(this._settings);
  final TeacherSettings _settings;
  @override
  Future<TeacherSettings> build() async => _settings;
}

TeacherSettings _settings({Map<String, Map<String, int>>? priceTable}) =>
    TeacherSettings(
      id: 'teacher-1',
      instruments: const ['바이올린'],
      lessonPriceTable: priceTable,
      createdAt: DateTime.utc(2026, 6, 17),
    );

Future<void> _pumpSheet(
  WidgetTester tester, {
  Map<String, Map<String, int>>? priceTable,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        teacherSettingsNotifierProvider.overrideWith(
          () => _StubSettingsNotifier(_settings(priceTable: priceTable)),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: SubscriptionTemplateFormSheet(
            teacherId: 'teacher-1',
            onSave: (_) async {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('가격표 없음 → 악기 드롭다운 숨김, 정가/판매가 필드만 (스모크)', (tester) async {
    await _pumpSheet(tester);

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.templatePriceLabel), findsOneWidget); // 판매가
    expect(
      find.text(AppStrings.templateRegularPriceLabel),
      findsOneWidget,
    ); // 정가
    // 가격표가 비어 있으면 악기 드롭다운/안내는 노출되지 않는다.
    expect(find.text(AppStrings.templateInstrumentLabel), findsNothing);
    expect(find.text(AppStrings.templatePriceAutofillHint), findsNothing);
  });

  testWidgets('가격표 있음 → 악기·레벨 선택 시 정가 자동입력 + 할인 미리보기', (tester) async {
    await _pumpSheet(
      tester,
      priceTable: {
        '바이올린': {'beginner': 50000, 'intermediate': 70000},
      },
    );

    // 악기 드롭다운 + 안내 노출.
    expect(find.text(AppStrings.templatePriceAutofillHint), findsOneWidget);
    expect(find.text(AppStrings.templateInstrumentLabel), findsOneWidget);

    // 악기 = 바이올린 선택.
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('바이올린').last);
    await tester.pumpAndSettle();

    // 레벨 = 초급 선택.
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.experienceLevelBeginner).last);
    await tester.pumpAndSettle();

    // 정가 = 회당 50,000 × 8회 = 400,000 자동입력 (판매가도 동일 프리필).
    expect(find.text('400,000'), findsWidgets);

    // 판매가를 320,000 으로 낮춤 → 정가 대비 20% 할인 미리보기.
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.templatePriceLabel),
      '320000',
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.templateDiscountPreview(20)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
