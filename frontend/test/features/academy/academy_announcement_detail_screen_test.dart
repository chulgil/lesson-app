import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_announcement.dart';
import 'package:lessonaza/features/notifications/presentation/screens/academy_announcement_detail_screen.dart';

/// G18/W5 — AcademyAnnouncementDetailScreen 회귀 테스트.
///
/// (1) 공지 본문 + 발송 시각 노출
/// (2) 미읽음 상태에서 '읽음 처리' 버튼 노출, 읽음 상태에서 숨김
void main() {
  final unread = AcademyAnnouncement(
    id: 'ann-1',
    academyId: 'acad_001',
    title: '여름 방학 수강 안내',
    body: '7월 방학 동안 보강 일정 안내드립니다.',
    sentAt: DateTime(2026, 5, 1, 10, 30),
    isRead: false,
  );

  final read = AcademyAnnouncement(
    id: 'ann-2',
    academyId: 'acad_001',
    title: '읽음 처리된 공지',
    body: '본문',
    sentAt: DateTime(2026, 4, 15, 9, 0),
    isRead: true,
  );

  group('AcademyAnnouncementDetailScreen', () {
    testWidgets('renders title + body + sentAt for unread', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AcademyAnnouncementDetailScreen(announcement: unread),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('여름 방학 수강 안내'), findsOneWidget);
      expect(find.text('7월 방학 동안 보강 일정 안내드립니다.'), findsOneWidget);
      expect(find.text(AppStrings.announcementMarkAsRead), findsOneWidget);
    });

    testWidgets('hides mark-as-read button when already read', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AcademyAnnouncementDetailScreen(announcement: read),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('읽음 처리된 공지'), findsOneWidget);
      expect(find.text(AppStrings.announcementMarkAsRead), findsNothing);
    });
  });
}
