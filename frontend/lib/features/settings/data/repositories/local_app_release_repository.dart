import '../../../../core/config/environment.dart';
import '../../domain/entities/app_release.dart';
import '../../domain/repositories/app_release_repository.dart';

class LocalAppReleaseRepository implements AppReleaseRepository {
  const LocalAppReleaseRepository({
    this.currentVersion = EnvironmentConfig.appVersion,
  });

  final String currentVersion;

  @override
  Future<AppReleaseSnapshot> fetchReleaseSnapshot() async {
    return AppReleaseSnapshot(
      version: AppVersionSnapshot(
        currentVersion: currentVersion,
        buildNumber: '1',
        latestVersion: '1.1.0',
        checkedAt: DateTime.now().toUtc(),
      ),
      news: [
        AppNewsItem(
          id: 'schedule-flow-hardening',
          title: '레슨 운영 흐름 안정화',
          summary: '스케줄 변경 요청과 취소 요청의 상태 표시를 더 명확하게 정리했습니다.',
          publishedAt: DateTime.utc(2026, 5, 7),
        ),
        AppNewsItem(
          id: 'onboarding-practice-regression',
          title: '온보딩과 연습 일지 개선',
          summary: '프로필 설정과 연습 일지 공유 흐름의 회귀 테스트를 보강했습니다.',
          publishedAt: DateTime.utc(2026, 5, 7),
        ),
      ],
      roadmap: [
        AppRoadmapItem(
          id: 'update-banner',
          title: '앱 업데이트 안내',
          summary: '선생님 홈에서 중요한 업데이트를 바로 확인할 수 있게 합니다.',
          status: AppRoadmapStatus.inProgress,
        ),
        AppRoadmapItem(
          id: 'review-prompt',
          title: '리뷰 요청 타이밍',
          summary: '레슨 경험이 충분히 쌓인 뒤 자연스럽게 리뷰를 요청합니다.',
          status: AppRoadmapStatus.planned,
        ),
        AppRoadmapItem(
          id: 'news-archive',
          title: '새 소식 아카이브',
          summary: '변경사항과 앞으로의 개선 계획을 한 화면에서 제공합니다.',
          status: AppRoadmapStatus.planned,
        ),
      ],
    );
  }
}
