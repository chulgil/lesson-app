// #1184 — 저장 실패 시 낙관적 업데이트 복구.
//
// remote 전환(#1178) 후 PUT 실패(오프라인·401·5xx)가 현실화됐다. 실패하면
// 낙관적으로 바꾼 state 를 이전 값으로 되돌리고 에러를 다시 던져, 화면이
// 사용자에게 실패를 알릴 수 있어야 한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/domain/entities/cancellation_defaults.dart';
import 'package:lessonaza/features/profile/domain/repositories/cancellation_defaults_repository.dart';
import 'package:lessonaza/features/profile/presentation/providers/cancellation_defaults_provider.dart';

CancellationDefaults _initial({bool enabled = true}) => CancellationDefaults(
  id: 'teacher_001',
  studentCompensationExtraMinutesEnabled: enabled,
  studentCompensationExtraMinutesMessage: '기존 문구',
  createdAt: DateTime.utc(2026, 7, 11),
);

class _ThrowingUpdateRepository implements CancellationDefaultsRepository {
  _ThrowingUpdateRepository(this.initial);

  final CancellationDefaults initial;
  int updateCalls = 0;

  @override
  Future<CancellationDefaults> getCancellationDefaults() async => initial;

  @override
  Future<CancellationDefaults> updateCancellationDefaults(
    CancellationDefaults defaults,
  ) async {
    updateCalls += 1;
    throw Exception('network down');
  }
}

class _RecordingRepository implements CancellationDefaultsRepository {
  _RecordingRepository(this.initial);

  final CancellationDefaults initial;
  CancellationDefaults? saved;

  @override
  Future<CancellationDefaults> getCancellationDefaults() async => initial;

  @override
  Future<CancellationDefaults> updateCancellationDefaults(
    CancellationDefaults defaults,
  ) async {
    saved = defaults;
    return defaults;
  }
}

void main() {
  test('저장 실패 시 state 를 이전 값으로 복구하고 rethrow 한다', () async {
    final repo = _ThrowingUpdateRepository(_initial(enabled: true));
    final container = ProviderContainer(
      overrides: [
        cancellationDefaultsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(
      cancellationDefaultsNotifierProvider,
      (_, __) {},
    );
    addTearDown(sub.close);

    await container.read(cancellationDefaultsNotifierProvider.future);

    await expectLater(
      container
          .read(cancellationDefaultsNotifierProvider.notifier)
          .toggleCompensationEnabled(false),
      throwsException,
    );

    final state = container.read(cancellationDefaultsNotifierProvider);
    expect(repo.updateCalls, 1);
    expect(
      state.value!.studentCompensationExtraMinutesEnabled,
      isTrue,
      reason: '실패한 낙관적 업데이트는 이전 값으로 복구되어야 한다',
    );
  });

  test('저장 실패 시 문구 변경도 이전 값으로 복구된다', () async {
    final repo = _ThrowingUpdateRepository(_initial());
    final container = ProviderContainer(
      overrides: [
        cancellationDefaultsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(
      cancellationDefaultsNotifierProvider,
      (_, __) {},
    );
    addTearDown(sub.close);

    await container.read(cancellationDefaultsNotifierProvider.future);

    await expectLater(
      container
          .read(cancellationDefaultsNotifierProvider.notifier)
          .updateCompensationMessage('새 문구'),
      throwsException,
    );

    expect(
      container
          .read(cancellationDefaultsNotifierProvider)
          .value!
          .studentCompensationExtraMinutesMessage,
      '기존 문구',
    );
  });

  test('저장 성공 시 갱신 값이 유지된다 (기존 동작 가드)', () async {
    final repo = _RecordingRepository(_initial(enabled: true));
    final container = ProviderContainer(
      overrides: [
        cancellationDefaultsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(
      cancellationDefaultsNotifierProvider,
      (_, __) {},
    );
    addTearDown(sub.close);

    await container.read(cancellationDefaultsNotifierProvider.future);
    await container
        .read(cancellationDefaultsNotifierProvider.notifier)
        .toggleCompensationEnabled(false);

    expect(
      container
          .read(cancellationDefaultsNotifierProvider)
          .value!
          .studentCompensationExtraMinutesEnabled,
      isFalse,
    );
    expect(repo.saved?.studentCompensationExtraMinutesEnabled, isFalse);
  });
}
