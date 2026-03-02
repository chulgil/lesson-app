// Provider for repertoire history timeline

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/repertoire_timeline.dart';
import 'practice_repertoire_crud_provider.dart';

part 'repertoire_history_provider.g.dart';

/// Provides a timeline of all repertoires for a student, grouped by month
@riverpod
Future<RepertoireTimeline> repertoireTimeline(
  RepertoireTimelineRef ref,
  String studentId,
) async {
  final repertoires = await ref.watch(
    studentRepertoiresProvider(studentId).future,
  );
  return RepertoireTimeline(repertoires: repertoires);
}
