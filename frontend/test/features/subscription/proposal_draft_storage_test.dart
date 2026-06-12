import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/subscription/data/repositories/proposal_draft_storage.dart';

void main() {
  late Directory tempDir;
  late ProposalDraftStorage storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('draft_storage_test');
    Hive.init(tempDir.path);
    storage = ProposalDraftStorage();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('save then load returns the draft with form values', () async {
    await storage.save(
      userId: 'u1',
      studentId: 's1',
      templateId: 'tpl-1',
      amount: 320000,
      totalLessons: 8,
      validityDays: 90,
      membershipId: 'm-1',
    );

    final result = await storage.load('u1', 's1');

    expect(result.expiredDiscarded, isFalse);
    final draft = result.draft;
    expect(draft, isNotNull);
    expect(draft!.templateId, 'tpl-1');
    expect(draft.amount, 320000);
    expect(draft.totalLessons, 8);
    expect(draft.validityDays, 90);
    expect(draft.membershipId, 'm-1');
    expect(draft.ageDays, 0);
  });

  test('load is user-scoped — another user sees no draft', () async {
    await storage.save(
      userId: 'u1',
      studentId: 's1',
      templateId: null,
      amount: 100000,
      totalLessons: 4,
      validityDays: 30,
      membershipId: null,
    );

    final other = await storage.load('u2', 's1');
    expect(other.draft, isNull);
    expect(other.expiredDiscarded, isFalse);
  });

  test('draft older than 7 days is auto-discarded and flagged', () async {
    // Inject a stale payload directly (savedAt 8 days ago).
    final box = await Hive.openBox('proposal_drafts');
    await box.put(
      'teacher:u1:proposal_draft:s1',
      jsonEncode({
        'templateId': 'tpl-1',
        'amount': 320000,
        'totalLessons': 8,
        'validityDays': 90,
        'membershipId': 'm-1',
        'savedAt':
            DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
      }),
    );

    final result = await storage.load('u1', 's1');

    expect(result.draft, isNull);
    expect(result.expiredDiscarded, isTrue);
    // Discard is permanent — a second load reports no draft, no expiry.
    final second = await storage.load('u1', 's1');
    expect(second.draft, isNull);
    expect(second.expiredDiscarded, isFalse);
  });

  test('delete removes the draft', () async {
    await storage.save(
      userId: 'u1',
      studentId: 's1',
      templateId: null,
      amount: 1,
      totalLessons: 1,
      validityDays: 7,
      membershipId: null,
    );
    await storage.delete('u1', 's1');

    final result = await storage.load('u1', 's1');
    expect(result.draft, isNull);
  });
}
