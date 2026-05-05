import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('feature dependency contract', () {
    test(
      'cross-feature presentation provider imports are explicit legacy dependencies',
      () {
        final currentImports =
            _crossFeaturePresentationProviderImports().toList()..sort();
        final unexpectedImports =
            currentImports
                .where(
                  (dependency) =>
                      !_legacyCrossFeaturePresentationProviderImports.contains(
                        dependency,
                      ),
                )
                .toList();
        final staleBaseline =
            _legacyCrossFeaturePresentationProviderImports
                .where((dependency) => !currentImports.contains(dependency))
                .toList();

        expect(
          unexpectedImports,
          isEmpty,
          reason:
              'New code must not import another feature presentation provider directly. Use a feature facade, domain contract, or application service instead.',
        );
        expect(
          staleBaseline,
          isEmpty,
          reason:
              'When a legacy cross-feature presentation provider import is removed, update this baseline so the remaining debt stays visible.',
        );
      },
    );
  });
}

Iterable<String> _crossFeaturePresentationProviderImports() sync* {
  for (final file in _dartFilesUnder('lib/features')) {
    final sourceFeature = _featureNameForPath(file.path);
    if (sourceFeature == null || !file.path.contains('/presentation/')) {
      continue;
    }

    for (final uri in _importOrExportUris(file)) {
      final targetFeature = _featureNameForImportUri(file.path, uri);
      if (targetFeature == null || targetFeature == sourceFeature) continue;
      if (!_pointsToPresentationProvider(uri)) continue;

      yield '${file.path} -> $uri';
    }
  }
}

Iterable<File> _dartFilesUnder(String path) {
  return Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'));
}

List<String> _importOrExportUris(File file) {
  final source = file.readAsStringSync();
  return RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  ).allMatches(source).map((match) => match.group(1)!).toList();
}

String? _featureNameForPath(String path) {
  final match = RegExp(r'lib/features/([^/]+)/').firstMatch(path);
  return match?.group(1);
}

String? _featureNameForImportUri(String sourcePath, String uri) {
  final absoluteUriMatch =
      RegExp(r'package:lesson_app/features/([^/]+)/').firstMatch(uri) ??
      RegExp(r'(?:^|/)features/([^/]+)/').firstMatch(uri);
  if (absoluteUriMatch != null) return absoluteUriMatch.group(1);

  if (!uri.startsWith('.')) return null;

  final sourceUri = Directory.current.uri.resolve(sourcePath);
  final normalized = sourceUri.resolve(uri).path;
  final match = RegExp(r'/lib/features/([^/]+)/').firstMatch(normalized);
  return match?.group(1);
}

bool _pointsToPresentationProvider(String uri) =>
    uri.contains('/presentation/providers/') ||
    uri.startsWith('presentation/providers/');

