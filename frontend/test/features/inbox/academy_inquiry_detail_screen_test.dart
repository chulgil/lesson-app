import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_inquiry.dart';
import 'package:lessonaza/features/inbox/presentation/screens/academy_inquiry_detail_screen.dart';

/// G19/W5 — AcademyInquiryDetailScreen 회귀 테스트.
///
/// (1) 본문 + 송신자 + 답변 입력 UI 노출
/// (2) 답변이 있을 때 '답변 (N)' 헤더 + 학원 답변 카드 노출
void main() {
  final pending = AcademyInquiry(
    id: 'inq-1',
    academyId: 'acad_001',
    senderRole: InquirySenderRole.student,
    senderName: '김학생',
    body: '이번 달 보강 가능한가요?',
    createdAt: DateTime(2026, 5, 20, 14, 0),
  );

  final replied = AcademyInquiry(
    id: 'inq-2',
    academyId: 'acad_001',
    senderRole: InquirySenderRole.parent,
    senderName: '학부모',
    body: '수강료 안내 부탁드립니다.',
    createdAt: DateTime(2026, 5, 18, 10, 0),
    replies: [
      AcademyInquiryReply(
        id: 'rep-1',
        body: '주 1회 기준 월 20만원입니다.',
        createdAt: DateTime(2026, 5, 18, 15, 0),
        isFromAcademy: true,
      ),
    ],
  );

  group('AcademyInquiryDetailScreen', () {
    testWidgets('renders body + sender + reply input for pending inquiry', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AcademyInquiryDetailScreen(
              inquiry: pending,
              academyId: 'acad_001',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('김학생'), findsOneWidget);
      expect(find.text('이번 달 보강 가능한가요?'), findsOneWidget);
      expect(find.text(AppStrings.inquiryReplySend), findsOneWidget);
    });

    testWidgets('shows reply header + academy reply card when replied', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AcademyInquiryDetailScreen(
              inquiry: replied,
              academyId: 'acad_001',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('답변 (1)'), findsOneWidget);
      expect(find.text('학원 답변'), findsOneWidget);
      expect(find.text('주 1회 기준 월 20만원입니다.'), findsOneWidget);
    });
  });
}
