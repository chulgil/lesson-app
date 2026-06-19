import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/presentation/providers/lesson_selection_provider.dart';

/// Unit tests for the schedule multi-select state (#768 ①).
void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  LessonSelection notifier() =>
      container.read(lessonSelectionProvider.notifier);
  Set<String> state() => container.read(lessonSelectionProvider);

  test('starts empty (selection mode off)', () {
    expect(state(), isEmpty);
  });

  test('toggle adds then removes (exits when last removed)', () {
    notifier().toggle('a');
    expect(state(), {'a'});
    notifier().toggle('b');
    expect(state(), {'a', 'b'});
    notifier().toggle('a');
    expect(state(), {'b'});
    notifier().toggle('b');
    expect(state(), isEmpty);
  });

  test('selectAll replaces the selection', () {
    notifier().toggle('x');
    notifier().selectAll(['a', 'b', 'c']);
    expect(state(), {'a', 'b', 'c'});
  });

  test('clear empties the selection', () {
    notifier().selectAll(['a', 'b']);
    notifier().clear();
    expect(state(), isEmpty);
  });
}
