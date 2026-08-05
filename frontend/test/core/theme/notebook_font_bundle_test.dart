// Regression guard for the notebook signature-font bundle.
//
// The signature typography (Playfair Display / Gaegu / IBM Plex Mono) is served
// by the google_fonts package. `app_bootstrap.dart` sets
// `GoogleFonts.config.allowRuntimeFetching = false`, so google_fonts loads the
// fonts ONLY from the bundled assets under `assets/google_fonts/` and never
// fetches them over the network. That makes the signature fonts render
// identically offline instead of silently falling back to the default sans
// (which is why signature titles looked the same as body text before bundling).
//
// The invariant that makes `allowRuntimeFetching = false` safe: EVERY
// `GoogleFonts.<family>(...)` variant used anywhere in lib/ must have a matching
// bundled asset. If it does not, google_fonts throws at render time. This test
// enforces that invariant by scanning the source and asserting an asset exists
// for each used (family, weight, style) — using google_fonts 8.x's own
// `{Family}-{Variant}.ttf` filename convention.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// google_fonts family method -> API family name (space-free, PascalCase — the
// literal passed to fontFamily inside the generated google_fonts methods).
const _familyName = {
  'playfairDisplay': 'PlayfairDisplay',
  'gaegu': 'Gaegu',
  'ibmPlexMono': 'IBMPlexMono',
  'notoSerifKr': 'NotoSerifKR',
};

// FontWeight.wNNN -> google_fonts filename weight part (toApiFilenamePart).
const _weightPart = {
  100: 'Thin',
  200: 'ExtraLight',
  300: 'Light',
  400: 'Regular',
  500: 'Medium',
  600: 'SemiBold',
  700: 'Bold',
  800: 'ExtraBold',
  900: 'Black',
};

String _variantFilename(String family, int weight, bool italic) {
  final wp = _weightPart[weight] ?? 'Regular';
  final String part;
  if (wp == 'Regular') {
    part = italic ? 'Italic' : 'Regular';
  } else {
    part =
        italic
            ? '$wp'
                'Italic'
            : wp;
  }
  return '$family-$part.ttf';
}

void main() {
  test(
    'every GoogleFonts variant used in lib/ is bundled under assets/google_fonts/',
    () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'run from frontend/');

      final bundleDir = Directory('assets/google_fonts');
      expect(
        bundleDir.existsSync(),
        isTrue,
        reason: 'assets/google_fonts/ must exist',
      );
      final bundled =
          bundleDir
              .listSync()
              .whereType<File>()
              .map((f) => f.uri.pathSegments.last)
              .where((n) => n.endsWith('.ttf'))
              .toSet();

      // Match GoogleFonts.<family>( ... ) up to the first close paren of the
      // args (font styles are single-call expressions in this codebase).
      final call = RegExp(
        r'GoogleFonts\.(playfairDisplay|gaegu|ibmPlexMono|notoSerifKr)\(([^;]*?)\)',
        dotAll: true,
      );
      final weightRe = RegExp(r'fontWeight:\s*FontWeight\.w(\d+)');
      final italicRe = RegExp(r'fontStyle:\s*FontStyle\.italic');

      final required = <String>{};
      final usages = <String, String>{}; // filename -> first file:line seen

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final src = entity.readAsStringSync();
        if (!src.contains('GoogleFonts.')) continue;
        for (final m in call.allMatches(src)) {
          final method = m.group(1)!;
          final body = m.group(2)!;
          final family = _familyName[method]!;
          final weight =
              int.tryParse(weightRe.firstMatch(body)?.group(1) ?? '') ?? 400;
          final italic = italicRe.hasMatch(body);
          final fn = _variantFilename(family, weight, italic);
          required.add(fn);
          usages.putIfAbsent(fn, () => entity.path);
        }
      }

      expect(
        required,
        isNotEmpty,
        reason: 'sanity: lib/ should reference GoogleFonts',
      );

      final missing = required.difference(bundled).toList()..sort();
      expect(
        missing,
        isEmpty,
        reason:
            'These GoogleFonts variants are used in lib/ but not bundled under '
            'assets/google_fonts/. With allowRuntimeFetching=false they throw at '
            'render time. Download the static instance and add it, or drop the '
            'usage.\n'
            '${missing.map((fn) => '  - $fn  (first used in ${usages[fn]})').join('\n')}',
      );
    },
  );

  test('app_bootstrap disables google_fonts runtime fetching', () {
    final src = File('lib/core/startup/app_bootstrap.dart').readAsStringSync();
    expect(
      src.contains('GoogleFonts.config.allowRuntimeFetching = false'),
      isTrue,
      reason:
          'bootstrap must force bundle-only loading so signature fonts render '
          'offline; removing this reintroduces the network-fallback bug.',
    );
  });
}
