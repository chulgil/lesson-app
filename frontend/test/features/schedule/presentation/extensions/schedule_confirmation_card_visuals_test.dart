import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/schedule_confirmation_card.dart';
import 'package:lessonaza/features/schedule/presentation/extensions/schedule_confirmation_card_visuals.dart';

void main() {
  group('ScheduleCardTypeVisualX', () {
    test('maps labels and suggestion text in presentation', () {
      expect(ScheduleCardType.afterTrial.label, '체험 후 등록');
      expect(ScheduleCardType.reEnrollment.label, '재등록');
      expect(ScheduleCardType.additionalInstrument.label, '추가 악기');

      expect(ScheduleCardType.afterTrial.suggestionText, '체험 레슨 시간으로 예약할까요?');
      expect(ScheduleCardType.reEnrollment.suggestionText, '이전 스케줄로 예약할까요?');
      expect(
        ScheduleCardType.additionalInstrument.suggestionText,
        '레슨 시간을 선택해주세요',
      );
    });
  });

  group('ScheduleCardStatusVisualX', () {
    test('maps labels in presentation', () {
      expect(ScheduleCardStatus.pending.label, '확인 대기');
      expect(ScheduleCardStatus.confirmed.label, '확정됨');
      expect(ScheduleCardStatus.changedTime.label, '시간 변경됨');
      expect(ScheduleCardStatus.dismissed.label, '닫힘');
    });
  });
}
