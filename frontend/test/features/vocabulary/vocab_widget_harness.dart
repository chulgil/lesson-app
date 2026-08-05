import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_card.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_set.dart';
import 'package:lessonaza/features/vocabulary/domain/repositories/vocab_repository.dart';
import 'package:lessonaza/features/vocabulary/presentation/providers/vocab_repository_provider.dart';

/// In-memory [VocabRepository] fake for widget tests (#1124 PR-2).
///
/// Its futures complete on the microtask queue (no real dart:io), so
/// `pumpAndSettle` advances them — unlike the real Hive store, whose file I/O
/// never completes inside flutter_test's fake-async zone. The Hive
/// implementation itself is covered by `local_vocab_repository_test`.
class InMemoryVocabRepository implements VocabRepository {
  final Map<String, VocabSet> _sets = {};
  final Map<String, List<VocabCard>> _cards = {};

  @override
  Future<List<VocabSet>> getSets() async =>
      _sets.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<void> saveSet(VocabSet set) async => _sets[set.id] = set;

  @override
  Future<void> deleteSet(String setId) async {
    _sets.remove(setId);
    _cards.remove(setId);
  }

  @override
  Future<List<VocabCard>> getCards(String setId) async =>
      List<VocabCard>.of(_cards[setId] ?? const [])
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<void> saveCard(VocabCard card) async {
    final list = _cards.putIfAbsent(card.setId, () => <VocabCard>[]);
    final index = list.indexWhere((c) => c.id == card.id);
    if (index >= 0) {
      list[index] = card;
    } else {
      list.add(card);
    }
  }

  @override
  Future<void> deleteCard(String setId, String cardId) async =>
      _cards[setId]?.removeWhere((c) => c.id == cardId);
}

/// A repository whose every call throws — to exercise error/fallback branches.
class ThrowingVocabRepository implements VocabRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('vocab store unavailable');
}

/// Harness that pumps vocab widgets with the repository provider overridden by
/// an in-memory fake (#1124 PR-2 smoke tests).
class VocabHarness {
  final InMemoryVocabRepository repo = InMemoryVocabRepository();

  Future<void> start() async {}

  Future<void> stop() async {}

  Widget wrap(Widget child) => ProviderScope(
    overrides: [vocabRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

const vocabDesktop = Size(1440, 900);
const vocabMobile = Size(375, 812);
const vocabTall = Size(375, 3000);

/// Pump [widget] at [size] with deterministic pixel ratio and auto-reset.
Future<void> pumpVocabAt(WidgetTester tester, Size size, Widget widget) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}
