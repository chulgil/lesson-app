import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/student_home/presentation/screens/student_settings_hub_screen.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/practice_reminder_sheet.dart';

/// #1130 (껍데기 감사 #434): 연습 리마인더 진입점 복원 + '준비 중' 배너 제거.
///
/// #1092 가 소유하는 영속(Hive `student:<uid>:practiceReminder`) + 주간
/// OS 스케줄링은 그대로 두고, 진입점 노출과 배너 제거만 검증한다.
///
/// 설정 서브허브 분리(P1) 이후 진입점은 [StudentSettingsHubScreen] 으로
/// 이동했다 — 프로필 탭에는 단일 "설정" 행만 남는다.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reminder_entrypoint_1130');
    Hive.init(tempDir.path);
    await Hive.openBox('notification_settings');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  Future<void> pumpHub(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: StudentSettingsHubScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: PracticeReminderSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('설정 허브에 연습 리마인더 진입점이 노출된다', (tester) async {
    await pumpHub(tester);

    expect(find.text(AppStrings.studentHomePracticeReminder), findsOneWidget);
    expect(find.byIcon(Icons.alarm_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('진입점 탭 시 연습 리마인더 시트가 열린다', (tester) async {
    await pumpHub(tester);

    // 진입점은 스크롤 하단에 위치 — 먼저 화면 안으로 스크롤.
    final entry = find.text(AppStrings.studentHomePracticeReminder);
    await tester.scrollUntilVisible(entry, 200);
    await tester.pumpAndSettle();

    await tester.tap(entry);
    await tester.pumpAndSettle();

    // 시트 헤더 문구로 오픈 확인.
    expect(
      find.text(AppStrings.studentHomePracticeReminderDesc),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets("시트에 '준비 중' 배너가 더 이상 없다", (tester) async {
    await pumpSheet(tester);

    expect(
      find.textContaining('준비 중'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('시트가 영속 상태(기본값: 활성)를 반영한다', (tester) async {
    await pumpSheet(tester);

    // 기본 PracticeReminderState 는 isEnabled=true → Switch 가 켜져 있다.
    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, isTrue);
    expect(tester.takeException(), isNull);
  });
}
