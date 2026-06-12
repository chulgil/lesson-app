import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_prompt.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_type.dart';

void main() {
  final baseTime = DateTime.utc(2026, 6, 12, 9);

  SpotlightPrompt makePrompt({
    String id = 'p1',
    String studentId = 's1',
    SpotlightType type = SpotlightType.teacherRec,
    String title = '바이올린 비브라토 영상',
    String? videoId,
    String? ctaRoute,
    DateTime? queuedAt,
    int declineCount = 0,
    DateTime? hideUntil,
    bool permanentlyHidden = false,
    DateTime? lastShownAt,
    bool isMandatory = false,
  }) => SpotlightPrompt(
    id: id,
    studentId: studentId,
    type: type,
    title: title,
    videoId: videoId,
    ctaRoute: ctaRoute,
    queuedAt: queuedAt ?? baseTime,
    declineCount: declineCount,
    hideUntil: hideUntil,
    permanentlyHidden: permanentlyHidden,
    lastShownAt: lastShownAt,
    isMandatory: isMandatory,
  );

  group('SpotlightPrompt entity', () {
    test('all required fields preserved', () {
      final p = makePrompt(
        videoId: 'vid_123',
        ctaRoute: '/practice/youtube',
        declineCount: 2,
      );
      expect(p.id, 'p1');
      expect(p.studentId, 's1');
      expect(p.type, SpotlightType.teacherRec);
      expect(p.title, '바이올린 비브라토 영상');
      expect(p.videoId, 'vid_123');
      expect(p.ctaRoute, '/practice/youtube');
      expect(p.queuedAt, baseTime);
      expect(p.declineCount, 2);
      expect(p.hideUntil, isNull);
      expect(p.permanentlyHidden, isFalse);
      expect(p.isMandatory, isFalse);
    });

    test('copyWith preserves untouched fields', () {
      final p = makePrompt(declineCount: 1);
      final updated = p.copyWith(declineCount: 3);
      expect(updated.declineCount, 3);
      expect(updated.id, p.id);
      expect(updated.title, p.title);
      expect(updated.queuedAt, p.queuedAt);
    });

    test('copyWith clearHideUntil resets to null', () {
      final p = makePrompt(hideUntil: baseTime.add(const Duration(days: 7)));
      final updated = p.copyWith(clearHideUntil: true);
      expect(updated.hideUntil, isNull);
    });
  });

  group('isHiddenAt', () {
    test('permanentlyHidden=true → hidden regardless of time', () {
      final p = makePrompt(permanentlyHidden: true);
      expect(p.isHiddenAt(baseTime), isTrue);
      expect(p.isHiddenAt(baseTime.add(const Duration(days: 365))), isTrue);
    });

    test('hideUntil in future → hidden', () {
      final p = makePrompt(hideUntil: baseTime.add(const Duration(days: 7)));
      expect(p.isHiddenAt(baseTime), isTrue);
      expect(
        p.isHiddenAt(baseTime.add(const Duration(days: 6, hours: 23))),
        isTrue,
      );
    });

    test('hideUntil in past → not hidden', () {
      final p = makePrompt(
        hideUntil: baseTime.subtract(const Duration(seconds: 1)),
      );
      expect(p.isHiddenAt(baseTime), isFalse);
    });

    test('no hideUntil, not permanent → not hidden', () {
      final p = makePrompt();
      expect(p.isHiddenAt(baseTime), isFalse);
    });
  });

  group('priority — 스펙 §7.2', () {
    test('teacherRec + isMandatory=true → 최상위 (0)', () {
      final p = makePrompt(type: SpotlightType.teacherRec, isMandatory: true);
      expect(p.priority, 0);
    });

    test('teacherRec 일반 → 10', () {
      final p = makePrompt(type: SpotlightType.teacherRec);
      expect(p.priority, 10);
    });

    test('seasonEvent → 20', () {
      final p = makePrompt(type: SpotlightType.seasonEvent);
      expect(p.priority, 20);
    });

    test('routineSuggestion → 30', () {
      final p = makePrompt(type: SpotlightType.routineSuggestion);
      expect(p.priority, 30);
    });

    test('isMandatory on non-teacherRec → ignored (priority follows type)', () {
      final p = makePrompt(type: SpotlightType.seasonEvent, isMandatory: true);
      expect(p.priority, 20, reason: '필수 플래그는 teacherRec 전용');
    });
  });

  group('JSON round-trip', () {
    test('full payload preserves all fields', () {
      final p = makePrompt(
        id: 'p_uuid_x',
        type: SpotlightType.seasonEvent,
        title: '추석 합주 챌린지',
        videoId: 'vid_chuseok',
        ctaRoute: '/season/chuseok',
        declineCount: 3,
        hideUntil: baseTime.add(const Duration(days: 7)),
        lastShownAt: baseTime.subtract(const Duration(hours: 2)),
        isMandatory: false,
      );
      final restored = SpotlightPrompt.fromJson(p.toJson());
      expect(restored.id, p.id);
      expect(restored.studentId, p.studentId);
      expect(restored.type, p.type);
      expect(restored.title, p.title);
      expect(restored.videoId, p.videoId);
      expect(restored.ctaRoute, p.ctaRoute);
      expect(restored.queuedAt.toUtc(), p.queuedAt.toUtc());
      expect(restored.declineCount, p.declineCount);
      expect(restored.hideUntil?.toUtc(), p.hideUntil?.toUtc());
      expect(restored.permanentlyHidden, p.permanentlyHidden);
      expect(restored.lastShownAt?.toUtc(), p.lastShownAt?.toUtc());
      expect(restored.isMandatory, p.isMandatory);
    });

    test('minimal payload (no nullable) preserves defaults', () {
      final p = makePrompt(type: SpotlightType.routineSuggestion);
      final restored = SpotlightPrompt.fromJson(p.toJson());
      expect(restored.videoId, isNull);
      expect(restored.ctaRoute, isNull);
      expect(restored.hideUntil, isNull);
      expect(restored.lastShownAt, isNull);
      expect(restored.declineCount, 0);
      expect(restored.permanentlyHidden, isFalse);
      expect(restored.isMandatory, isFalse);
    });

    test('permanentlyHidden=true → JSON preserves', () {
      final p = makePrompt(permanentlyHidden: true);
      final restored = SpotlightPrompt.fromJson(p.toJson());
      expect(restored.permanentlyHidden, isTrue);
    });
  });
}
