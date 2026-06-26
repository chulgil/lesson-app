import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/lessons/domain/entities/teaching_resource.dart';
import 'package:lessonaza/features/lessons/presentation/extensions/teaching_resource_visuals.dart';

import '../../../../helpers/helpers.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // TeachingResourceType
  // ═══════════════════════════════════════════════════════════════════════════

  group('TeachingResourceType', () {
    test('각 타입의 label이 올바르다', () {
      expect(TeachingResourceType.teacherRecording.label, '녹음');
      expect(TeachingResourceType.youtube.label, '유튜브');
      expect(TeachingResourceType.externalLink.label, '링크');
    });

    test('각 타입의 icon이 올바르다', () {
      expect(TeachingResourceType.teacherRecording.icon, Icons.music_note);
      expect(TeachingResourceType.youtube.icon, Icons.smart_display);
      expect(TeachingResourceType.externalLink.icon, Icons.link);
    });

    test('모든 타입은 고유한 label을 가진다', () {
      final labels = TeachingResourceType.values.map((t) => t.label).toSet();
      expect(labels.length, TeachingResourceType.values.length);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // parseYoutubeUrl
  // ═══════════════════════════════════════════════════════════════════════════

  group('parseYoutubeUrl', () {
    test('표준 URL에서 비디오 ID 추출', () {
      final result = TeachingResource.parseYoutubeUrl(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
      expect(result.videoId, 'dQw4w9WgXcQ');
      expect(result.startSeconds, isNull);
    });

    test('짧은 URL에서 비디오 ID 추출', () {
      final result = TeachingResource.parseYoutubeUrl(
        'https://youtu.be/dQw4w9WgXcQ',
      );
      expect(result.videoId, 'dQw4w9WgXcQ');
    });

    test('타임스탬프 파라미터 추출 (?t=92)', () {
      final result = TeachingResource.parseYoutubeUrl(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=92',
      );
      expect(result.videoId, 'dQw4w9WgXcQ');
      expect(result.startSeconds, 92);
    });

    test('짧은 URL + 타임스탬프', () {
      final result = TeachingResource.parseYoutubeUrl(
        'https://youtu.be/dQw4w9WgXcQ?t=30',
      );
      expect(result.videoId, 'dQw4w9WgXcQ');
      expect(result.startSeconds, 30);
    });

    test('잘못된 URL은 null videoId 반환', () {
      final result = TeachingResource.parseYoutubeUrl(
        'https://example.com/not-a-video',
      );
      expect(result.videoId, isNull);
      expect(result.startSeconds, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // thumbnailUrl
  // ═══════════════════════════════════════════════════════════════════════════

  group('thumbnailUrl', () {
    test('유효한 비디오 ID → 썸네일 URL 생성', () {
      expect(
        TeachingResource.thumbnailUrl('dQw4w9WgXcQ'),
        'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      );
    });

    test('null 비디오 ID → null 반환', () {
      expect(TeachingResource.thumbnailUrl(null), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // launchUrl
  // ═══════════════════════════════════════════════════════════════════════════

  group('launchUrl', () {
    test('YouTube + startSeconds → 타임스탬프 포함 URL', () {
      final resource = createTeachingResource(
        youtubeUrl: 'https://www.youtube.com/watch?v=abc12345678',
        youtubeVideoId: 'abc12345678',
        youtubeStartSeconds: 92,
      );
      expect(
        resource.launchUrl,
        'https://www.youtube.com/watch?v=abc12345678&t=92s',
      );
    });

    test('YouTube + startSeconds 0 → 원본 URL 반환', () {
      final resource = createTeachingResource(
        youtubeUrl: 'https://www.youtube.com/watch?v=abc12345678',
        youtubeVideoId: 'abc12345678',
        youtubeStartSeconds: 0,
      );
      expect(resource.launchUrl, 'https://www.youtube.com/watch?v=abc12345678');
    });

    test('YouTube + startSeconds null → 원본 URL 반환', () {
      final resource = createTeachingResource(
        youtubeUrl: 'https://www.youtube.com/watch?v=abc12345678',
        youtubeStartSeconds: null,
      );
      expect(resource.launchUrl, 'https://www.youtube.com/watch?v=abc12345678');
    });

    test('externalLink → externalUrl 반환', () {
      final resource = createTeachingResource(
        type: TeachingResourceType.externalLink,
        youtubeUrl: null,
        youtubeVideoId: null,
        externalUrl: 'https://example.com/sheet.pdf',
      );
      expect(resource.launchUrl, 'https://example.com/sheet.pdf');
    });

    test('teacherRecording → null 반환', () {
      final resource = createTeachingResource(
        type: TeachingResourceType.teacherRecording,
        youtubeUrl: null,
        youtubeVideoId: null,
      );
      expect(resource.launchUrl, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // segmentDurationText
  // ═══════════════════════════════════════════════════════════════════════════

  group('segmentDurationText', () {
    test('start + end → "1:32~2:35" 형식', () {
      final resource = createTeachingResource(
        youtubeStartSeconds: 92,
        youtubeEndSeconds: 155,
      );
      expect(resource.segmentDurationText, '1:32~2:35');
    });

    test('start만 → "1:32~" 형식', () {
      final resource = createTeachingResource(youtubeStartSeconds: 92);
      expect(resource.segmentDurationText, '1:32~');
    });

    test('start null → null', () {
      final resource = createTeachingResource();
      expect(resource.segmentDurationText, isNull);
    });

    test('YouTube 아닌 타입 → null', () {
      final resource = createTeachingResource(
        type: TeachingResourceType.externalLink,
        youtubeUrl: null,
        youtubeVideoId: null,
        youtubeStartSeconds: 92,
      );
      expect(resource.segmentDurationText, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // timestampText
  // ═══════════════════════════════════════════════════════════════════════════

  group('timestampText', () {
    test('start + end → "1:32 ~ 2:35" 형식 (공백 포함)', () {
      final resource = createTeachingResource(
        youtubeStartSeconds: 92,
        youtubeEndSeconds: 155,
      );
      expect(resource.timestampText, '1:32 ~ 2:35');
    });

    test('start만 → "1:32부터" 형식', () {
      final resource = createTeachingResource(youtubeStartSeconds: 92);
      expect(resource.timestampText, '1:32부터');
    });

    test('start null → null', () {
      final resource = createTeachingResource();
      expect(resource.timestampText, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // _formatSeconds (tested via public getters)
  // ═══════════════════════════════════════════════════════════════════════════

  group('시간 포맷팅', () {
    test('0초 → "0:00"', () {
      final resource = createTeachingResource(youtubeStartSeconds: 0);
      expect(resource.timestampText, '0:00부터');
    });

    test('60초 → "1:00"', () {
      final resource = createTeachingResource(youtubeStartSeconds: 60);
      expect(resource.timestampText, '1:00부터');
    });

    test('300초 → "5:00"', () {
      final resource = createTeachingResource(youtubeStartSeconds: 300);
      expect(resource.timestampText, '5:00부터');
    });

    test('5초 → "0:05"', () {
      final resource = createTeachingResource(youtubeStartSeconds: 5);
      expect(resource.timestampText, '0:05부터');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // copyWith
  // ═══════════════════════════════════════════════════════════════════════════

  group('copyWith', () {
    test('title 변경 시 다른 필드 유지', () {
      final original = createTeachingResource(
        id: 'tr_1',
        title: 'Original',
        youtubeStartSeconds: 92,
      );
      final copied = original.copyWith(title: 'Changed');

      expect(copied.title, 'Changed');
      expect(copied.id, 'tr_1');
      expect(copied.youtubeStartSeconds, 92);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // equality
  // ═══════════════════════════════════════════════════════════════════════════

  group('equality', () {
    test('같은 ID → 동일', () {
      final a = createTeachingResource(id: 'tr_1');
      final b = createTeachingResource(id: 'tr_1', title: 'Different Title');
      expect(a, equals(b));
    });

    test('다른 ID → 다름', () {
      final a = createTeachingResource(id: 'tr_1');
      final b = createTeachingResource(id: 'tr_2');
      expect(a, isNot(equals(b)));
    });

    test('hashCode는 ID 기반', () {
      final a = createTeachingResource(id: 'tr_1');
      final b = createTeachingResource(id: 'tr_1');
      expect(a.hashCode, b.hashCode);
    });
  });
}
