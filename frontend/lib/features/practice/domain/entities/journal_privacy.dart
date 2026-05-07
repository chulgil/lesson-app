/// Privacy scope for a practice journal.
///
/// - [JournalPrivacy.private]: only the owner can view the journal.
/// - [JournalPrivacy.partial]: a limited journal view can be shared.
/// - [JournalPrivacy.shared]: the full journal can be shared.
enum JournalPrivacy { private, partial, shared }

extension JournalPrivacyStorage on JournalPrivacy {
  /// Stable value used for local persistence.
  String get storageValue => name;

  /// Whether the journal is visible only to the owner.
  bool get isPrivate => this == JournalPrivacy.private;

  /// Whether the journal is shared in a limited form.
  bool get isPartial => this == JournalPrivacy.partial;

  /// Whether the journal is fully shared.
  bool get isShared => this == JournalPrivacy.shared;

  /// Whether a teacher can see anything from this journal.
  bool get isTeacherVisible => this != JournalPrivacy.private;
}

JournalPrivacy journalPrivacyFromStorageValue(String? value) {
  switch (value) {
    case 'partial':
      return JournalPrivacy.partial;
    case 'shared':
      return JournalPrivacy.shared;
    case 'private':
    default:
      return JournalPrivacy.private;
  }
}
