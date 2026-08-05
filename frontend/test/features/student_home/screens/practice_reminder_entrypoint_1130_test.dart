import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_home_profile_provider.dart';
import 'package:lessonaza/features/student_home/presentation/screens/student_profile_tab.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/practice_reminder_sheet.dart';

/// #1130 (껍데기 감사 #434): 연습 리마인더 진입점 복원 + '준비 중' 배너 제거.
///
/// #1092 가 소유하는 영속(Hive `student:<uid>:practiceReminder`) + 주간
/// OS 스케줄링은 그대로 두고, 진입점 노출과 배너 제거만 검증한다.
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

  const fakeProfile = StudentHomeProfileState(
    studentId: 'student-1',
    name: '홍길동',
    initial: '홍',
    email: 'hong@example.com',
    instrument: '바이올린',
    lessonCountLabel: '12회',
    practiceTimeLabel: '8시간',
    lessonPeriodLabel: '3개월',
    repertoireCount: 2,
    teacherSubtitle: '김선생님',
  );

  Future<void> pumpTab(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentHomeProfileProvider.overrideWithValue(fakeProfile),
        ],
        child: const MaterialApp(home: Scaffold(body: StudentProfileTab())),
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

  testWidgets('프로필 설정 메뉴에 연습 리마인더 진입점이 노출된다', (tester) async {
    await pumpTab(tester);

    expect(find.text(AppStrings.studentHomePracticeReminder), findsOneWidget);
    expect(find.byIcon(Icons.alarm_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('진입점 탭 시 연습 리마인더 시트가 열린다', (tester) async {
    await pumpTab(tester);

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
