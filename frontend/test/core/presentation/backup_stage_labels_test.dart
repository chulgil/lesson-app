// #1299 — BackupStage/BackupFailure presentation 매핑 검증.
//
// data 계층은 stage/failure 값만 내고, 문구는 이 확장이 유일하게 만든다.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/entities/backup_stage.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/l10n/generated/app_localizations.dart';
import 'package:lessonaza/core/presentation/extensions/backup_stage_labels.dart';

void main() {
  group('BackupStageLabels', () {
    test('모든 stage 가 비어있지 않은 라벨로 매핑된다', () {
      for (final stage in BackupStage.values) {
        expect(stage.label(), isNotEmpty, reason: stage.name);
      }
    });

    test('녹음 추가/복원 stage 는 카운터가 있으면 진행형 문구를 쓴다', () {
      expect(
        BackupStage.addingRecordings.label(current: 3, total: 10),
        AppStrings.backupRecordingsAddingProgressFormat(3, 10),
      );
      expect(
        BackupStage.restoringRecordings.label(current: 7, total: 9),
        AppStrings.backupRecordingsRestoringProgressFormat(7, 9),
      );
      expect(
        BackupStage.addingRecordings.label(),
        AppStrings.backupRecordingsAdding,
      );
    });

    test('완료 stage 는 백업/복원 각각의 완료 문구로 매핑된다', () {
      expect(BackupStage.backupCompleted.label(), AppStrings.backupComplete);
      expect(BackupStage.restoreCompleted.label(), AppStrings.restoreComplete);
    });
  });

  group('BackupFailureLabels.resolveMessage — 문구 충실도 (리뷰 0821)', () {
    late AppLocalizations ko;

    setUpAll(() async {
      ko = await AppLocalizations.delegate.load(const Locale('ko'));
    });

    test('wrongExtension 은 확장자 안내 행동지시를 유지한다', () {
      final message = const BackupFailure(
        BackupFailureKind.wrongExtension,
        detail: '.lessonbackup',
      ).resolveMessage(ko);

      expect(message, contains('.lessonbackup'));
      expect(message, contains('선택해주세요'));
    });

    test('pathUnavailable 은 경로 원인을 정확히 밝힌다', () {
      final message = const BackupFailure(
        BackupFailureKind.pathUnavailable,
      ).resolveMessage(ko);

      expect(message, contains('파일 경로'));
    });

    test('나머지 kind 는 context-free message 와 동일하다', () {
      for (final failure in [
        const BackupFailure(BackupFailureKind.invalidFile),
        const BackupFailure(BackupFailureKind.encodeFailed),
        const BackupFailure(BackupFailureKind.unknown, detail: 'x'),
      ]) {
        expect(failure.resolveMessage(ko), failure.message);
      }
    });
  });

  group('BackupFailureLabels', () {
    test('실패 4종이 각각의 문구로 매핑된다', () {
      expect(
        const BackupFailure(BackupFailureKind.invalidFile).message,
        AppStrings.backupInvalidFile,
      );
      expect(
        const BackupFailure(
          BackupFailureKind.unsupportedVersion,
          detail: '99.0',
        ).message,
        AppStrings.backupUnsupportedVersionFormat('99.0'),
      );
      expect(
        const BackupFailure(BackupFailureKind.encodeFailed).message,
        AppStrings.backupEncodeFailure,
      );
      expect(
        const BackupFailure(BackupFailureKind.unknown, detail: 'boom').message,
        AppStrings.restoreErrorFormat('boom'),
      );
    });
  });
}
