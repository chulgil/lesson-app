import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/journal_privacy.dart';

void main() {
  test('exposes the three privacy tiers with stable storage values', () {
    expect(JournalPrivacy.private.storageValue, 'private');
    expect(JournalPrivacy.partial.storageValue, 'partial');
    expect(JournalPrivacy.shared.storageValue, 'shared');
  });

  test('maps storage values back to the matching privacy tier', () {
    expect(journalPrivacyFromStorageValue('private'), JournalPrivacy.private);
    expect(journalPrivacyFromStorageValue('partial'), JournalPrivacy.partial);
    expect(journalPrivacyFromStorageValue('shared'), JournalPrivacy.shared);
    expect(journalPrivacyFromStorageValue('unknown'), JournalPrivacy.private);
    expect(journalPrivacyFromStorageValue(null), JournalPrivacy.private);
  });

  test('describes teacher visibility semantics clearly', () {
    expect(JournalPrivacy.private.isPrivate, isTrue);
    expect(JournalPrivacy.private.isTeacherVisible, isFalse);

    expect(JournalPrivacy.partial.isPartial, isTrue);
    expect(JournalPrivacy.partial.isTeacherVisible, isTrue);
    expect(JournalPrivacy.partial.isShared, isFalse);

    expect(JournalPrivacy.shared.isShared, isTrue);
    expect(JournalPrivacy.shared.isTeacherVisible, isTrue);
  });
}
