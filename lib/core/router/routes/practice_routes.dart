// Practice route definitions

import 'package:go_router/go_router.dart';

import '../../../features/practice/presentation/screens/practice_repertoire_screen.dart';
import '../../../features/practice/presentation/screens/add_repertoire_screen.dart';
import '../../../features/practice/presentation/screens/repertoire_detail_screen.dart';
import '../../../features/practice/presentation/screens/practice_recording_screen.dart';
import '../../../features/practice/presentation/screens/add_section_screen.dart';
import '../../../features/practice/presentation/screens/section_detail_screen.dart';
import '../../../features/practice/presentation/screens/repertoire_archive_screen.dart';
import '../../../features/practice/presentation/screens/practice_note_list_screen.dart';
import '../../../features/practice/presentation/screens/practice_goal_setting_screen.dart';
import '../../../features/practice/presentation/screens/practice_stats_screen.dart';
import '../app_routes.dart';

/// Practice routes
List<GoRoute> practiceRoutes = [
  // Repertoire List
  GoRoute(
    path: AppRoutes.practiceRepertoire,
    name: 'practiceRepertoire',
    builder: (context, state) {
      final studentId = state.uri.queryParameters['studentId'] ?? '';
      return PracticeRepertoireScreen(studentId: studentId);
    },
  ),

  // Add Repertoire
  GoRoute(
    path: AppRoutes.addRepertoire,
    name: 'addRepertoire',
    builder: (context, state) {
      final studentId = state.uri.queryParameters['studentId'] ?? '';
      return AddRepertoireScreen(studentId: studentId);
    },
  ),

  // Repertoire Detail
  GoRoute(
    path: AppRoutes.repertoireDetail,
    name: 'repertoireDetail',
    builder: (context, state) {
      final repertoireId = state.pathParameters['id'] ?? '';
      final studentId = state.uri.queryParameters['studentId'] ?? '';
      return RepertoireDetailScreen(
        repertoireId: repertoireId,
        studentId: studentId,
      );
    },
  ),

  // Practice Recording
  GoRoute(
    path: AppRoutes.practiceRecording,
    name: 'practiceRecording',
    builder: (context, state) {
      final repertoireId = state.pathParameters['repertoireId'] ?? '';
      final studentId = state.uri.queryParameters['studentId'] ?? '';
      final repertoireName = state.uri.queryParameters['name'] ?? '';
      return PracticeRecordingScreen(
        repertoireId: repertoireId,
        repertoireName: repertoireName,
        studentId: studentId,
      );
    },
  ),

  // Add Section
  GoRoute(
    path: AppRoutes.addSection,
    name: 'addSection',
    builder: (context, state) {
      final repertoireId = state.uri.queryParameters['repertoireId'] ?? '';
      final studentId = state.uri.queryParameters['studentId'] ?? '';
      return AddSectionScreen(
        repertoireId: repertoireId,
        studentId: studentId,
      );
    },
  ),

  // Section Detail
  GoRoute(
    path: AppRoutes.sectionDetail,
    name: 'sectionDetail',
    builder: (context, state) {
      final sectionId = state.pathParameters['id'] ?? '';
      final repertoireId = state.uri.queryParameters['repertoireId'] ?? '';
      final studentId = state.uri.queryParameters['studentId'] ?? '';
      final dateStr = state.uri.queryParameters['date'];
      final selectedDate = dateStr != null ? DateTime.tryParse(dateStr) : null;
      return SectionDetailScreen(
        sectionId: sectionId,
        repertoireId: repertoireId,
        studentId: studentId,
        selectedDate: selectedDate,
      );
    },
  ),

  // Practice Archive
  GoRoute(
    path: AppRoutes.practiceArchive,
    name: 'practiceArchive',
    builder: (context, state) {
      final studentId = state.uri.queryParameters['studentId'] ?? '';
      return RepertoireArchiveScreen(studentId: studentId);
    },
  ),

  // Practice Notes
  GoRoute(
    path: AppRoutes.practiceNotes,
    name: 'practiceNotes',
    builder: (context, state) {
      final sectionId = state.pathParameters['sectionId'] ?? '';
      final sectionName = state.uri.queryParameters['name'] ?? '';
      return PracticeNoteListScreen(
        sectionId: sectionId,
        sectionName: sectionName,
      );
    },
  ),

  // Practice Goal Settings
  GoRoute(
    path: AppRoutes.practiceGoalSettings,
    name: 'practiceGoalSettings',
    builder: (context, state) {
      final studentId = state.uri.queryParameters['studentId'] ?? '';
      return PracticeGoalSettingScreen(studentId: studentId);
    },
  ),

  // Practice Stats
  GoRoute(
    path: AppRoutes.practiceStats,
    name: 'practiceStats',
    builder: (context, state) {
      final studentId = state.uri.queryParameters['studentId'] ?? '';
      return PracticeStatsScreen(studentId: studentId);
    },
  ),
];