const _legacyCrossFeaturePresentationProviderImports = <String>{
  'lib/features/home/presentation/providers/assignment_summary_provider.dart -> ../../../practice/presentation/providers/practice_item_providers.dart',
  'lib/features/home/presentation/providers/assignment_summary_provider.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/home/presentation/widgets/dashboard_tab.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/home/presentation/widgets/dashboard_tab.dart -> ../../../lessons/presentation/providers/booking_providers.dart',
  'lib/features/home/presentation/widgets/dashboard_tab.dart -> ../../../lessons/presentation/providers/lesson_confirmation_provider.dart',
  'lib/features/home/presentation/widgets/dashboard_tab.dart -> ../../../lessons/presentation/providers/lesson_crud_provider.dart',
  'lib/features/home/presentation/widgets/dashboard_tab.dart -> ../../../lessons/presentation/providers/lesson_stats_provider.dart',
  'lib/features/home/presentation/widgets/dashboard_tab.dart -> ../../../schedule/presentation/providers/unified_lesson_request_providers.dart',
  'lib/features/home/presentation/widgets/getting_started_card.dart -> ../../../lessons/presentation/providers/lesson_crud_provider.dart',
  'lib/features/home/presentation/widgets/getting_started_card.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/home/presentation/widgets/lesson_card.dart -> ../../../students/presentation/providers/lesson_class_providers.dart',
  'lib/features/home/presentation/widgets/lesson_card.dart -> ../../../students/presentation/providers/membership_providers.dart',
  'lib/features/home/presentation/widgets/lesson_request_section.dart -> ../../../schedule/presentation/providers/unified_lesson_request_providers.dart',
  'lib/features/home/presentation/widgets/schedule_change_request_section.dart -> ../../../schedule/presentation/providers/unified_lesson_request_providers.dart',
  'lib/features/home/presentation/widgets/schedule_change_request_section.dart -> ../../../subscription/presentation/providers/subscription_providers.dart',
  'lib/features/home/presentation/widgets/teacher_subscription_section.dart -> ../../../schedule/presentation/providers/unified_lesson_request_providers.dart',
  'lib/features/home/presentation/widgets/teacher_subscription_section.dart -> ../../../students/presentation/providers/lesson_class_providers.dart',
  'lib/features/home/presentation/widgets/teacher_subscription_section.dart -> ../../../students/presentation/providers/membership_providers.dart',
  'lib/features/home/presentation/widgets/teacher_subscription_section.dart -> ../../../subscription/presentation/providers/subscription_providers.dart',
  'lib/features/home/presentation/widgets/urgent_alert_zone.dart -> ../../../lessons/presentation/providers/booking_providers.dart',
  'lib/features/home/presentation/widgets/urgent_alert_zone.dart -> ../../../lessons/presentation/providers/lesson_confirmation_provider.dart',
  'lib/features/invite/presentation/screens/code_input_screen.dart -> ../../../../features/profile/presentation/providers/invite_provider.dart',
  'lib/features/invite/presentation/screens/invite_confirm_screen.dart -> ../../../../features/auth/presentation/providers/user_role_provider.dart',
  'lib/features/invite/presentation/screens/invite_confirm_screen.dart -> ../../../../features/profile/presentation/providers/invite_provider.dart',
  'lib/features/invite/presentation/screens/invite_confirm_screen.dart -> ../../../parent_home/presentation/providers/user_profile_provider.dart',
  'lib/features/invite/presentation/screens/invite_history_screen.dart -> ../../../../features/profile/presentation/providers/invite_provider.dart',
  'lib/features/invite/presentation/screens/invite_screen.dart -> ../../../../features/profile/presentation/providers/invite_provider.dart',
  'lib/features/invite/presentation/screens/my_connections_screen.dart -> ../../../../features/profile/presentation/providers/invite_provider.dart',
  'lib/features/invite/presentation/screens/pending_requests_screen.dart -> ../../../../features/profile/presentation/providers/invite_provider.dart',
  'lib/features/invite/presentation/screens/scan_invite_screen.dart -> ../../../../features/profile/presentation/providers/invite_provider.dart',
  'lib/features/lessons/presentation/providers/booking_providers.dart -> ../../../subscription/presentation/providers/subscription_lifecycle_service_providers.dart',
  'lib/features/lessons/presentation/providers/feedback_template_providers.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/lessons/presentation/providers/lesson_confirmation_provider.dart -> ../../../schedule/presentation/providers/unified_lesson_request_providers.dart',
  'lib/features/lessons/presentation/providers/payment_providers.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/lessons/presentation/providers/tip_template_providers.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/lessons/presentation/screens/add_lesson_screen.dart -> ../../../../features/profile/presentation/providers/teacher_extended_profile_provider.dart',
  'lib/features/lessons/presentation/screens/add_lesson_screen.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/lessons/presentation/screens/edit_lesson_screen.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/lessons/presentation/screens/lesson_detail_screen.dart -> ../../../subscription/presentation/providers/subscription_lifecycle_service_providers.dart',
  'lib/features/lessons/presentation/screens/teacher_attendance_screen.dart -> ../../../schedule/presentation/providers/unified_lesson_request_providers.dart',
  'lib/features/lessons/presentation/widgets/add_practice_item_sheet.dart -> ../../../practice/presentation/providers/practice_item_providers.dart',
  'lib/features/lessons/presentation/widgets/add_practice_item_sheet.dart -> ../../../practice/presentation/providers/practice_repertoire_crud_provider.dart',
  'lib/features/lessons/presentation/widgets/edit_practice_item_sheet.dart -> ../../../practice/presentation/providers/practice_item_providers.dart',
  'lib/features/lessons/presentation/widgets/lesson_form/lesson_location_section.dart -> ../../../../students/presentation/providers/location_providers.dart',
  'lib/features/lessons/presentation/widgets/practice_items_section.dart -> ../../../practice/presentation/providers/practice_item_providers.dart',
  'lib/features/notifications/presentation/providers/notification_providers.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/notifications/presentation/providers/subscription_expiry_providers.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/notifications/presentation/providers/subscription_expiry_providers.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/notifications/presentation/providers/subscription_expiry_providers.dart -> ../../../subscription/presentation/providers/subscription_providers.dart',
  'lib/features/onboarding/presentation/providers/onboarding_providers.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/onboarding/presentation/screens/student_profile_setup_screen.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/onboarding/presentation/screens/student_tutorial_screen.dart -> ../../../../features/auth/presentation/providers/user_role_provider.dart',
  'lib/features/onboarding/presentation/screens/student_tutorial_screen.dart -> ../../../auth/presentation/providers/auth_provider.dart',
  'lib/features/onboarding/presentation/screens/tutorial_screen.dart -> ../../../auth/presentation/providers/auth_provider.dart',
  'lib/features/parent_home/presentation/screens/parent_dashboard_tab.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/parent_home/presentation/screens/parent_payments_tab.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/parent_home/presentation/screens/parent_payments_tab.dart -> ../../../students/presentation/providers/lesson_class_providers.dart',
  'lib/features/parent_home/presentation/screens/parent_payments_tab.dart -> ../../../students/presentation/providers/membership_providers.dart',
  'lib/features/parent_home/presentation/screens/parent_payments_tab.dart -> ../../../subscription/presentation/providers/subscription_providers.dart',
  'lib/features/parent_home/presentation/screens/parent_profile_tab.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/parent_home/presentation/widgets/child_card.dart -> ../../../../features/students/presentation/providers/student_crud_provider.dart',
  'lib/features/practice/presentation/providers/practice_crud_provider.dart -> ../../../gamification/presentation/providers/point_award_service.dart',
  'lib/features/practice/presentation/providers/practice_item_providers.dart -> ../../../gamification/presentation/providers/point_award_service.dart',
  'lib/features/practice/presentation/providers/practice_item_providers.dart -> ../../../lessons/presentation/providers/teaching_resource_providers.dart',
  'lib/features/practice/presentation/providers/practice_item_providers.dart -> ../../../lessons/presentation/providers/tip_template_providers.dart',
  'lib/features/practice/presentation/providers/practice_streak_provider.dart -> ../../../../features/auth/presentation/providers/user_role_provider.dart',
  'lib/features/practice/presentation/providers/recording_feedback_provider.dart -> ../../../notifications/presentation/providers/notification_providers.dart',
  'lib/features/practice/presentation/providers/recording_provider.dart -> ../../../gamification/presentation/providers/point_award_service.dart',
  'lib/features/practice/presentation/screens/section_picker_screen.dart -> ../../../settings/presentation/providers/orphan_recording_provider.dart',
  'lib/features/profile/presentation/providers/invite_provider.dart -> ../../../../features/auth/presentation/providers/user_role_provider.dart',
  'lib/features/profile/presentation/providers/invite_provider.dart -> ../../../notifications/presentation/providers/notification_providers.dart',
  'lib/features/profile/presentation/providers/teacher_extended_profile_provider.dart -> ../../../../features/auth/presentation/providers/user_role_provider.dart',
  'lib/features/profile/presentation/providers/teacher_extended_profile_provider.dart -> ../../../../features/onboarding/presentation/providers/teacher_profile_repository_provider.dart',
  'lib/features/profile/presentation/screens/basic_info_edit_screen.dart -> ../../../auth/presentation/providers/auth_provider.dart',
  'lib/features/profile/presentation/screens/feedback_template_management_screen.dart -> ../../../lessons/presentation/providers/feedback_template_providers.dart',
  'lib/features/profile/presentation/screens/instrument_management_screen.dart -> ../../../settings/presentation/providers/teacher_settings_provider.dart',
  'lib/features/profile/presentation/screens/lesson_time_settings_screen.dart -> ../../../settings/presentation/providers/teacher_settings_provider.dart',
  'lib/features/profile/presentation/screens/outstanding_payments_screen.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/profile/presentation/screens/outstanding_payments_screen.dart -> ../../../notifications/presentation/providers/notification_providers.dart',
  'lib/features/profile/presentation/screens/outstanding_payments_screen.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/profile/presentation/screens/profile_tab.dart -> ../../../auth/presentation/providers/auth_provider.dart',
  'lib/features/profile/presentation/screens/profile_tab.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/profile/presentation/screens/profile_tab.dart -> ../../../lessons/presentation/providers/lesson_stats_provider.dart',
  'lib/features/profile/presentation/screens/profile_tab.dart -> ../../../students/presentation/providers/grouped_students_provider.dart',
  'lib/features/profile/presentation/screens/profile_tab.dart -> ../../../subscription/presentation/providers/subscription_providers.dart',
  'lib/features/profile/presentation/screens/repertoire_management_screen.dart -> ../../../practice/presentation/providers/piece_crud_provider.dart',
  'lib/features/profile/presentation/screens/repertoire_management_screen.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/profile/presentation/screens/tip_template_management_screen.dart -> ../../../lessons/presentation/providers/tip_template_providers.dart',
  'lib/features/profile/presentation/widgets/feedback_template_form_sheet.dart -> ../../../lessons/presentation/providers/feedback_template_providers.dart',
  'lib/features/schedule/presentation/providers/group_class_booking_providers.dart -> ../../../notifications/presentation/providers/notification_providers.dart',
  'lib/features/schedule/presentation/providers/teacher_availability_providers.dart -> ../../../lessons/presentation/providers/booking_providers.dart',
  'lib/features/schedule/presentation/providers/teacher_availability_providers.dart -> ../../../lessons/presentation/providers/lesson_repository_provider.dart',
  'lib/features/schedule/presentation/providers/teacher_availability_providers.dart -> ../../../search/presentation/providers/teacher_providers.dart',
  'lib/features/schedule/presentation/providers/unified_lesson_request_providers.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/schedule/presentation/providers/unified_lesson_request_providers.dart -> ../../../relationship/presentation/providers/relationship_providers.dart',
  'lib/features/schedule/presentation/providers/unified_lesson_request_providers.dart -> ../../../subscription/presentation/providers/subscription_providers.dart',
  'lib/features/schedule/presentation/providers/week_lessons_provider.dart -> ../../../lessons/presentation/providers/lesson_repository_provider.dart',
  'lib/features/schedule/presentation/providers/week_lessons_provider.dart -> ../../../students/presentation/providers/lesson_class_providers.dart',
  'lib/features/schedule/presentation/providers/week_lessons_provider.dart -> ../../../students/presentation/providers/membership_providers.dart',
  'lib/features/schedule/presentation/providers/week_lessons_provider.dart -> ../../../subscription/presentation/providers/subscription_providers.dart',
  'lib/features/schedule/presentation/screens/booking_cancel_screen.dart -> ../../../search/presentation/providers/teacher_search_provider.dart',
  'lib/features/schedule/presentation/screens/booking_reschedule_screen.dart -> ../../../notifications/presentation/providers/notification_providers.dart',
  'lib/features/schedule/presentation/screens/group_class_attendance_screen.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/schedule/presentation/screens/pending_bookings_screen.dart -> ../../../../features/lessons/presentation/providers/booking_providers.dart',
  'lib/features/schedule/presentation/screens/register_regular_lesson_screen.dart -> ../../../../features/lessons/presentation/providers/booking_providers.dart',
  'lib/features/schedule/presentation/screens/register_regular_lesson_screen.dart -> ../../../../features/settings/presentation/providers/teacher_settings_provider.dart',
  'lib/features/schedule/presentation/screens/request_detail_screen.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/schedule/presentation/screens/request_detail_screen.dart -> ../../../subscription/presentation/providers/subscription_template_providers.dart',
  'lib/features/schedule/presentation/screens/schedule_tab.dart -> ../../../lessons/presentation/providers/lesson_crud_provider.dart',
  'lib/features/schedule/presentation/screens/suggest_alternative_screen.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/schedule/presentation/screens/time_exception_screen.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/schedule/presentation/screens/unified_lesson_request_screen.dart -> ../../../../features/settings/presentation/providers/teacher_settings_provider.dart',
  'lib/features/schedule/presentation/screens/weekly_schedule_screen.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/schedule/presentation/widgets/approval_bottom_sheet.dart -> ../../../../features/lessons/presentation/providers/booking_providers.dart',
  'lib/features/schedule/presentation/widgets/previous_schedule_card.dart -> ../../../relationship/presentation/providers/relationship_providers.dart',
  'lib/features/schedule/presentation/widgets/proposal_bottom_sheet.dart -> ../../../profile/presentation/providers/teacher_extended_profile_provider.dart',
  'lib/features/schedule/presentation/widgets/proposal_bottom_sheet.dart -> ../../../subscription/presentation/providers/subscription_template_providers.dart',
  'lib/features/schedule/presentation/widgets/schedule_timeline_view.dart -> ../../../lessons/presentation/providers/lesson_crud_provider.dart',
  'lib/features/search/presentation/screens/academy_detail_screen.dart -> ../../../parent_home/presentation/providers/user_profile_provider.dart',
  'lib/features/search/presentation/screens/teacher_detail_screen.dart -> ../../../profile/presentation/providers/invite_provider.dart',
  'lib/features/search/presentation/screens/teacher_search_screen.dart -> ../../../profile/presentation/providers/invite_provider.dart',
  'lib/features/settings/presentation/providers/orphan_recording_provider.dart -> ../../../practice/presentation/providers/practice_repertoire_crud_provider.dart',
  'lib/features/settings/presentation/providers/orphan_recording_provider.dart -> ../../../practice/presentation/providers/practice_repertoire_repository_provider.dart',
  'lib/features/settings/presentation/screens/all_recordings_screen.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/student_home/presentation/providers/student_lesson_progress_provider.dart -> ../../../schedule/presentation/providers/schedule_confirmation_card_providers.dart',
  'lib/features/student_home/presentation/providers/student_lesson_progress_provider.dart -> ../../../schedule/presentation/providers/unified_lesson_request_providers.dart',
  'lib/features/student_home/presentation/screens/my_teachers_screen.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/student_home/presentation/screens/my_teachers_screen.dart -> ../../../relationship/presentation/providers/relationship_providers.dart',
  'lib/features/student_home/presentation/screens/notification_settings_screen.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/student_home/presentation/screens/notification_settings_screen.dart -> ../../../notifications/presentation/providers/subscription_expiry_providers.dart',
  'lib/features/student_home/presentation/screens/student_dashboard_tab.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/student_home/presentation/screens/student_dashboard_tab.dart -> ../../../practice/presentation/providers/practice_crud_provider.dart',
  'lib/features/student_home/presentation/screens/student_home_screen.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/student_home/presentation/screens/student_lessons_tab.dart -> ../../../../features/lessons/presentation/providers/booking_providers.dart',
  'lib/features/student_home/presentation/screens/student_lessons_tab.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/student_home/presentation/screens/student_lessons_tab.dart -> ../../../lessons/presentation/providers/lesson_crud_provider.dart',
  'lib/features/student_home/presentation/screens/student_practice_tab.dart -> ../../../../features/practice/presentation/providers/practice_repertoire_crud_provider.dart',
  'lib/features/student_home/presentation/screens/student_practice_tab.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/student_home/presentation/screens/student_practice_tab.dart -> ../../../practice/presentation/providers/repertoire_sort_provider.dart',
  'lib/features/student_home/presentation/screens/student_profile_edit_screen.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/student_home/presentation/screens/student_profile_edit_screen.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/student_home/presentation/screens/student_profile_edit_screen.dart -> ../../../students/presentation/providers/student_image_provider.dart',
  'lib/features/student_home/presentation/screens/student_profile_tab.dart -> ../../../../features/parent_home/presentation/providers/parent_crud_provider.dart',
  'lib/features/student_home/presentation/screens/student_profile_tab.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/student_home/presentation/screens/student_profile_tab.dart -> ../../../lessons/presentation/providers/lesson_crud_provider.dart',
  'lib/features/student_home/presentation/screens/student_profile_tab.dart -> ../../../practice/presentation/providers/practice_crud_provider.dart',
  'lib/features/student_home/presentation/screens/student_profile_tab.dart -> ../../../practice/presentation/providers/practice_repertoire_crud_provider.dart',
  'lib/features/student_home/presentation/screens/student_profile_tab.dart -> ../../../profile/presentation/providers/invite_provider.dart',
  'lib/features/student_home/presentation/screens/student_profile_tab.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/student_home/presentation/widgets/dashboard/practice_summary_section.dart -> ../../../../practice/presentation/providers/practice_crud_provider.dart',
  'lib/features/student_home/presentation/widgets/dashboard/teacher_feedback_section.dart -> ../../../../lessons/presentation/providers/lesson_crud_provider.dart',
  'lib/features/student_home/presentation/widgets/student_getting_started_card.dart -> ../../../../features/profile/presentation/providers/invite_provider.dart',
  'lib/features/student_home/presentation/widgets/student_getting_started_card.dart -> ../../../lessons/presentation/providers/booking_providers.dart',
  'lib/features/student_home/presentation/widgets/weekly_practice_widget.dart -> ../../../practice/presentation/providers/practice_item_providers.dart',
  'lib/features/students/presentation/providers/bulk_teacher_action_providers.dart -> ../../../lessons/presentation/providers/lesson_repository_provider.dart',
  'lib/features/students/presentation/providers/bulk_teacher_action_providers.dart -> ../../../notifications/presentation/providers/notification_providers.dart',
  'lib/features/students/presentation/providers/student_roster_summary_provider.dart -> ../../../subscription/presentation/providers/subscription_providers.dart',
  'lib/features/students/presentation/screens/bulk_cancel_screen.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/students/presentation/screens/student_detail_screen.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/students/presentation/screens/student_detail_screen.dart -> ../../../parent_home/presentation/providers/parent_crud_provider.dart',
  'lib/features/students/presentation/screens/students_tab.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/students/presentation/widgets/bulk_message_sheet.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/students/presentation/widgets/student_detail/student_lessons_sections.dart -> ../../../../lessons/presentation/providers/lesson_crud_provider.dart',
  'lib/features/students/presentation/widgets/student_detail/student_notes_section.dart -> ../../../../lessons/presentation/providers/lesson_note_providers.dart',
  'lib/features/students/presentation/widgets/student_detail/student_practice_section.dart -> ../../../../practice/presentation/providers/practice_crud_provider.dart',
  'lib/features/students/presentation/widgets/student_detail/student_practice_tab.dart -> ../../../../practice/presentation/providers/practice_overview_provider.dart',
  'lib/features/students/presentation/widgets/student_detail/student_practice_tab.dart -> ../../../../practice/presentation/providers/recording_feedback_provider.dart',
  'lib/features/subscription/presentation/providers/subscription_proposal_providers.dart -> ../../../notifications/presentation/providers/notification_providers.dart',
  'lib/features/subscription/presentation/screens/expiring_subscriptions_screen.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/subscription/presentation/screens/issue_subscription_actions.dart -> ../../../relationship/presentation/providers/relationship_providers.dart',
  'lib/features/subscription/presentation/screens/issue_subscription_actions.dart -> ../../../schedule/presentation/providers/schedule_confirmation_card_providers.dart',
  'lib/features/subscription/presentation/screens/issue_subscription_actions.dart -> ../../../schedule/presentation/providers/unified_lesson_request_providers.dart',
  'lib/features/subscription/presentation/screens/issue_subscription_actions.dart -> ../../../settings/presentation/providers/teacher_settings_provider.dart',
  'lib/features/subscription/presentation/screens/issue_subscription_actions.dart -> ../../../students/presentation/providers/lesson_class_providers.dart',
  'lib/features/subscription/presentation/screens/issue_subscription_actions.dart -> ../../../students/presentation/providers/membership_providers.dart',
  'lib/features/subscription/presentation/screens/issue_subscription_actions.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/subscription/presentation/screens/issue_subscription_screen.dart -> ../../../students/presentation/providers/lesson_class_providers.dart',
  'lib/features/subscription/presentation/screens/issue_subscription_screen.dart -> ../../../students/presentation/providers/membership_providers.dart',
  'lib/features/subscription/presentation/screens/issue_subscription_screen.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/subscription/presentation/screens/proposal_confirm_screen.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/subscription/presentation/screens/proposal_create_screen.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/subscription/presentation/screens/proposal_detail_screen.dart -> ../../../search/presentation/providers/teacher_search_provider.dart',
  'lib/features/subscription/presentation/screens/renewal_detail_screen.dart -> ../../../search/presentation/providers/teacher_search_provider.dart',
  'lib/features/subscription/presentation/screens/schedule_change_request_list_screen.dart -> ../../../schedule/presentation/providers/unified_lesson_request_providers.dart',
  'lib/features/subscription/presentation/screens/schedule_change_request_list_screen.dart -> ../../../students/presentation/providers/lesson_class_providers.dart',
  'lib/features/subscription/presentation/screens/schedule_change_request_list_screen.dart -> ../../../students/presentation/providers/membership_providers.dart',
  'lib/features/subscription/presentation/screens/student_proposal_accept_screen.dart -> ../../../search/presentation/providers/teacher_search_provider.dart',
  'lib/features/subscription/presentation/screens/subscription_detail_screen.dart -> ../../../schedule/presentation/providers/unified_lesson_request_providers.dart',
  'lib/features/subscription/presentation/screens/subscription_detail_screen.dart -> ../../../students/presentation/providers/lesson_class_providers.dart',
  'lib/features/subscription/presentation/screens/subscription_detail_screen.dart -> ../../../students/presentation/providers/membership_providers.dart',
  'lib/features/subscription/presentation/screens/subscription_detail_screen.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/subscription/presentation/screens/subscription_list_screen.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/subscription/presentation/screens/subscription_list_screen.dart -> ../../../students/presentation/providers/lesson_class_providers.dart',
  'lib/features/subscription/presentation/screens/subscription_list_screen.dart -> ../../../students/presentation/providers/membership_providers.dart',
  'lib/features/subscription/presentation/screens/teacher_subscription_list_screen.dart -> ../../../auth/presentation/providers/user_role_provider.dart',
  'lib/features/subscription/presentation/screens/teacher_subscription_list_screen.dart -> ../../../schedule/presentation/providers/unified_lesson_request_providers.dart',
  'lib/features/subscription/presentation/screens/teacher_subscription_list_screen.dart -> ../../../students/presentation/providers/lesson_class_providers.dart',
  'lib/features/subscription/presentation/screens/teacher_subscription_list_screen.dart -> ../../../students/presentation/providers/membership_providers.dart',
  'lib/features/subscription/presentation/widgets/issue_form_membership_widgets.dart -> ../../../students/presentation/providers/lesson_class_providers.dart',
  'lib/features/subscription/presentation/widgets/location_travel_selector.dart -> ../../../students/presentation/providers/student_crud_provider.dart',
  'lib/features/subscription/presentation/widgets/subscription_policy_sheet.dart -> ../../../students/presentation/providers/lesson_class_providers.dart',
  'lib/features/subscription/presentation/widgets/subscription_policy_sheet.dart -> ../../../students/presentation/providers/membership_providers.dart',
};
