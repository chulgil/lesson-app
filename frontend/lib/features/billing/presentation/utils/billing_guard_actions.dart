// #415 R4 Phase B — Paywall 가드 헬퍼.
//
// 학생 추가 진입점에서 호출. BillingGuard 결정에 따라
// allowed → onPass 즉시 실행, blocked → FreeLimitSheet 노출.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../students/students_facade.dart';
import '../../domain/entities/app_billing_snapshot.dart';
import '../../domain/services/billing_guard.dart';
import '../providers/app_billing_provider.dart';
import '../widgets/free_limit_sheet.dart';

/// 학생 추가 동작 전에 결제 한도를 확인하고 [onPass] 를 호출한다.
///
/// 한도 차단 시 [FreeLimitSheet] 를 보여주고 [onPass] 는 실행하지 않는다.
/// Phase B 는 Pro/Trial 버튼이 "곧 제공됩니다" 안내만 한다 — 실제 결제 흐름은 Phase C.
Future<void> guardAddStudentNavigation({
  required BuildContext context,
  required WidgetRef ref,
  required VoidCallback onPass,
}) async {
  AppBillingSnapshot snapshot;
  int studentCount;
  try {
    snapshot = await ref.read(appBillingSnapshotProvider.future);
    if (!context.mounted) return;
    final students = await ref.read(studentsNotifierProvider.future);
    studentCount = students.length;
  } catch (_) {
    // 데이터 로딩 실패 시 사용자 흐름을 막지 않는다 (백엔드가 server-side 한도를
    // 별도 enforce 함 — Phase A). 클라이언트 가드는 UX 안내 layer 일 뿐.
    if (!context.mounted) return;
    onPass();
    return;
  }
  if (!context.mounted) return;

  const guard = BillingGuard();
  final decision = guard.checkStudentLimit(
    snapshot: snapshot,
    currentStudentCount: studentCount,
  );

  if (decision.allowed) {
    onPass();
    return;
  }

  await showFreeLimitSheet(
    context: context,
    reason: decision.reason,
    trialAvailable: !snapshot.trialUsed,
    onBuyPro: () => _showComingSoonHint(context),
    onStartTrial: () => _showComingSoonHint(context),
  );
}

void _showComingSoonHint(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(AppStrings.paywallComingSoonHint)),
  );
}
