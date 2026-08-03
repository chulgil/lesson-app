// Journey sticker catalog providers (P3b Daily Satisfaction — doc 46 §5).

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../../core/sync/revalidation_events_provider.dart';
import '../../data/repositories/mock_journey_sticker_repository.dart';
import '../../data/repositories/remote_journey_sticker_repository.dart';
import '../../domain/entities/journey_sticker.dart';
import '../../domain/repositories/journey_sticker_repository.dart';

part 'journey_sticker_provider.g.dart';

@Riverpod(keepAlive: true)
JourneyStickerRepository journeyStickerRepository(
  JourneyStickerRepositoryRef ref,
) => createRepository<JourneyStickerRepository>(
  ref: ref,
  mock: () => MockJourneyStickerRepository(),
  remote: (api) => RemoteJourneyStickerRepository(api),
);

@riverpod
Future<JourneyStickerCatalog> journeyStickerCatalog(
  JourneyStickerCatalogRef ref,
  String studentId,
) async {
  ref.autoRevalidate('/gamification');
  final repository = ref.watch(journeyStickerRepositoryProvider);
  return repository.getCatalog(studentId);
}
