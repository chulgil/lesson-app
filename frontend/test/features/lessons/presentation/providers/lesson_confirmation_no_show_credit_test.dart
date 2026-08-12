import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/lessons/data/repositories/mock_lesson_repository.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_confirmation_provider.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_repository_provider.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/lesson_confirmation_dialog.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_makeup_credit_repository.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

/// 노쇼 표시 시 보강 크레딧 지급 배선 (spec §4.2, 선생님 재량, 기본 OFF).
///
/// 체크박스 ON → confirmationResult.grantMakeupCredit=true → 상태 전이 성공 후
/// MakeupCreditActions.grant(reason: noShowExempt) 1회 호출. OFF → 호출 없음.
class _SpyLessonRepository extends MockLessonRepository {
  final List<LessonStatus> statusTransitions = [];

  @override
  Future<Lesson> updateLessonStatus(Lesson lesson, LessonStatus status) async {
    statusTransitions.add(status);
    return lesson.copyWith(status: status);
  }

  @override
  Future<List<Lesson>> getLessons() async => const [];
}

class _SpyMakeupCreditRepository extends MockMakeupCreditRepository {
  final List<MakeupCreditReason> grantedReasons = [];
  final List<String?> grantedLessonIds = [];
  final List<String> grantedStudentIds = [];

  @override
  Future<MakeupCredit> grantCredit({
    required String studentId,
    String? sourceSubscriptionId,
    String? reasonNote,
    MakeupCreditReason reason = MakeupCreditReason.manualGrant,
    String? lessonId,
  }) async {
    grantedReasons.add(reason);
    grantedLessonIds.add(lessonId);
    grantedStudentIds.add(studentId);
    return super.grantCredit(
      studentId: studentId,
      sourceSubscriptionId: sourceSubscriptionId,
      reasonNote: reasonNote,
      reason: reason,
      lessonId: lessonId,
    );
  }
}

Lesson _lesson() => Lesson(
  id: 'lesson-noshow-credit-1',
  studentId: 'stu-1',
  studentName: '김민지',
  instrument: '바이올린',
  date: DateTime(2026, 8, 10),
  startTime: '10:00',
  status: LessonStatus.scheduled,
  subscriptionId: 'sub-1',
  createdAt: DateTime(2026, 8, 1),
);

void main() {
  late _SpyLessonRepository lessonRepo;
  late _SpyMakeupCreditRepository creditRepo;
  late ProviderContainer container;

  setUp(() {
    lessonRepo = _SpyLessonRepository();
    creditRepo = _SpyMakeupCreditRepository();
    container = ProviderContainer(
      overrides: [
        lessonRepositoryProvider.overrideWithValue(lessonRepo),
        makeupCreditRepositoryProvider.overrideWithValue(creditRepo),
      ],
    );
    addTearDown(container.dispose);
  });

  test('체크박스 ON → 노쇼 처리 후 보강 크레딧 1회 지급', () async {
    final notifier = container.read(
      lessonConfirmationNotifierProvider.notifier,
    );
    final lesson = _lesson();

    final result = await notifier.handleLessonNonCompletion(
      lesson,
      const LessonConfirmationResult(
        completed: false,
        nonCompletionReason: LessonNonCompletionReason.noShow,
        grantMakeupCredit: true,
      ),
    );

    expect(result.success, isTrue);
    expect(lessonRepo.statusTransitions, [LessonStatus.noShow]);
    expect(creditRepo.grantedReasons, [MakeupCreditReason.noShowExempt]);
    expect(creditRepo.grantedLessonIds, [lesson.id]);
    expect(creditRepo.grantedStudentIds, [lesson.studentId]);
  });

  test('체크박스 OFF(기본값) → 보강 크레딧 지급 호출 없음', () async {
    final notifier = container.read(
      lessonConfirmationNotifierProvider.notifier,
    );
    final lesson = _lesson();

    final result = await notifier.handleLessonNonCompletion(
      lesson,
      const LessonConfirmationResult(
        completed: false,
        nonCompletionReason: LessonNonCompletionReason.noShow,
      ),
    );

    expect(result.success, isTrue);
    expect(lessonRepo.statusTransitions, [LessonStatus.noShow]);
    expect(creditRepo.grantedReasons, isEmpty);
  });

  test('학생 사정 불참(studentAbsent)은 체크박스 ON 이어도 지급하지 않는다', () async {
    // grantMakeupCredit 은 다이얼로그에서 noShow 사유일 때만 세팅되지만,
    // 배선이 사유 자체로도 게이트하는지 회귀 검증.
    final notifier = container.read(
      lessonConfirmationNotifierProvider.notifier,
    );
    final lesson = _lesson();

    final result = await notifier.handleLessonNonCompletion(
      lesson,
      const LessonConfirmationResult(
        completed: false,
        nonCompletionReason: LessonNonCompletionReason.studentAbsent,
        grantMakeupCredit: true,
      ),
    );

    expect(result.success, isTrue);
    expect(lessonRepo.statusTransitions, [LessonStatus.studentAbsent]);
    expect(creditRepo.grantedReasons, isEmpty);
  });
}
