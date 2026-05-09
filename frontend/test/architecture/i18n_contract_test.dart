import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter l10n ARB infrastructure is present', () {
    final l10nConfig = File('l10n.yaml');
    expect(l10nConfig.existsSync(), isTrue);

    final config = l10nConfig.readAsStringSync();
    expect(config, contains('arb-dir: lib/core/l10n/arb'));
    expect(config, contains('output-dir: lib/core/l10n/generated'));

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('generate: true'));

    final koArb = File('lib/core/l10n/arb/app_ko.arb');
    final enArb = File('lib/core/l10n/arb/app_en.arb');
    expect(koArb.existsSync(), isTrue);
    expect(enArb.existsSync(), isTrue);

    final ko = jsonDecode(koArb.readAsStringSync()) as Map<String, dynamic>;
    final en = jsonDecode(enArb.readAsStringSync()) as Map<String, dynamic>;
    expect(ko['@@locale'], 'ko');
    expect(en['@@locale'], 'en');
    expect(
      ko.keys.where((key) => !key.startsWith('@')).toSet(),
      en.keys.where((key) => !key.startsWith('@')).toSet(),
    );
  });

  test('MaterialApp is wired to generated AppLocalizations', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(
      main,
      contains("import 'core/l10n/generated/app_localizations.dart';"),
    );
    expect(main, contains('AppLocalizations.delegate'));
    expect(main, contains('AppLocalizations.supportedLocales'));
  });

  test('student and parent bottom navigation labels use AppStrings', () {
    final targetFiles = [
      File(
        'lib/features/student_home/presentation/screens/student_home_screen.dart',
      ),
      File(
        'lib/features/parent_home/presentation/screens/parent_home_screen.dart',
      ),
    ];
    final hardcodedLabels = RegExp(
      r"_buildNavItem\([^,]+,\s*'[^']+',\s*'[^']*[가-힣][^']*'\)",
    );
    final violations = <String>[];

    for (final file in targetFiles) {
      final content = file.readAsStringSync();
      if (hardcodedLabels.hasMatch(content)) {
        violations.add(file.path);
      }
      expect(content, contains('core/l10n/app_strings.dart'));
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Bottom navigation labels are high-traffic UI text and must not be hardcoded.',
    );
  });

  test('high-traffic billing and account UI text uses AppStrings', () {
    final prohibited = <String, List<String>>{
      'lib/features/billing/presentation/screens/billing_plans_screen.dart': [
        "'얼리어답터 한정 (90일)'",
        "'영구 이용'",
        "'현재 플랜'",
        "'현재'",
      ],
      'lib/features/student_home/presentation/screens/student_profile_tab.dart':
          ["'계정 삭제'"],
    };

    final violations = <String>[];
    for (final entry in prohibited.entries) {
      final content = File(entry.key).readAsStringSync();
      for (final literal in entry.value) {
        if (content.contains(literal)) {
          violations.add('${entry.key}: $literal');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'High-traffic billing/account labels must be centralized through AppStrings.',
    );
  });
}
