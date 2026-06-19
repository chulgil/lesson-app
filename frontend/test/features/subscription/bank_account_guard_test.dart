// #847 입금 계좌 미등록 시 수강권 발급/제안 차단 가드.
//
// 계좌 없음(profile null 또는 bankAccounts 비어있음) -> false + 안내 다이얼로그.
// 계좌 있음 -> true, 다이얼로그 없음.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/search/search_facade.dart'
    show teacherFullProfileProvider;
import 'package:lessonaza/features/subscription/presentation/widgets/bank_account_guard.dart';

const _teacherId = 't1';

TeacherProfile _profile({required bool withBank}) => TeacherProfile(
  id: _teacherId,
  userId: 'u1',
  name: '김선생',
  instruments: const ['바이올린'],
  introduction: '',
  createdAt: DateTime(2026, 6, 19),
  bankAccounts:
      withBank
          ? [
            BankAccount(
              id: 'a1',
              bankName: '국민은행',
              accountNumber: '123-456',
              accountHolder: '김선생',
              isDefault: true,
              createdAt: DateTime(2026, 6, 19),
            ),
          ]
          : const [],
);

Widget _harness({
  required List<Override> overrides,
  required void Function(bool) onResult,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(
        body: Consumer(
          builder:
              (context, ref, _) => ElevatedButton(
                onPressed: () async {
                  final ok = await ensureBankAccountRegistered(
                    context: context,
                    ref: ref,
                    teacherId: _teacherId,
                  );
                  onResult(ok);
                },
                child: const Text('go'),
              ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('#847 계좌 없음 -> false + 안내 다이얼로그', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _harness(
        overrides: [
          teacherFullProfileProvider(
            _teacherId,
          ).overrideWith((ref) async => _profile(withBank: false)),
        ],
        onResult: (r) => result = r,
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.bankAccountRequiredTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('#847 profile null -> false + 안내 다이얼로그', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _harness(
        overrides: [
          teacherFullProfileProvider(
            _teacherId,
          ).overrideWith((ref) async => null),
        ],
        onResult: (r) => result = r,
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.bankAccountRequiredTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('#847 계좌 있음 -> true, 다이얼로그 없음', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _harness(
        overrides: [
          teacherFullProfileProvider(
            _teacherId,
          ).overrideWith((ref) async => _profile(withBank: true)),
        ],
        onResult: (r) => result = r,
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.bankAccountRequiredTitle), findsNothing);
    expect(result, isTrue);
  });
}
