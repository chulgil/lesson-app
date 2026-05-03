import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_proposal.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_template.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/proposal_card_widgets.dart';

void main() {
  testWidgets('proposal cards constrain long template and price text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final template = SubscriptionTemplate(
      id: 'template-long',
      ownerId: 'teacher-1',
      ownerType: SubscriptionTemplateOwnerType.teacher,
      name: '초중급 콩쿠르 준비 집중 패키지 12회권 긴 이름 테스트',
      totalLessons: 120,
      lessonDurationMinutes: 120,
      validityDays: 365,
      price: 123456789,
      createdAt: DateTime.utc(2026, 5, 4),
    );
    final proposal = SubscriptionProposal(
      id: 'proposal-1',
      teacherId: 'teacher-1',
      studentId: 'student-1',
      templateId: template.id,
      status: ProposalStatus.pending,
      createdAt: DateTime.utc(2026, 5, 4),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      discountAmount: 12345678,
      discountReason: '장기 등록 특별 할인 테스트 메시지',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ProposalHeaderCard(proposal: proposal, template: template),
                const SizedBox(height: 16),
                ProposalDetailsCard(template: template),
                const SizedBox(height: 16),
                ProposalDiscountCard(proposal: proposal, template: template),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('초중급 콩쿠르'), findsOneWidget);
  });
}
