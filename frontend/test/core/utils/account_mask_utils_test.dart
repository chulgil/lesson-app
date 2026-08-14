import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/utils/account_mask_utils.dart';

void main() {
  group('maskAccountNumber', () {
    test('masks all but the last 4 digits, preserving hyphens', () {
      expect(maskAccountNumber('110-123-456789'), '***-***-**6789');
    });

    test('masks a plain numeric string without separators', () {
      expect(maskAccountNumber('12345678901'), '*******8901');
    });

    test('returns unchanged when 4 digits or fewer', () {
      expect(maskAccountNumber('1234'), '1234');
      expect(maskAccountNumber('12'), '12');
    });

    test('is idempotent — masking an already-masked string is a no-op', () {
      final once = maskAccountNumber('110-123-456789');
      final twice = maskAccountNumber(once);
      expect(twice, once);
    });
  });
}
