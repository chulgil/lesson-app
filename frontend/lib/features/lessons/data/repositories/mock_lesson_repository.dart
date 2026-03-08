import 'package:uuid/uuid.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/lesson_repository.dart';

/// Mock implementation for development
class MockLessonRepository implements LessonRepository {
  final _uuid = const Uuid();
  final List<Lesson> _lessons = [];

  MockLessonRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _lessons.addAll([
      // === Today's Lessons (4) ===
      // lesson_001: student_1 김민준, completed, 10:00, feedback filled, 바이올린
      Lesson(
        id: 'lesson_001',
        studentId: 'student_1',
        studentName: '김민준',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '바이올린',
        date: today,
        startTime: '10:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_001',
            name: 'Concerto in A minor',
            composer: 'Vivaldi',
            opus: 'RV 356',
            movement: '1악장',
          ),
          LessonPiece(
            id: 'piece_002',
            name: '가보트',
            composer: 'Gossec',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        feedback: '활 잡는 자세가 많이 좋아졌어요. 비발디 1악장 카덴차 부분 음정이 불안정하니 천천히 반복 연습해오세요. 가보트는 리듬감이 좋아졌습니다.',
        keyPoints: ['카덴차 음정 정확도', '보잉 방향 전환', '가보트 리듬 안정'],
        practiceTips: '메트로놈 72 템포에서 카덴차 구간 10회 반복 후, 템포를 4씩 올려보세요.',
        assignments: ['비발디 1악장 전체 암보', '가보트 p.12~14 반복'],
        createdAt: today.subtract(const Duration(days: 14)),
      ),

      // lesson_002: student_2 이서연, scheduled, 14:00, 피아노
      Lesson(
        id: 'lesson_002',
        studentId: 'student_2',
        studentName: '이서연',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '피아노',
        date: today,
        startTime: '14:00',
        duration: 60,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(
            id: 'piece_003',
            name: 'Sonata Pathétique',
            composer: 'Beethoven',
            opus: 'Op.13',
            movement: '2악장 Adagio cantabile',
          ),
        ],
        location: const LessonLocationInfo(
          name: '학생 자택 방문',
          address: '서울시 서초구 반포동 45-7',
        ),
        createdAt: today.subtract(const Duration(days: 7)),
      ),

      // lesson_003: student_5 정다은, scheduled, 16:00, 바이올린 (초등학생)
      Lesson(
        id: 'lesson_003',
        studentId: 'student_5',
        studentName: '정다은',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '바이올린',
        date: today,
        startTime: '16:00',
        duration: 60,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(
            id: 'piece_004',
            name: '작은 별 변주곡',
            composer: 'Mozart',
            notes: '스즈키 교본 1권',
          ),
          LessonPiece(
            id: 'piece_005',
            name: '긴긴밤',
            notes: '한국 동요, 활 연습용',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        createdAt: today.subtract(const Duration(days: 5)),
      ),

      // lesson_004: student_12 박준혁, scheduled, 18:00, 바이올린
      Lesson(
        id: 'lesson_004',
        studentId: 'student_12',
        studentName: '박준혁',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '바이올린',
        date: today,
        startTime: '18:00',
        duration: 60,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(
            id: 'piece_006',
            name: 'Minuet No.3',
            composer: 'Bach',
            notes: '스즈키 교본 2권',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        createdAt: today.subtract(const Duration(days: 3)),
      ),

      // === Tomorrow's Lessons (3) ===
      // lesson_005: student_3 박지호, scheduled, 11:00, 첼로, online (Zoom)
      Lesson(
        id: 'lesson_005',
        studentId: 'student_3',
        studentName: '박지호',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '첼로',
        date: today.add(const Duration(days: 1)),
        startTime: '11:00',
        duration: 60,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(
            id: 'piece_007',
            name: 'Suite No.1 in G major',
            composer: 'Bach',
            opus: 'BWV 1007',
            movement: 'Prélude',
          ),
        ],
        location: const LessonLocationInfo(name: '온라인 (Zoom)'),
        createdAt: today.subtract(const Duration(days: 2)),
      ),

      // lesson_006: student_1 김민준, scheduled, 15:00, 바이올린
      Lesson(
        id: 'lesson_006',
        studentId: 'student_1',
        studentName: '김민준',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '바이올린',
        date: today.add(const Duration(days: 1)),
        startTime: '15:00',
        duration: 60,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(
            id: 'piece_008',
            name: 'Concerto in A minor',
            composer: 'Vivaldi',
            opus: 'RV 356',
            movement: '2악장',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        createdAt: today.subtract(const Duration(days: 1)),
      ),

      // lesson_007: student_11 이하은, scheduled, 17:00, 피아노 (복수악기 중 피아노)
      Lesson(
        id: 'lesson_007',
        studentId: 'student_11',
        studentName: '이하은',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '피아노',
        date: today.add(const Duration(days: 1)),
        startTime: '17:00',
        duration: 60,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(
            id: 'piece_009',
            name: 'Arabesque No.1',
            composer: 'Debussy',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        createdAt: today,
      ),

      // === Past Lessons - Yesterday (2) ===
      // lesson_008: student_3 박지호, completed, 14:00, feedback+keyPoints+practiceTips 모두 있음
      Lesson(
        id: 'lesson_008',
        studentId: 'student_3',
        studentName: '박지호',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '첼로',
        date: today.subtract(const Duration(days: 1)),
        startTime: '14:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_010',
            name: 'Cello Sonata No.3',
            composer: 'Beethoven',
            opus: 'Op.69',
            movement: '1악장',
          ),
          LessonPiece(
            id: 'piece_011',
            name: '백조',
            composer: 'Saint-Saëns',
            notes: '동물의 사육제 중',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        feedback: '베토벤 소나타 1악장 전개부 진입이 매끄러워졌어요. 왼손 포지션 이동 시 음이 끊기지 않도록 주의하세요. 백조는 레가토 표현이 아름다웠습니다.',
        keyPoints: ['포지션 이동 매끄럽게', '전개부 다이내믹 대비', '백조 레가토 보잉'],
        practiceTips: '포지션 이동 구간(마디 34~42)을 느린 템포로 매일 5회 연습. 백조는 보잉 한 활에 4박 유지 연습.',
        assignments: ['베토벤 소나타 1악장 전체 통주', '백조 암보'],
        createdAt: today.subtract(const Duration(days: 10)),
      ),

      // lesson_009: student_4 최유진, completed, 16:00, 체험 레슨 완료, feedback 있음
      Lesson(
        id: 'lesson_009',
        studentId: 'student_4',
        studentName: '최유진',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '플루트',
        date: today.subtract(const Duration(days: 1)),
        startTime: '16:00',
        duration: 45,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_012',
            name: 'Syrinx',
            composer: 'Debussy',
            notes: '체험 레슨 - 발췌 연주',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        feedback: '체험 레슨 진행했습니다. 호흡 기초가 잘 되어 있고 음감이 좋습니다. 저음역 톤이 안정적이며 정규 수업 진행 시 빠른 성장이 기대됩니다.',
        createdAt: today.subtract(const Duration(days: 3)),
      ),

      // === Past Lessons - 3 days ago (2) ===
      // lesson_010: student_2 이서연, completed, 14:00, 피아노
      Lesson(
        id: 'lesson_010',
        studentId: 'student_2',
        studentName: '이서연',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '피아노',
        date: today.subtract(const Duration(days: 3)),
        startTime: '14:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_013',
            name: 'Sonata Pathétique',
            composer: 'Beethoven',
            opus: 'Op.13',
            movement: '1악장 Grave - Allegro',
          ),
          LessonPiece(
            id: 'piece_014',
            name: 'Nocturne',
            composer: 'Chopin',
            opus: 'Op.9 No.2',
          ),
        ],
        location: const LessonLocationInfo(
          name: '학생 자택 방문',
          address: '서울시 서초구 반포동 45-7',
        ),
        feedback: '비창 1악장 서주부 Grave 표현이 깊어졌어요. 알레그로 진입 시 템포가 불안정하니 메트로놈과 함께 연습하세요. 녹턴은 루바토 감각이 좋습니다.',
        keyPoints: ['서주부-알레그로 전환 안정', '왼손 옥타브 정확도', '녹턴 페달링'],
        practiceTips: '비창 마디 11~15 구간 메트로놈 108에서 시작, 4씩 올려 132까지. 녹턴 페달은 하프 페달 연습.',
        createdAt: today.subtract(const Duration(days: 14)),
      ),

      // lesson_011: student_5 정다은, noShow, 16:00, 바이올린 (노쇼 케이스)
      Lesson(
        id: 'lesson_011',
        studentId: 'student_5',
        studentName: '정다은',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '바이올린',
        date: today.subtract(const Duration(days: 3)),
        startTime: '16:00',
        duration: 60,
        status: LessonStatus.noShow,
        pieces: const [
          LessonPiece(
            id: 'piece_015',
            name: '작은 별 변주곡',
            composer: 'Mozart',
            notes: '스즈키 교본 1권',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        createdAt: today.subtract(const Duration(days: 10)),
      ),

      // === Past Lessons - 1 week ago (2) ===
      // lesson_012: student_1 김민준, completed, 10:00, 바이올린 (히스토리)
      Lesson(
        id: 'lesson_012',
        studentId: 'student_1',
        studentName: '김민준',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '바이올린',
        date: today.subtract(const Duration(days: 7)),
        startTime: '10:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_016',
            name: 'Concerto in A minor',
            composer: 'Vivaldi',
            opus: 'RV 356',
            movement: '1악장',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        feedback: '비발디 1악장 진도를 나갔습니다. 제시부 보잉 패턴은 안정적이나 전개부 진입 시 음정이 흔들려요. 포지션 이동 연습이 필요합니다.',
        keyPoints: ['제시부 보잉 패턴 유지', '전개부 포지션 이동'],
        practiceTips: '3포지션 이동 구간 슬로우 연습 매일 10분.',
        createdAt: today.subtract(const Duration(days: 21)),
      ),

      // lesson_013: student_11 이하은, completed, 17:00, 바이올린 (다른 악기)
      Lesson(
        id: 'lesson_013',
        studentId: 'student_11',
        studentName: '이하은',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '바이올린',
        date: today.subtract(const Duration(days: 7)),
        startTime: '17:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_017',
            name: '유머레스크',
            composer: 'Dvořák',
            opus: 'Op.101 No.7',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        feedback: '유머레스크 전반적으로 잘 진행했어요. 중간부 스타카토 구간에서 활의 탄력을 더 살려주세요. 피아노 레슨과 병행하니 음악적 표현이 풍부해지고 있어요.',
        keyPoints: ['스타카토 활 탄력', '중간부 다이내믹 변화'],
        practiceTips: '스타카토 구간 활 상단 1/3 지점에서 연습. 거울 보며 활 위치 확인.',
        createdAt: today.subtract(const Duration(days: 14)),
      ),

      // === Cancelled (1) ===
      // lesson_014: student_3 박지호, cancelled, 2 days ago, 학생 사정으로 취소
      Lesson(
        id: 'lesson_014',
        studentId: 'student_3',
        studentName: '박지호',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '첼로',
        date: today.subtract(const Duration(days: 2)),
        startTime: '14:00',
        duration: 60,
        status: LessonStatus.cancelledByStudentAdvance,
        pieces: const [],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        createdAt: today.subtract(const Duration(days: 9)),
      ),

      // === Edge Cases ===
      // lesson_015: student_1 김민준, completed, 5 days ago, 짧은 레슨 (30분)
      Lesson(
        id: 'lesson_015',
        studentId: 'student_1',
        studentName: '김민준',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '바이올린',
        date: today.subtract(const Duration(days: 5)),
        startTime: '10:00',
        duration: 30,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_018',
            name: '아리랑 변주곡',
            composer: '윤이상',
            notes: '편곡 버전 - 바이올린 독주',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        feedback: '보충 레슨으로 아리랑 변주곡 집중 연습했습니다. 한국적 비브라토 표현에 신경 써주세요.',
        keyPoints: ['한국적 비브라토', '장식음 처리'],
        createdAt: today.subtract(const Duration(days: 14)),
      ),

      // === Fix #7: Cancelled by Teacher ===
      // lesson_016: student_2 이서연, cancelledByTeacher, 4 days ago
      Lesson(
        id: 'lesson_016',
        studentId: 'student_2',
        studentName: '이서연',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '피아노',
        date: today.subtract(const Duration(days: 4)),
        startTime: '14:00',
        duration: 60,
        status: LessonStatus.cancelledByTeacher,
        pieces: const [],
        location: const LessonLocationInfo(
          name: '학생 자택 방문',
          address: '서울시 서초구 반포동 45-7',
        ),
        createdAt: today.subtract(const Duration(days: 11)),
      ),

      // === Fix #6: Old Lessons (2-3 months ago, history/archive) ===
      // lesson_017: student_1 김민준, completed, 30 days ago, 바이올린
      Lesson(
        id: 'lesson_017',
        studentId: 'student_1',
        studentName: '김민준',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '바이올린',
        date: today.subtract(const Duration(days: 30)),
        startTime: '10:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_019',
            name: 'Concerto in G minor',
            composer: 'Vivaldi',
            opus: 'RV 317',
            movement: '3악장',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        feedback: 'G단조 협주곡 3악장 마무리 레슨. 피날레 부분 템포가 안정적이었어요.',
        keyPoints: ['피날레 템포 안정', '마지막 카덴차'],
        createdAt: today.subtract(const Duration(days: 44)),
      ),

      // lesson_018: student_2 이서연, completed, 45 days ago, 피아노
      Lesson(
        id: 'lesson_018',
        studentId: 'student_2',
        studentName: '이서연',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '피아노',
        date: today.subtract(const Duration(days: 45)),
        startTime: '14:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_020',
            name: 'Invention No.8',
            composer: 'Bach',
            opus: 'BWV 779',
          ),
        ],
        location: const LessonLocationInfo(
          name: '학생 자택 방문',
          address: '서울시 서초구 반포동 45-7',
        ),
        feedback: '인벤션 8번 양손 독립 연주가 좋아졌어요. 성부 간 밸런스에 신경 쓰세요.',
        keyPoints: ['양손 독립', '성부 밸런스'],
        createdAt: today.subtract(const Duration(days: 59)),
      ),

      // lesson_019: student_3 박지호, completed, 60 days ago, 첼로
      Lesson(
        id: 'lesson_019',
        studentId: 'student_3',
        studentName: '박지호',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '첼로',
        date: today.subtract(const Duration(days: 60)),
        startTime: '11:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_021',
            name: 'Cello Sonata No.1',
            composer: 'Brahms',
            opus: 'Op.38',
            movement: '1악장',
          ),
        ],
        location: const LessonLocationInfo(name: '온라인 (Zoom)'),
        feedback: '브람스 소나타 1악장 도입부 완성. 왼손 비브라토 폭을 넓혀보세요.',
        keyPoints: ['비브라토 폭', '도입부 다이내믹'],
        createdAt: today.subtract(const Duration(days: 74)),
      ),

