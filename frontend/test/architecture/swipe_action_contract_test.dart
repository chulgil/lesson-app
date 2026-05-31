import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editable template management cards use SwipeActionTile', () {
    const paths = [
      'lib/features/profile/presentation/screens/feedback_template_management_screen.dart',
      'lib/features/profile/presentation/screens/tip_template_management_screen.dart',
    ];

    for (final path in paths) {
      final source = File(path).readAsStringSync();

      expect(source, contains('SwipeActionTile('), reason: path);
      expect(source, isNot(contains('Dismissible(')), reason: path);
      expect(source, contains('AppStrings.swipeActionEdit'), reason: path);
    }
  });

  test('editable note list rows use SwipeActionTile instead of popup menus', () {
    const path =
        'lib/features/practice/presentation/widgets/notes/note_list_item.dart';
    final source = File(path).readAsStringSync();

    expect(source, contains('SwipeActionTile('), reason: path);
    expect(source, isNot(contains('PopupMenuButton')), reason: path);
    expect(source, contains('AppStrings.swipeActionEdit'), reason: path);
  });
}
