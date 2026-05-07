import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/mock_youtube_search_api.dart';
import '../../domain/entities/youtube_search_result.dart';

part 'youtube_search_providers.g.dart';

/// Singleton mock API instance (swap for real implementation later)
@Riverpod(keepAlive: true)
MockYoutubeSearchApi youtubeSearchApi(YoutubeSearchApiRef ref) =>
    const MockYoutubeSearchApi();

/// Provider that executes a YouTube search for [query].
/// Returns an empty list when [query] is blank.
@riverpod
Future<List<YoutubeSearchResult>> youtubeSearch(
  YoutubeSearchRef ref,
  String query,
) async {
  if (query.trim().isEmpty) return const [];
  final api = ref.watch(youtubeSearchApiProvider);
  return api.search(query);
}
