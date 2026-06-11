// W2 Task 2.3 — CategoryStatus presentation extension.
// spec §11.1: 5묶음 카테고리 카드 라벨 규칙.
//
// 라벨/색상 매핑은 presentation 책임 (flutter-architecture: domain enum 에
// label getter 금지). CategoryStatusCalculator 는 hint key 만 반환하고,
// 사용자-facing 문자열은 이 extension 에서 AppStrings 로 매핑.

import 'package:flutter/widgets.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/category_status_provider.dart';

/// 5묶음 카테고리 카드의 상태별 라벨/색상 매핑.
extension CategoryStatusVisuals on CategoryStatus {
  /// 카드 우측 상태 라벨 (spec §11.1).
  ///
  /// - Complete → "설정완료"
  /// - Partial  → hintKey 매핑 또는 "N/M 항목"
  /// - Empty    → hintKey 매핑 또는 "미설정"
  /// - Neutral  → "기본값"
  String get label {
    final status = this;
    return switch (status) {
      CategoryStatusComplete() => AppStrings.categoryStatusComplete,
      CategoryStatusPartial(:final hintKey, :final filled, :final total) =>
        _resolveHint(hintKey) ??
            AppStrings.categoryStatusPartialNOfM(filled, total),
      CategoryStatusEmpty(:final hintKey) =>
        _resolveHint(hintKey) ?? AppStrings.categoryStatusEmpty,
      CategoryStatusNeutral() => AppStrings.categoryStatusNeutralDefault,
    };
  }

  /// 라벨 텍스트 색상 (3색 이하 원칙: success/warning/grey).
  ///
  /// - Complete → paperOk (녹색 펜)
  /// - Partial  → paperAccent (빨간 펜 — 작업 필요)
  /// - Empty    → paperAccent (빨간 펜 — 작업 필요)
  /// - Neutral  → inkTertiary (회색)
  Color get color {
    final status = this;
    return switch (status) {
      CategoryStatusComplete() => AppColors.paperOk,
      CategoryStatusPartial() => AppColors.paperAccent,
      CategoryStatusEmpty() => AppColors.paperAccent,
      CategoryStatusNeutral() => AppColors.inkTertiary,
    };
  }

  /// Empty 상태에서 노란 점 (⚠ ●) 표시 여부.
  bool get showWarningDot => this is CategoryStatusEmpty;
}

String? _resolveHint(String? key) {
  switch (key) {
    case categoryHintKeyBreakTimeMissing:
      return AppStrings.categoryHintBreakTimeMissing;
    case categoryHintKeyBankAccountMissing:
      return AppStrings.categoryHintBankAccountMissing;
    case categoryHintKeyPriceTableMissing:
      return AppStrings.categoryHintPriceTableMissing;
    default:
      return null;
  }
}
