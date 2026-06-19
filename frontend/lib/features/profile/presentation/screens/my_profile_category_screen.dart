import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';

/// 👤 내 프로필 카테고리 화면 (#765 — BottomSheet → 정식 라우트 승격).
///
/// 기존 `showMyProfileSheet` 의 5 항목을 그대로 옮긴 화면. 공개 설정 + 미리보기는
/// 단일 항목으로 통합(#803) — 상단 CTA 가 미리보기 SSOT.
class MyProfileCategoryScreen extends StatelessWidget {
  const MyProfileCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.categorySheetMyProfileTitle,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text(AppStrings.profileBasicInfoEditLabel),
            subtitle: const Text(AppStrings.profileBasicInfoEditSubtitle),
            onTap: () => context.push(AppRoutes.basicInfoEdit),
          ),
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text(AppStrings.profileInstrumentManagementLabel),
            subtitle: const Text(
              AppStrings.profileInstrumentManagementSubtitle,
            ),
            onTap: () => context.push(AppRoutes.instrumentManagement),
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text(AppStrings.profileCredentialsLabel),
            subtitle: const Text(AppStrings.profileCredentialsSubtitle),
            onTap: () => context.push(AppRoutes.extendedProfile),
          ),
          ListTile(
            leading: const Icon(Icons.library_music),
            title: const Text(AppStrings.profileRepertoireLabel),
            subtitle: const Text(AppStrings.profileRepertoireSubtitle),
            onTap: () => context.push(AppRoutes.repertoireManagement),
          ),
          // 공개 설정 + 미리보기 통합 (#803).
          ListTile(
            leading: const Icon(Icons.lock_outlined),
            title: const Text(AppStrings.profilePreviewAndPublic),
            subtitle: const Text(AppStrings.profileVisibilitySubtitleLabel),
            onTap: () => context.push(AppRoutes.profileVisibility),
          ),
        ],
      ),
    );
  }
}
