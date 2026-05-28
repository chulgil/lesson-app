import '../../../profile/domain/entities/cancellation_defaults.dart';
import '../../../profile/domain/repositories/cancellation_defaults_repository.dart';

/// Mock implementation of CancellationDefaultsRepository for testing
class MockCancellationDefaultsRepository
    implements CancellationDefaultsRepository {
  CancellationDefaults? _data;

  /// Create mock with custom initial data or use defaults
  MockCancellationDefaultsRepository({CancellationDefaults? initialData})
    : _data =
          initialData ??
          CancellationDefaults(
            id: 'teacher_001',
            cancellationDeadlineHours: 12,
            studentCompensationExtraMinutesEnabled: true,
            includeExtraMinutesTextOnLateCancel: true,
            studentCompensationExtraMinutesMessage: '10분 보너스 연습시간을 제공해드립니다',
            notifyOwnerOnLateCancel: false,
            createdAt: DateTime.now(),
          );

  @override
  Future<CancellationDefaults> getCancellationDefaults() async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 200));
    return _data!;
  }

  @override
  Future<CancellationDefaults> updateCancellationDefaults(
    CancellationDefaults defaults,
  ) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 300));
    _data = defaults.copyWith(updatedAt: DateTime.now());
    return _data!;
  }
}
