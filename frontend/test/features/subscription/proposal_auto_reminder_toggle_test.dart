import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/features/subscription/domain/entities/proposal_settings.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_proposal.dart';
import 'package:lessonaza/features/subscription/domain/services/proposal_reminder_service.dart';
import 'package:lessonaza/features/subscription/presentation/providers/proposal_settings_providers.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_proposal_providers.dart';

/// #1212: 제안 생성 시 24/48/72h 리마인더를 FE 로컬로 예약하지 않아야 한다.
///
/// 리마인더 대상은 학생인데 예약은 교사 기기에서 일어나 교사에게 오발했다
/// (flutter_local_notifications 는 액터 기기 전용). 리마인더 발송은 BE 스케줄러
/// 소관이므로 FE 예약 경로를 제거했고, 이 테스트는 재도입을 막는 회귀 가드다.
/// 교사 설정 토글(autoReminderEnabled) 값과 무관하게 0 이어야 한다.
/// (이전 #203 계약: 토글 ON 이면 1회 예약 — 지금은 폐기)

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

  // 과거 예약 경로는 fire-and-forget(.then) 이었다 — 설정 future 해소 + 마이크로태스크
  // 배수까지 기다려야 "예약이 늦게 일어나는" 케이스도 잡을 수 있다.
  await container.read(teacherProposalSettingsProvider(teacherId).future);
  await Future<void>.delayed(Duration.zero);
  return spy.scheduleCalls;
}

void main() {
  test('#1212 자동 리마인더 OFF → 제안 생성 시 FE 로컬 예약 안 함', () async {
    expect(await _scheduleCallsAfterCreate(autoReminderEnabled: false), 0);
  });

  test('#1212 자동 리마인더 ON 이어도 → 제안 생성 시 FE 로컬 예약 안 함', () async {
    expect(await _scheduleCallsAfterCreate(autoReminderEnabled: true), 0);
  });
}
