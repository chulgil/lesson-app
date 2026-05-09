import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'screens should prefer app bar add action over duplicate in-body add CTA',
    () {
      final files = _presentationScreenDartFiles('lib/features');
      final violations = <String>[];

      for (final file in files) {
        final source = file.readAsStringSync();
        if (!_hasHeaderAddAction(source)) continue;
        if (_hasInBodyDuplicateAddAction(source)) {
          violations.add(file.path.replaceAll('\\', '/'));
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            '아래 화면은 헤더 + 액션과 동일한 의미의 바디 add CTA를 동시에 노출하고 있습니다. 헤더 액션 우선 규칙에 따라 중복을 제거하세요.',
      );
    },
  );
}

List<File> _presentationScreenDartFiles(String root) {
  final directory = Directory(root);
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => file.path.contains('/presentation/screens/'))
      .where((file) => !file.path.endsWith('.g.dart'))
      .toList();
}

bool _hasHeaderAddAction(String source) {
  if (source.contains('DetailAppBarAction.add')) return true;

  var cursor = 0;
  while (true) {
    final appBarIndex = source.indexOf('AppBar(', cursor);
    if (appBarIndex == -1) return false;

    final actionsIndex = source.indexOf('actions:', appBarIndex);
    if (actionsIndex != -1) {
      final bracketStart = source.indexOf('[', actionsIndex);
      if (bracketStart != -1) {
        final bracketEnd = _findMatchingBracket(source, bracketStart);
        if (bracketEnd != -1) {
          final actionsBlock = source.substring(actionsIndex, bracketEnd + 1);
          if (_containsAddActionIcon(actionsBlock)) {
            return true;
          }
        }
      }
    }

    cursor = appBarIndex + 7;
  }
}

bool _containsAddActionIcon(String block) {
  return block.contains('IconButton(') &&
      _containsExactAddIcon(block) &&
      block.contains('onPressed');
}

bool _hasInBodyDuplicateAddAction(String source) {
  return _hasFloatingActionAdd(source) ||
      _hasEmptyStateAddAction(source) ||
      _hasLabeledButtonAddAction(source, 'FilledButton.icon') ||
      _hasLabeledButtonAddAction(source, 'OutlinedButton.icon') ||
      _hasLabeledButtonAddAction(source, 'ElevatedButton.icon') ||
      _hasTextButtonAddAction(source) ||
      _hasTextPrimaryBottomAddAction(source);
}

bool _hasFloatingActionAdd(String source) {
  final fabIndex = source.indexOf('floatingActionButton:');
  if (fabIndex == -1) return false;

  final openParen = source.indexOf('(', fabIndex);
  if (openParen == -1) return false;

  final closeParen = _findMatchingParen(source, openParen);
  if (closeParen == -1) return false;

  final block = source.substring(fabIndex, closeParen + 1);
  return _containsExactAddIcon(block) ||
      block.contains('Icons.person_add') ||
      _containsExactAddText(block);
}

bool _hasEmptyStateAddAction(String source) {
  var cursor = 0;
  while (true) {
    final widgetIndex = source.indexOf('EmptyStateWidget(', cursor);
    if (widgetIndex == -1) return false;

    final openParen = source.indexOf('(', widgetIndex);
    final closeParen = _findMatchingParen(source, openParen);
    if (closeParen == -1) return false;

    final block = source.substring(widgetIndex, closeParen + 1);
    if (block.contains('actionLabel:') &&
        block.contains('actionIcon:') &&
        block.contains('onAction:') &&
        _containsExactAddIcon(block)) {
      return true;
    }

    cursor = closeParen + 1;
  }
}

bool _hasLabeledButtonAddAction(String source, String buttonType) {
  var cursor = 0;
  while (true) {
    final index = source.indexOf('$buttonType(', cursor);
    if (index == -1) return false;

    final openParen = source.indexOf('(', index);
    final closeParen = _findMatchingParen(source, openParen);
    if (closeParen == -1) return false;

    final block = source.substring(index, closeParen + 1);
    if (_containsExactAddIcon(block) && block.contains('onPressed:')) {
      return true;
    }

    cursor = closeParen + 1;
  }
}

bool _hasTextPrimaryBottomAddAction(String source) {
  return source.contains('_FineActionBar(');
}

bool _hasTextButtonAddAction(String source) {
  var cursor = 0;
  while (true) {
    final index = source.indexOf('TextButton(', cursor);
    if (index == -1) return false;

    final openParen = source.indexOf('(', index);
    final closeParen = _findMatchingParen(source, openParen);
    if (closeParen == -1) return false;

    final block = source.substring(index, closeParen + 1);
    if ((block.contains('Icons.add') || _containsExactAddText(block)) &&
        block.contains('onPressed:')) {
      return true;
    }

    cursor = closeParen + 1;
  }
}

bool _containsExactAddIcon(String source) {
  return RegExp(r'Icons\.add(?![_a-zA-Z0-9])').hasMatch(source);
}

bool _containsExactAddText(String source) {
  return source.contains('추가') ||
      RegExp(r'AppStrings\.[a-zA-Z0-9_]*[Aa]dd').hasMatch(source);
}

int _findMatchingParen(String source, int openIndex) {
  var depth = 0;
  for (var i = openIndex; i < source.length; i++) {
    final char = source[i];
    if (char == '(') {
      depth++;
    } else if (char == ')') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

int _findMatchingBracket(String source, int openIndex) {
  var depth = 0;
  for (var i = openIndex; i < source.length; i++) {
    final char = source[i];
    if (char == '[') {
      depth++;
    } else if (char == ']') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}
