import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/domain/bank_account_defaults.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';

void main() {
  group('normalizeBankAccountDefaults', () {
    test('empty list returns empty list', () {
      final result = normalizeBankAccountDefaults([]);
      expect(result, isEmpty);
    });

    test('single account is set to default', () {
      final account = BankAccount(
        id: 'ba_1',
        bankName: 'Test Bank',
        accountNumber: '123456',
        accountHolder: 'Test User',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      final result = normalizeBankAccountDefaults([account]);

      expect(result, hasLength(1));
      expect(result[0].isDefault, true);
      expect(result[0].id, 'ba_1');
    });

    test('multiple accounts with no default sets first to default', () {
      final accounts = [
        BankAccount(
          id: 'ba_1',
          bankName: 'Bank 1',
          accountNumber: '111',
          accountHolder: 'User 1',
          isDefault: false,
          createdAt: DateTime.now(),
        ),
        BankAccount(
          id: 'ba_2',
          bankName: 'Bank 2',
          accountNumber: '222',
          accountHolder: 'User 2',
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      ];

      final result = normalizeBankAccountDefaults(accounts);

      expect(result, hasLength(2));
      expect(result[0].isDefault, true);
      expect(result[1].isDefault, false);
    });

    test('multiple accounts with existing default keeps that default', () {
      final accounts = [
        BankAccount(
          id: 'ba_1',
          bankName: 'Bank 1',
          accountNumber: '111',
          accountHolder: 'User 1',
          isDefault: false,
          createdAt: DateTime.now(),
        ),
        BankAccount(
          id: 'ba_2',
          bankName: 'Bank 2',
          accountNumber: '222',
          accountHolder: 'User 2',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      ];

      final result = normalizeBankAccountDefaults(accounts);

      expect(result, hasLength(2));
      expect(result[0].isDefault, false);
      expect(result[1].isDefault, true);
    });

    test('preferred default ID is honored if present', () {
      final accounts = [
        BankAccount(
          id: 'ba_1',
          bankName: 'Bank 1',
          accountNumber: '111',
          accountHolder: 'User 1',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        BankAccount(
          id: 'ba_2',
          bankName: 'Bank 2',
          accountNumber: '222',
          accountHolder: 'User 2',
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      ];

      final result =
          normalizeBankAccountDefaults(accounts, preferredDefaultId: 'ba_2');

      expect(result, hasLength(2));
      expect(result[0].isDefault, false);
      expect(result[1].isDefault, true);
    });

    test(
        'preferred default ID is ignored if not found, falls back to first',
        () {
      final accounts = [
        BankAccount(
          id: 'ba_1',
          bankName: 'Bank 1',
          accountNumber: '111',
          accountHolder: 'User 1',
          isDefault: false,
          createdAt: DateTime.now(),
        ),
        BankAccount(
          id: 'ba_2',
          bankName: 'Bank 2',
          accountNumber: '222',
          accountHolder: 'User 2',
          isDefault: false,
          createdAt: DateTime.now(),
        ),
      ];

      final result = normalizeBankAccountDefaults(
        accounts,
        preferredDefaultId: 'ba_nonexistent',
      );

      expect(result, hasLength(2));
      expect(result[0].isDefault, true);
      expect(result[1].isDefault, false);
    });

    test('never has multiple defaults', () {
      final accounts = [
        BankAccount(
          id: 'ba_1',
          bankName: 'Bank 1',
          accountNumber: '111',
          accountHolder: 'User 1',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        BankAccount(
          id: 'ba_2',
          bankName: 'Bank 2',
          accountNumber: '222',
          accountHolder: 'User 2',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      ];

      final result = normalizeBankAccountDefaults(accounts);

      expect(result, hasLength(2));
      expect(result.where((a) => a.isDefault), hasLength(1));
    });

    test('returns new list without mutating original', () {
      final original = BankAccount(
        id: 'ba_1',
        bankName: 'Test Bank',
        accountNumber: '123456',
        accountHolder: 'Test User',
        isDefault: false,
        createdAt: DateTime.now(),
      );
      final accounts = [original];

      final result = normalizeBankAccountDefaults(accounts);

      expect(result, isNot(same(accounts)));
      expect(result[0], isNot(same(original)));
      expect(accounts[0].isDefault, false);
    });
  });
}
