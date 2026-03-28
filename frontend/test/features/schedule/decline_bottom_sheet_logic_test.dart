import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';

/// Tests for decline bottom sheet default message logic.
///
/// The bottom sheet has two paths:
/// 1. Reject (message only) → default: declineDefaultMessage
/// 2. Propose alternative → default: proposeDefaultMessage
void main() {
  group('decline bottom sheet default messages', () {
    test('reject default message exists in AppStrings', () {
      expect(AppStrings.declineDefaultMessage, isNotEmpty);
      expect(
        AppStrings.declineDefaultMessage,
        contains('어렵'),
        reason: 'Decline message should convey difficulty',
      );
    });

    test('propose default message exists in AppStrings', () {
      expect(AppStrings.proposeDefaultMessage, isNotEmpty);
      expect(
        AppStrings.proposeDefaultMessage,
        contains('제안'),
        reason: 'Propose message should mention suggestion',
      );
    });

    test('bottom sheet title exists in AppStrings', () {
      expect(AppStrings.declineBottomSheetTitle, isNotEmpty);
    });

    test('message hint exists in AppStrings', () {
      expect(AppStrings.messageHint, isNotEmpty);
    });

    test('default messages are different', () {
      expect(
        AppStrings.declineDefaultMessage,
        isNot(equals(AppStrings.proposeDefaultMessage)),
        reason: 'Reject and propose should have different defaults',
      );
    });
  });
}
