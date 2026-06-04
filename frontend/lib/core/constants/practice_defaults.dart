/// Practice defaults — fixed identifiers and display names for the
/// quick-recording (바로 녹음) feature.
///
/// Spec: `docs/specs/practice/practice_master.md` §4.3.3.
///
/// The default repertoire ("무제") and section ("바로 녹음") are
/// auto-created once per student. The constants here are the **suffix**
/// templates: real IDs are scoped per student via
/// [defaultRepertoireIdFor] / [defaultQuickRecordSectionIdFor].
class PracticeDefaults {
  PracticeDefaults._();

  /// Suffix appended to a studentId to form the default repertoire ID.
  static const String repertoireIdSuffix = 'default_repertoire';

  /// Suffix appended to a studentId to form the default quick-record section ID.
  static const String quickRecordSectionIdSuffix =
      'default_quick_record_section';

  /// Display name of the default repertoire ("무제").
  static const String repertoireName = '무제';

  /// Display name of the default quick-record section ("바로 녹음").
  static const String quickRecordSectionName = '바로 녹음';

  /// Resolve the default repertoire ID for a given student.
  static String defaultRepertoireIdFor(String studentId) =>
      '${studentId}__$repertoireIdSuffix';

  /// Resolve the default quick-record section ID for a given student.
  static String defaultQuickRecordSectionIdFor(String studentId) =>
      '${studentId}__$quickRecordSectionIdSuffix';

  /// Whether the given repertoire ID matches the default suffix for any student.
  static bool isDefaultRepertoireId(String id) =>
      id.endsWith('__$repertoireIdSuffix');

  /// Whether the given section ID matches the default quick-record suffix.
  static bool isDefaultQuickRecordSectionId(String id) =>
      id.endsWith('__$quickRecordSectionIdSuffix');
}
