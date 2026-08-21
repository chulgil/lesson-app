// #1299 — BackupStage/BackupFailure presentation 매핑 검증.
//
// data 계층은 stage/failure 값만 내고, 문구는 이 확장이 유일하게 만든다.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/entities/backup_stage.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
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
