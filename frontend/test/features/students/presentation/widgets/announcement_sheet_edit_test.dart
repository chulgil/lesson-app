import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/students/domain/entities/teacher_announcement.dart';
import 'package:lessonaza/features/students/presentation/widgets/announcement_sheet.dart';

/// Layout smoke test (HARD-GATE) for [AnnouncementSheet] in EDIT mode.
///
/// Verifies prefill (message), edit-mode title/CTA, and no render crash.
void main() {
  testWidgets('AnnouncementSheet edit mode prefills + shows 수정/저장', (
    tester,
  ) async {
    final existing = TeacherAnnouncement(
      id: 'a1',
      teacherId: 't1',
      type: AnnouncementType.dayOff,
      dates: [DateTime(2026, 7, 20)],
      message: '기존 공지 메시지',
      createdAt: DateTime(2026, 6, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: AnnouncementSheet(existing: existing)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Prefilled message.
    expect(find.text('기존 공지 메시지'), findsOneWidget);
    // Edit-mode title + CTA.
    expect(find.text(AppStrings.announcementEditTitle), findsOneWidget);
    expect(find.text(AppStrings.save), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