      // lesson_020: student_1 김민준, completed, 75 days ago, 바이올린
      Lesson(
        id: 'lesson_020',
        studentId: 'student_1',
        studentName: '김민준',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '바이올린',
        date: today.subtract(const Duration(days: 75)),
        startTime: '10:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_022',
            name: 'Partita No.2',
            composer: 'Bach',
            opus: 'BWV 1004',
            movement: 'Sarabande',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        feedback: '바흐 파르티타 사라반드 해석 레슨. 장식음 처리와 바로크 보잉 스타일 연습.',
        keyPoints: ['바로크 보잉', '장식음 해석'],
        createdAt: today.subtract(const Duration(days: 89)),
      ),

      // lesson_021: student_5 정다은, completed, 50 days ago, 바이올린
      Lesson(
        id: 'lesson_021',
        studentId: 'student_5',
        studentName: '정다은',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '바이올린',
        date: today.subtract(const Duration(days: 50)),
        startTime: '16:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_023',
            name: '즐거운 농부',
            composer: 'Schumann',
            notes: '스즈키 교본 1권',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        feedback: '즐거운 농부 리듬감이 좋아졌어요. 활 방향 전환 시 소리가 끊기지 않도록 연습하세요.',
        createdAt: today.subtract(const Duration(days: 64)),
      ),

