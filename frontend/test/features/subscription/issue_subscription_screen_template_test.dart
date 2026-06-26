import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_template.dart';
import 'package:lessonaza/features/subscription/domain/repositories/subscription_template_repository.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_template_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/issue_subscription_screen.dart';

void main() {
  testWidgets('issue screen applies template defaults from templateId', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionTemplateRepositoryProvider.overrideWithValue(
            _FakeSubscriptionTemplateRepository(
              SubscriptionTemplate(
                id: 'template-12',
                ownerId: 'teacher-1',
                ownerType: SubscriptionTemplateOwnerType.teacher,
                name: '12회 집중권',
                totalLessons: 12,
                lessonDurationMinutes: 60,
                validityDays: 120,
                price: 360000,
                rescheduleAllowance: 3,
                createdAt: DateTime.utc(2026, 5, 4),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: IssueSubscriptionScreen(
            studentIds: ['student-1', 'student-2'],
            templateId: 'template-12',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('12회'), findsOneWidget);
    expect(_hasTextFieldValue(tester, '120'), isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();

    expect(_hasTextFieldValue(tester, '360,000'), isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('3회'), findsOneWidget);
  });
}

bool _hasTextFieldValue(WidgetTester tester, String value) {
  return tester
      .widgetList<TextFormField>(find.byType(TextFormField))
      .any((field) => field.controller?.text == value);
}

class _FakeSubscriptionTemplateRepository
    implements SubscriptionTemplateRepository {
  final SubscriptionTemplate template;

  _FakeSubscriptionTemplateRepository(this.template);

  @override
  Future<SubscriptionTemplate?> getById(String id) async =>
      id == template.id ? template : null;

  @override
  Future<List<SubscriptionTemplate>> getActiveByAcademy(
    String academyId,
  ) async => const [];

  @override
  Future<List<SubscriptionTemplate>> getActiveByTeacher(
    String teacherId,
  ) async => const [];

  @override
  Future<List<SubscriptionTemplate>> getAutoProposalTemplates(
    String teacherId,
  ) async => const [];

  @override
  Future<List<SubscriptionTemplate>> getByAcademy(String academyId) async =>
      const [];

  @override
  Future<List<SubscriptionTemplate>> getByTeacher(String teacherId) async =>
      const [];

  @override
  Future<SubscriptionTemplate> create(SubscriptionTemplate template) async =>
      template;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> reorder(List<String> orderedIds) async {}

  @override
  Future<SubscriptionTemplate> toggleActive(String id) async => template;

  @override
  Future<SubscriptionTemplate> update(SubscriptionTemplate template) async =>
      template;
}
