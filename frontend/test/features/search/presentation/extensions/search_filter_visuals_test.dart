import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/search/domain/entities/search_filter.dart';
import 'package:lessonaza/features/search/presentation/extensions/search_filter_visuals.dart';

void main() {
  group('SearchFilterVisuals', () {
    test('provides labels for search scopes', () {
      expect(SearchScope.all.label, '전체');
      expect(SearchScope.teachers.label, '선생님');
      expect(SearchScope.students.label, '학생');
      expect(SearchScope.lessons.label, '레슨');
    });

    test('provides labels for search result types', () {
      expect(SearchResultType.teacher.label, '선생님');
      expect(SearchResultType.student.label, '학생');
      expect(SearchResultType.lesson.label, '레슨');
      expect(SearchResultType.practice.label, '연습');
    });
  });
}
