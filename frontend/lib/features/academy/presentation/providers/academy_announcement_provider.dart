import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_academy_announcement_repository.dart';
import '../../data/repositories/remote_academy_announcement_repository.dart';
import '../../domain/entities/academy_announcement.dart';
import '../../domain/repositories/academy_announcement_repository.dart';

part 'academy_announcement_provider.g.dart';

// Provider for AcademyAnnouncementRepository — switches Mock ↔ Remote (#554 영역 4).
@Riverpod(keepAlive: true)
AcademyAnnouncementRepository academyAnnouncementRepository(Ref ref) =>
    createRepository<AcademyAnnouncementRepository>(
      ref: ref,
      mock: () => MockAcademyAnnouncementRepository(),
      remote: (api) => RemoteAcademyAnnouncementRepository(api),
    );

// Provider for listing academy announcements (received by members).
@riverpod
Future<List<AcademyAnnouncement>> academyAnnouncements(
  Ref ref,
  String academyId,
) async {
  final repository = ref.watch(academyAnnouncementRepositoryProvider);
  return repository.listByAcademy(academyId);
}
