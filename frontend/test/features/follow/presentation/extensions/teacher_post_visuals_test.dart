import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/follow/domain/entities/teacher_post.dart';
import 'package:lessonaza/features/follow/presentation/extensions/teacher_post_visuals.dart';

void main() {
  group('PostTypeVisualX', () {
    test('maps post type labels', () {
      expect(PostType.performance.label, '발표회');
      expect(PostType.event.label, '이벤트');
      expect(PostType.notice.label, '공지사항');
    });

    test('maps post type emoji', () {
      expect(PostType.performance.emoji, '🎵');
      expect(PostType.event.emoji, '🎉');
      expect(PostType.notice.emoji, '📢');
    });
  });
}
