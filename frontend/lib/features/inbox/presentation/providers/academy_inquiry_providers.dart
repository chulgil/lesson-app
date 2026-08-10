import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/features/academy/academy.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_inquiry_repository.dart';

/// Single shared inquiry repository instance.
///
/// Call sites previously constructed their own [MockAcademyInquiryRepository]
/// (instance-level storage), so a submitted inquiry or reply was written to a
/// throwaway instance and could never show up in the list/detail screens.
final academyInquiryRepositoryProvider = Provider<AcademyInquiryRepository>(
  (ref) => MockAcademyInquiryRepository(),
);

/// Inquiries for an academy — invalidate after a successful submit/reply so
/// reopening the list picks up the new data.
final academyInquiryListProvider =
    FutureProvider.family<List<AcademyInquiry>, String>((ref, academyId) {
      final repo = ref.watch(academyInquiryRepositoryProvider);
      return repo.listByAcademy(academyId);
    });
