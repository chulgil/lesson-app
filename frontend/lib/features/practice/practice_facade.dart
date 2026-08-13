// 연습 기능의 공개 조회 및 액션 provider 진입점입니다.
library;

export 'domain/entities/practice_item.dart';
export 'domain/entities/practice_log.dart';
export 'domain/entities/practice_note.dart';
export 'domain/entities/practice_repertoire.dart';
export 'domain/entities/repertoire_sort_type.dart';
export 'domain/entities/metronome_settings.dart'
    show
        AccentPattern,
        MetronomeSettings,
        MetronomeSound,
        Subdivision,
        TimeSignature;
export 'domain/entities/student_practice_overview.dart'
    show DailyPracticeEntry, SharedRecording, StudentPracticeOverview;
export 'presentation/providers/metronome_provider.dart'
    show Metronome, MetronomeState, metronomeProvider;
export 'presentation/providers/piece_crud_provider.dart'
    show
        PiecesNotifier,
        StudentRepertoireNotifier,
        piecesNotifierProvider,
        pieceSearchQueryProvider,
        studentRepertoireNotifierProvider;
export 'presentation/providers/practice_crud_provider.dart';
export 'presentation/providers/practice_goal_provider.dart'
    show
        defaultDailyGoalMinutes,
        effectiveDailyGoalMinutesProvider,
        practiceGoalProvider;
export 'presentation/providers/practice_item_providers.dart';
export 'presentation/providers/practice_loop_stats_provider.dart'
    show practiceLoopStatsSummaryProvider;
export 'presentation/providers/practice_note_provider.dart'
    show
        PracticeNoteCrud,
        practiceNoteCrudProvider,
        practiceNoteRepositoryProvider,
        sectionNotesProvider;
export 'presentation/providers/practice_overview_provider.dart'
    show studentPracticeOverviewProvider;
export 'presentation/providers/practice_repertoire_crud_provider.dart';
export 'presentation/providers/practice_repertoire_repository_provider.dart'
    show practiceRepertoireRepositoryProvider;
export 'presentation/providers/practice_streak_provider.dart'
    show
        currentUserStreakProvider,
        practiceStreakProvider,
        streakNotifierProvider;
export 'presentation/providers/recording_feedback_provider.dart'
    show recordingFeedbackCountProvider;
export 'presentation/providers/recording_provider.dart'
    show
        audioPlayerServiceProvider,
        audioRecorderServiceProvider,
        microphonePermissionProvider,
        RecordingState,
        recordingNotifierProvider;
export 'presentation/providers/repertoire_archive_provider.dart'
    show activeRepertoiresProvider;
export 'presentation/providers/repertoire_sort_provider.dart';
export 'presentation/widgets/goal/goal_progress_widget.dart'
    show GoalProgressWidget;
export 'presentation/providers/smart_recording_provider.dart'
    show smartRecordingNotifierProvider, smartRecordingSettingsNotifierProvider;