      // lesson_022: student_11 이하은, completed, 40 days ago, 피아노
      Lesson(
        id: 'lesson_022',
        studentId: 'student_11',
        studentName: '이하은',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '피아노',
        date: today.subtract(const Duration(days: 40)),
        startTime: '17:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_024',
            name: 'Clair de Lune',
            composer: 'Debussy',
            notes: 'Suite bergamasque 3번',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        feedback: '달빛 소나타 페달 사용이 섬세해졌어요. 중간부 아르페지오 균일한 터치 연습 필요.',
        keyPoints: ['페달 섬세함', '아르페지오 균일'],
        createdAt: today.subtract(const Duration(days: 54)),
      ),

      // lesson_023: student_3 박지호, completed, 90 days ago, 첼로
      Lesson(
        id: 'lesson_023',
        studentId: 'student_3',
        studentName: '박지호',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '첼로',
        date: today.subtract(const Duration(days: 90)),
        startTime: '14:00',
        duration: 60,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_025',
            name: 'Kol Nidrei',
            composer: 'Bruch',
            opus: 'Op.47',
          ),
        ],
        location: const LessonLocationInfo(
          name: '하모니 음악학원',
          address: '서울시 강남구 테헤란로 123',
        ),
        feedback: '콜 니드라이 감정 표현이 깊어졌어요. 첫 진입부 비브라토에 감정을 실어주세요.',
        createdAt: today.subtract(const Duration(days: 104)),
      ),

      // === Fix #9: Teacher_2 Lessons (multi-teacher scenario) ===
      // lesson_024: student_2 이서연, completed, 2 days ago, teacher_2 (이론 수업)
      Lesson(
        id: 'lesson_024',
        studentId: 'student_2',
        studentName: '이서연',
        teacherId: 'teacher_2',
        teacherName: '박영희',
        instrument: '피아노',
        date: today.subtract(const Duration(days: 2)),
        startTime: '11:00',
        duration: 45,
        status: LessonStatus.completed,
        pieces: const [
          LessonPiece(
            id: 'piece_026',
            name: '화성학 기초',
            notes: '3화음 전위, 연결법',
          ),
        ],
        location: const LessonLocationInfo(
          name: '뮤직아트 스튜디오',
          address: '서울시 마포구 합정동 12-3',
        ),
        feedback: '3화음 전위 이해가 좋아요. 다음 시간에 7화음으로 넘어갈게요.',
        keyPoints: ['3화음 전위 완성', '연결법 규칙'],
        createdAt: today.subtract(const Duration(days: 16)),
      ),

      // lesson_025: student_3 박지호, scheduled, tomorrow, teacher_2 (이론 수업)
      Lesson(
        id: 'lesson_025',
        studentId: 'student_3',
        studentName: '박지호',
        teacherId: 'teacher_2',
        teacherName: '박영희',
        instrument: '첼로',
        date: today.add(const Duration(days: 1)),
        startTime: '13:00',
        duration: 45,
        status: LessonStatus.scheduled,
        pieces: const [
          LessonPiece(
            id: 'piece_027',
            name: '음악 이론',
            notes: '조성 분석 - 소나타 형식',
          ),
        ],
        location: const LessonLocationInfo(
          name: '뮤직아트 스튜디오',
          address: '서울시 마포구 합정동 12-3',
        ),
        createdAt: today.subtract(const Duration(days: 5)),
      ),
    ]);
  }

  @override
  Future<List<Lesson>> getLessons() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_lessons);
  }

  @override
  Future<List<Lesson>> getLessonsByStudent(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _lessons.where((l) => l.studentId == studentId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<Lesson>> getLessonsByDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _lessons.where((l) {
      return l.date.year == date.year &&
          l.date.month == date.month &&
          l.date.day == date.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<List<Lesson>> getLessonsByDateRange(
      DateTime start, DateTime end) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _lessons.where((l) {
      return l.date.isAfter(start.subtract(const Duration(days: 1))) &&
          l.date.isBefore(end.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<List<Lesson>> getUpcomingLessons({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    return _lessons
        .where((l) =>
            l.status == LessonStatus.scheduled &&
            l.date.isAfter(now.subtract(const Duration(hours: 2))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date))
      ..take(limit);
  }

  @override
  Future<List<Lesson>> getRecentLessons({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    return _lessons
        .where((l) =>
            l.status == LessonStatus.completed &&
            l.date.isBefore(now))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date))
      ..take(limit);
  }

  @override
  Future<Lesson?> getLesson(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _lessons.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Lesson> createLesson(Lesson lesson) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newLesson = lesson.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _lessons.add(newLesson);
    return newLesson;
  }

  @override
  Future<Lesson> updateLesson(Lesson lesson) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _lessons.indexWhere((l) => l.id == lesson.id);
    if (index == -1) {
      throw Exception('Lesson not found');
    }
    final updated = lesson.copyWith(updatedAt: DateTime.now());
    _lessons[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteLesson(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _lessons.removeWhere((l) => l.id == id);
  }

  @override
  Future<void> cancelLesson(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _lessons.indexWhere((l) => l.id == id);
    if (index == -1) {
      throw Exception('Lesson not found');
    }
    _lessons[index] = _lessons[index].copyWith(
      status: LessonStatus.cancelled,
      updatedAt: DateTime.now(),
    );
  }
}
