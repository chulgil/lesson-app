import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_template.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_template_providers.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/unified_subscription_sheet.dart';

/// #769 — 수강권 발급 방식(바로 발급 vs 제안) 차이 캡션 회귀 가드.
///
/// 발급 바텀시트 하단 두 버튼에 차이 설명이 없어 잘못된 발급 방식 선택 위험.
/// 각 버튼 아래 한 줄 캡션('교사가 즉시 발급' / '학생 수락·입금 후 발급')이
/// 노출돼야 한다. _buildBottomButtons 는 템플릿 상태와 무관하게 항상 렌더.

const _teacherId = 'teacher_1';

void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync().path);
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTeacherTemplatesProvider(
            _teacherId,
          ).overrideWith((ref) async => const <SubscriptionTemplate>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: UnifiedSubscriptionSheet(
              teacherId: _teacherId,
              studentIds: const ['stu_1'],
              studentName: '학생 A',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('발급 바텀시트 — 두 발급 버튼에 차이 캡션 노출', (tester) async {
    await pumpSheet(tester);

    expect(tester.takeException(), isNull);
    expect(
      find.text(AppStrings.unifiedSubscriptionDirectIssueCaption),
      findsOneWidget,
      reason: "'바로 발급' 버튼 아래 '교사가 즉시 발급' 캡션 (#769)",
    );
    expect(
      find.text(AppStrings.unifiedSubscriptionProposalCaption),
      findsOneWidget,
      reason: "'제안 보내기' 버튼 아래 '학생 수락·입금 후 발급' 캡션 (#769)",
    );
  });

  testWidgets('좁은 뷰포트(375) — 캡션 추가 후 바텀바 overflow 없음', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpSheet(tester);

    expect(
      tester.takeException(),
      isNull,
      reason: '375px 에서 캡션 Row 추가로 바텀바가 overflow/크래시 하지 않아야 한다',
    );
    expect(
      find.text(AppStrings.unifiedSubscriptionProposalCaption),
      findsOneWidget,
    );
  });
}
