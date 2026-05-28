import '../entities/cancellation_defaults.dart';

/// Repository interface for managing teacher cancellation policy defaults
abstract class CancellationDefaultsRepository {
  /// Fetch current cancellation defaults for the teacher
  Future<CancellationDefaults> getCancellationDefaults();

  /// Update cancellation defaults
  Future<CancellationDefaults> updateCancellationDefaults(
    CancellationDefaults defaults,
  );
}
