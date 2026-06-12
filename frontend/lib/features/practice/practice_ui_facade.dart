// Practice feature public UI boundary.
library;

export 'presentation/screens/section_picker_screen.dart'
    show SectionPickerResult, SectionPickerScreen;
export 'presentation/widgets/recording_player_sheet.dart'
    show RecordingPlayerSheet;
export 'presentation/widgets/note/practice_note_card.dart'
    show PracticeNoteCard;
export 'presentation/widgets/note_access_active_banner.dart'
    show NoteAccessActiveBanner;
export 'presentation/widgets/notes/note_edit_dialog.dart' show NoteEditDialog;
export 'presentation/widgets/teacher_feedback_sheet.dart'
    show TeacherFeedbackSheet;
export 'presentation/widgets/youtube/section_video_affordance.dart'
    show SectionVideoAffordance;
// 학생 P1 — gamification [연습 시작] 진입점이 메트로놈 modal 을 호출.
export 'presentation/widgets/practice_tools_modal.dart' show PracticeToolsModal;
