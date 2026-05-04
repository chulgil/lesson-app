import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production UI uses NotebookCard instead of direct Material Card', () {
    final libDirectory = Directory('lib');
    final allowedFiles = {'lib/core/widgets/notebook/notebook_surfaces.dart'};

    final directCardUsages = <String>[];

    for (final file in libDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (allowedFiles.contains(normalizedPath)) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'(^|[^A-Za-z0-9_])Card\(').hasMatch(lines[i])) {
          directCardUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directCardUsages,
      isEmpty,
      reason:
          'Use NotebookCard so card surfaces keep the Notebook x Score SSOT.',
    );
  });

  test('production UI uses Notebook scaffold wrappers', () {
    final libDirectory = Directory('lib');
    final allowedFiles = {
      'lib/core/widgets/notebook/notebook_detail_scaffold.dart',
      'lib/core/widgets/notebook/notebook_screen_scaffold.dart',
    };

    final directScaffoldUsages = <String>[];

    for (final file in libDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (allowedFiles.contains(normalizedPath)) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'(^|[^A-Za-z0-9_])Scaffold\(').hasMatch(lines[i])) {
          directScaffoldUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directScaffoldUsages,
      isEmpty,
      reason:
          'Use NotebookScreenScaffold or NotebookDetailScaffold so every production screen follows the Notebook x Score SSOT.',
    );
  });

  test('production UI does not use raw white black or yellow colors', () {
    final libDirectory = Directory('lib');
    final allowedPrefixes = [
      'lib/core/theme/app_colors.dart',
      'lib/core/utils/image_utils.dart',
      'lib/features/invite/presentation/screens/scan_invite_screen.dart',
      'lib/features/practice/presentation/widgets/waveform/',
    ];

    final rawColorUsages = <String>[];
    final rawColorPattern = RegExp(
      r'Colors\.(white|yellow|black|black54|black87)\b',
    );

    for (final file in libDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (allowedPrefixes.any(normalizedPath.startsWith)) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (rawColorPattern.hasMatch(lines[i]) &&
            !lines[i].trimLeft().startsWith('//')) {
          rawColorUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      rawColorUsages,
      isEmpty,
      reason:
          'Use Notebook palette tokens such as AppColors.paper, inkScrim, or paperHighlight.',
    );
  });

  test('legacy UX guideline does not contradict Notebook color SSOT', () {
    final uxGuidelines = File('../docs/specs/design/ux_guidelines.md');
    final content = uxGuidelines.readAsStringSync();

    expect(
      content,
      isNot(
        contains('Colors.white`, `Colors.black`, `Colors.transparent`만 허용'),
      ),
      reason:
          'Notebook SSOT forbids raw white/black for UI surfaces; legacy guidelines must point to AppColors tokens.',
    );
    expect(
      content,
      isNot(contains('Colors.black.withValues')),
      reason:
          'Documentation examples should use AppColors.ink alpha tokens instead of raw Material black shadows.',
    );
  });

  test('schedule and subscription dialogs use NotebookAlertDialog', () {
    final libDirectory = Directory('lib/features');
    final allowedFiles = {
      'lib/features/schedule/presentation/widgets/availability/booking_confirm_dialog.dart',
    };

    final directAlertDialogUsages = <String>[];
    final targetPrefixes = [
      'lib/features/schedule/',
      'lib/features/subscription/',
    ];

    for (final file in libDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (!targetPrefixes.any(normalizedPath.startsWith)) continue;
      if (allowedFiles.contains(normalizedPath)) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'(^|[^A-Za-z0-9_])AlertDialog\(').hasMatch(lines[i])) {
          directAlertDialogUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directAlertDialogUsages,
      isEmpty,
      reason:
          'Use NotebookAlertDialog in schedule/subscription flows so popup surfaces follow the Notebook x Score SSOT.',
    );
  });

  test(
    'schedule and subscription sheet widgets use Notebook bottom sheet API',
    () {
      final libDirectory = Directory('lib/features');
      final allowedFiles = <String>{};

      final directBottomSheetUsages = <String>[];
      final targetPrefixes = [
        'lib/features/schedule/presentation/widgets/',
        'lib/features/subscription/presentation/widgets/',
      ];

      for (final file in libDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.endsWith('.g.dart'))) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        if (!targetPrefixes.any(normalizedPath.startsWith)) continue;
        if (allowedFiles.contains(normalizedPath)) continue;

        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (RegExp(r'showModalBottomSheet(?:<.*>)?\(').hasMatch(lines[i])) {
            directBottomSheetUsages.add('$normalizedPath:${i + 1}');
          }
        }
      }

      expect(
        directBottomSheetUsages,
        isEmpty,
        reason:
            'Reusable schedule/subscription sheets should enter through showNotebookBottomSheet.',
      );
    },
  );

  test('availability settings screens use Notebook bottom sheet API', () {
    final targetFiles = [
      File(
        'lib/features/schedule/presentation/screens/weekly_schedule_screen.dart',
      ),
      File(
        'lib/features/schedule/presentation/screens/teacher_availability_screen.dart',
      ),
    ];

    final directBottomSheetUsages = <String>[];
    for (final file in targetFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'showModalBottomSheet(?:<.*>)?\(').hasMatch(lines[i])) {
          directBottomSheetUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directBottomSheetUsages,
      isEmpty,
      reason:
          'Teacher availability setting sheets should enter through showNotebookBottomSheet.',
    );
  });

  test('schedule flow screens use Notebook bottom sheet API', () {
    final targetFiles = [
      File(
        'lib/features/schedule/presentation/screens/request_detail_screen.dart',
      ),
      File(
        'lib/features/schedule/presentation/screens/suggest_alternative_screen.dart',
      ),
      File(
        'lib/features/schedule/presentation/screens/time_exception_screen.dart',
      ),
      File(
        'lib/features/schedule/presentation/screens/booking_cancel_screen.dart',
      ),
      File(
        'lib/features/schedule/presentation/screens/pending_bookings_screen.dart',
      ),
    ];

    final directBottomSheetUsages = <String>[];
    for (final file in targetFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'showModalBottomSheet(?:<.*>)?\(').hasMatch(lines[i])) {
          directBottomSheetUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directBottomSheetUsages,
      isEmpty,
      reason:
          'Schedule request/cancel/exception sheets should enter through showNotebookBottomSheet.',
    );
  });

  test('schedule and subscription confirmation dialogs use Notebook dialog API', () {
    final targetFiles = [
      File(
        'lib/features/schedule/presentation/screens/booking_cancel_screen.dart',
      ),
      File(
        'lib/features/schedule/presentation/screens/booking_reschedule_screen.dart',
      ),
      File(
        'lib/features/schedule/presentation/screens/weekly_schedule_screen.dart',
      ),
      File(
        'lib/features/subscription/presentation/widgets/unified_subscription_sheet.dart',
      ),
    ];

    final directDialogUsages = <String>[];
    for (final file in targetFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'showDialog(?:<.*>)?\(').hasMatch(lines[i])) {
          directDialogUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directDialogUsages,
      isEmpty,
      reason:
          'Confirmation dialogs in schedule/subscription flows should enter through showNotebookDialog.',
    );
  });

  test('lesson confirmation dialogs use Notebook dialog API', () {
    final targetFiles = [
      File('lib/features/lessons/presentation/screens/add_lesson_screen.dart'),
      File('lib/features/lessons/presentation/screens/edit_lesson_screen.dart'),
      File(
        'lib/features/lessons/presentation/widgets/lesson_detail/lesson_notes_widgets.dart',
      ),
    ];

    final directDialogUsages = <String>[];
    for (final file in targetFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'showDialog(?:<.*>)?\(').hasMatch(lines[i])) {
          directDialogUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directDialogUsages,
      isEmpty,
      reason:
          'Lesson confirmation dialogs should enter through showNotebookDialog.',
    );
  });

  test('student home sheet widgets use Notebook bottom sheet API', () {
    final targetFiles = [
      File(
        'lib/features/student_home/presentation/widgets/language_select_sheet.dart',
      ),
      File(
        'lib/features/student_home/presentation/widgets/practice_reminder_sheet.dart',
      ),
    ];

    final directBottomSheetUsages = <String>[];
    for (final file in targetFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'showModalBottomSheet(?:<.*>)?\(').hasMatch(lines[i])) {
          directBottomSheetUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directBottomSheetUsages,
      isEmpty,
      reason:
          'Student-facing settings sheets should enter through showNotebookBottomSheet.',
    );
  });

  test('lesson flow sheets use Notebook bottom sheet API', () {
    final targetPrefixes = [
      'lib/features/lessons/presentation/screens/',
      'lib/features/lessons/presentation/widgets/',
    ];

    final directBottomSheetUsages = <String>[];
    final libDirectory = Directory('lib/features/lessons/presentation');
    for (final file in libDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (!targetPrefixes.any(normalizedPath.startsWith)) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'showModalBottomSheet(?:<.*>)?\(').hasMatch(lines[i])) {
          directBottomSheetUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directBottomSheetUsages,
      isEmpty,
      reason:
          'Lesson detail, resource, attendance, and feedback sheets should enter through Notebook bottom sheet APIs.',
    );
  });

  test('practice flow sheets use Notebook bottom sheet API', () {
    final libDirectory = Directory('lib/features/practice/presentation');
    final directBottomSheetUsages = <String>[];

    for (final file in libDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'showModalBottomSheet(?:<.*>)?\(').hasMatch(lines[i])) {
          directBottomSheetUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directBottomSheetUsages,
      isEmpty,
      reason:
          'Practice tools, recording, feedback, and section sheets should enter through Notebook bottom sheet APIs.',
    );
  });

  test('profile setting sheets use Notebook bottom sheet API', () {
    final libDirectory = Directory('lib/features/profile/presentation');
    final directBottomSheetUsages = <String>[];

    for (final file in libDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'showModalBottomSheet(?:<.*>)?\(').hasMatch(lines[i])) {
          directBottomSheetUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directBottomSheetUsages,
      isEmpty,
      reason:
          'Profile, lesson time, bank account, and template sheets should enter through Notebook bottom sheet APIs.',
    );
  });

  test('production UI routes bottom sheets through Notebook APIs', () {
    final allowedFiles = {
      'lib/core/widgets/notebook/notebook_bottom_sheet.dart',
    };
    final directBottomSheetUsages = <String>[];

    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (allowedFiles.contains(normalizedPath)) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'showModalBottomSheet(?:<.*>)?\(').hasMatch(lines[i])) {
          directBottomSheetUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directBottomSheetUsages,
      isEmpty,
      reason:
          'Use showNotebookBottomSheet or showNotebookModalBottomSheet so modal sheets share the Notebook x Score route contract.',
    );
  });

  test(
    'production UI uses NotebookAlertDialog instead of direct AlertDialog',
    () {
      final allowedFiles = {
        'lib/core/widgets/notebook/notebook_alert_dialog.dart',
      };
      final directAlertDialogUsages = <String>[];

      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.endsWith('.g.dart'))) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        if (allowedFiles.contains(normalizedPath)) continue;

        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (RegExp(r'(^|[^A-Za-z0-9_])AlertDialog\(').hasMatch(lines[i])) {
            directAlertDialogUsages.add('$normalizedPath:${i + 1}');
          }
        }
      }

      expect(
        directAlertDialogUsages,
        isEmpty,
        reason:
            'Use NotebookAlertDialog so popup surfaces share the Notebook x Score SSOT.',
      );
    },
  );

  test('schedule and subscription screens use Notebook scaffold wrappers', () {
    final targetDirectories = [
      Directory('lib/features/schedule/presentation/screens'),
      Directory('lib/features/subscription/presentation/screens'),
    ];
    final allowedFiles = {
      'lib/features/schedule/presentation/screens/schedule_tab.dart',
    };
    final directScaffoldUsages = <String>[];

    for (final directory in targetDirectories) {
      for (final file in directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.endsWith('.g.dart'))) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        if (allowedFiles.contains(normalizedPath)) continue;

        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (RegExp(r'(^|[^A-Za-z0-9_])Scaffold\(').hasMatch(lines[i])) {
            directScaffoldUsages.add('$normalizedPath:${i + 1}');
          }
        }
      }
    }

    expect(
      directScaffoldUsages,
      isEmpty,
      reason:
          'Schedule and subscription screens should use NotebookScreenScaffold or NotebookDetailScaffold so page surfaces share the Notebook x Score SSOT.',
    );
  });

  test('student home screens use Notebook scaffold wrappers', () {
    final directScaffoldUsages = <String>[];

    for (final file in Directory(
          'lib/features/student_home/presentation/screens',
        )
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'(^|[^A-Za-z0-9_])Scaffold\(').hasMatch(lines[i])) {
          directScaffoldUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directScaffoldUsages,
      isEmpty,
      reason:
          'Student-facing screens should use NotebookScreenScaffold so the student app surface does not drift from Notebook x Score.',
    );
  });

  test('profile setting screens use Notebook scaffold wrappers', () {
    final directScaffoldUsages = <String>[];

    for (final file in Directory('lib/features/profile/presentation/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'(^|[^A-Za-z0-9_])Scaffold\(').hasMatch(lines[i])) {
          directScaffoldUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directScaffoldUsages,
      isEmpty,
      reason:
          'Teacher profile and settings screens should use NotebookScreenScaffold so operational settings share the Notebook x Score page surface.',
    );
  });

  test('lesson screens use Notebook scaffold wrappers', () {
    final directScaffoldUsages = <String>[];

    for (final file in Directory('lib/features/lessons/presentation/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'(^|[^A-Za-z0-9_])Scaffold\(').hasMatch(lines[i])) {
          directScaffoldUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directScaffoldUsages,
      isEmpty,
      reason:
          'Lesson screens should use NotebookScreenScaffold so lesson recording, feedback, and detail surfaces stay in the Notebook x Score SSOT.',
    );
  });

  test('supporting teacher utility screens use Notebook scaffold wrappers', () {
    final targetDirectories = [
      Directory('lib/features/analytics/presentation/screens'),
      Directory('lib/features/home/presentation/screens'),
      Directory('lib/features/notifications/presentation/screens'),
      Directory('lib/features/settings/presentation/screens'),
    ];
    final directScaffoldUsages = <String>[];

    for (final directory in targetDirectories) {
      for (final file in directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.endsWith('.g.dart'))) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (RegExp(r'(^|[^A-Za-z0-9_])Scaffold\(').hasMatch(lines[i])) {
            directScaffoldUsages.add('$normalizedPath:${i + 1}');
          }
        }
      }
    }

    expect(
      directScaffoldUsages,
      isEmpty,
      reason:
          'Analytics, teacher home, notification, and settings utility screens should use NotebookScreenScaffold so supporting surfaces keep the Notebook x Score SSOT.',
    );
  });

  test('student management screens use Notebook scaffold wrappers', () {
    final directScaffoldUsages = <String>[];

    for (final file in Directory('lib/features/students/presentation/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'(^|[^A-Za-z0-9_])Scaffold\(').hasMatch(lines[i])) {
          directScaffoldUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directScaffoldUsages,
      isEmpty,
      reason:
          'Student roster, detail, add, edit, and bulk action screens should use NotebookScreenScaffold so student management surfaces keep the Notebook x Score SSOT.',
    );
  });

  test('practice screens use Notebook scaffold wrappers', () {
    final directScaffoldUsages = <String>[];

    for (final file in Directory('lib/features/practice/presentation/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'(^|[^A-Za-z0-9_])Scaffold\(').hasMatch(lines[i])) {
          directScaffoldUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directScaffoldUsages,
      isEmpty,
      reason:
          'Practice repertoire, section, recording, stats, and tuner screens should use NotebookScreenScaffold so practice surfaces keep the Notebook x Score SSOT.',
    );
  });

  test(
    'auth onboarding invite follow search and gamification screens use Notebook scaffold wrappers',
    () {
      final targetDirectories = [
        Directory('lib/features/auth/presentation/screens'),
        Directory('lib/features/onboarding/presentation/screens'),
        Directory('lib/features/invite/presentation/screens'),
        Directory('lib/features/follow/presentation/screens'),
        Directory('lib/features/search/presentation/screens'),
        Directory('lib/features/gamification/presentation/screens'),
      ];
      final directScaffoldUsages = <String>[];

      for (final directory in targetDirectories) {
        for (final file in directory
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where((file) => !file.path.endsWith('.g.dart'))) {
          final normalizedPath = file.path.replaceAll('\\', '/');
          final lines = file.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            if (RegExp(r'(^|[^A-Za-z0-9_])Scaffold\(').hasMatch(lines[i])) {
              directScaffoldUsages.add('$normalizedPath:${i + 1}');
            }
          }
        }
      }

      expect(
        directScaffoldUsages,
        isEmpty,
        reason:
            'Auth, onboarding, invite, follow, search, and gamification screens should use NotebookScreenScaffold so entry and discovery surfaces keep the Notebook x Score SSOT.',
      );
    },
  );

  test('parent home screens use Notebook scaffold wrappers', () {
    final directScaffoldUsages = <String>[];

    for (final file in Directory(
          'lib/features/parent_home/presentation/screens',
        )
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'(^|[^A-Za-z0-9_])Scaffold\(').hasMatch(lines[i])) {
          directScaffoldUsages.add('$normalizedPath:${i + 1}');
        }
      }
    }

    expect(
      directScaffoldUsages,
      isEmpty,
      reason:
          'Parent home, child profile, assignment, payment, and profile screens should use NotebookScreenScaffold so parent-facing surfaces keep the Notebook x Score SSOT.',
    );
  });
}
