import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/features/subscription/domain/entities/proposal_settings.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_proposal.dart';
import 'package:lessonaza/features/subscription/domain/services/proposal_reminder_service.dart';
import 'package:lessonaza/features/subscription/presentation/providers/proposal_settings_providers.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_proposal_providers.dart';

/// #203: 교사의 "자동 리마인더" 토글(autoReminderEnabled)이 꺼져 있으면 제안 생성 시
/// 24/48/72h 리마인더를 예약하지 않아야 한다. (이전: 토글 무시하고 무조건 예약)

const _emptyCopy = ProposalReminderCopy(
  reminder24hTitle: '',
  reminder24hBody: '',
  reminder48hTitle: '',
  reminder48hBody: '',
  reminder72hTitleDiscount: '',
  reminder72hTitleNoDiscount: '',
  reminder72hBodyDiscount: '',
  reminder72hBodyNoDiscount: '',
  actionLabel: '',
);

class _SpyReminderService extends ProposalReminderService {
  int scheduleCalls = 0;

  _SpyReminderService()
    : super(
        scheduleNotification: (_) async {},
        cancelNotificationsByProposalId: (_) async {},
        loadProposal: (_) async => null,
        copy: _emptyCopy,
      );

  @override
  Future<void> scheduleRemindersForProposal(
    SubscriptionProposal proposal,
  ) async {
    scheduleCalls++;
  }
}

Future<int> _scheduleCallsAfterCreate({
  required bool autoReminderEnabled,
}) async {
  const teacherId = 'teacher-203';
  final spy = _SpyReminderService();
  final container = ProviderContainer(
    overrides: [
      mockDataModeProvider.overrideWithValue(true),
      proposalReminderServiceProvider.overrideWithValue(spy),
      teacherProposalSettingsProvider(teacherId).overrideWith(
        (ref) => ProposalSettings(
          teacherId: teacherId,
          autoReminderEnabled: autoReminderEnabled,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  await container
      .read(subscriptionProposalNotifierProvider.notifier)
      .createProposal(
        teacherId: teacherId,
        studentId: 'student-1',
        templateId: 'tmpl-1',
      );

  // _scheduleReminders 는 fire-and-forget(.then) — 설정 future 해소 + 마이크로태스크 배수.
  await container.read(teacherProposalSettingsProvider(teacherId).future);
  await Future<void>.delayed(Duration.zero);
  return spy.scheduleCalls;
}

void main() {
  test('#203 자동 리마인더 OFF → 제안 생성 시 리마인더 예약 안 함', () async {
    expect(await _scheduleCallsAfterCreate(autoReminderEnabled: false), 0);
  });

  test('#203 자동 리마인더 ON → 제안 생성 시 리마인더 예약함', () async {
    expect(await _scheduleCallsAfterCreate(autoReminderEnabled: true), 1);
  });
}
