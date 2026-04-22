import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'notebook_typography.dart';

/// App theme configuration
class AppTheme {
  AppTheme._();

  /// Light theme
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,

      // Colors
      colorScheme: ColorScheme.light(
        primary: AppColors.ink,
        onPrimary: AppColors.paper,
        primaryContainer: AppColors.inkQuaternary,
        secondary: AppColors.paperAccent,
        onSecondary: AppColors.paper,
        secondaryContainer: AppColors.paperAccentSoft,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
        error: AppColors.paperAccent,
        onError: AppColors.paper,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.paperDark,

      // AppBar — Notebook × Score: Playfair Display 타이틀로 4대 시그니처(Playfair) 를 상단에 통일.
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: NotebookTypography.appBarTitle,
      ),

      // Dialog — Notebook × Score: AlertDialog 제목을 Playfair Display 로 통일.
      dialogTheme: DialogThemeData(
        titleTextStyle: NotebookTypography.dialogTitle,
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        margin: EdgeInsets.zero,
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          minimumSize: Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: Size(double.infinity, AppSpacing.buttonHeight),
          side: const BorderSide(color: AppColors.ink),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.inkQuaternary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.inkQuaternary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.ink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.paperAccent),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.inkTertiary,
        ),
        labelStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.inkSecondary,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.paper,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: AppColors.inkSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.caption,
        unselectedLabelStyle: AppTypography.caption,
      ),

      // TabBar — Notebook × Score: Vermillion 인디케이터 + ink 보조색. 특수 override(흰색, pill) 는 개별 화면에서 유지.
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.paperAccent,
        unselectedLabelColor: AppColors.inkSecondary,
        indicatorColor: AppColors.paperAccent,
        labelStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.bodyMedium,
        dividerColor: AppColors.inkQuaternary,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.inkQuaternary,
        thickness: 1,
        space: 0,
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.ink;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        side: const BorderSide(color: AppColors.inkQuaternary, width: 2),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ink,
        linearTrackColor: AppColors.inkQuaternary,
      ),

      // SnackBar — Notebook × Score: ink 배경 + paper 텍스트 + Vermillion 액션.
      // 앱 전반 알림의 4대 시그니처 통일 (Material 기본 회색 SnackBar 제거).
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.paper,
        ),
        actionTextColor: AppColors.paperAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),

      // Switch — Notebook × Score: 활성 thumb/track 을 Vermillion 으로 통일.
      // 개별 activeThumbColor override 가 없는 Switch 도 자동 Vermillion 적용.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return AppColors.paper;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccentSoft;
          }
          return AppColors.inkQuaternary;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return AppColors.inkTertiary;
        }),
      ),

      // TextSelection — Notebook × Score: 커서·선택·핸들을 Vermillion 으로 통일.
      // TextField 전역에 자동 적용.
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.paperAccent,
        selectionColor: AppColors.paperAccentSoft,
        selectionHandleColor: AppColors.paperAccent,
      ),

      // Icon — Notebook × Score: 앱 전역 아이콘 기본색을 `ink` 로 고정.
      // Material 기본 colorScheme.onSurface 를 우회해 명시적 Notebook 팔레트 선언.
      iconTheme: const IconThemeData(color: AppColors.ink, size: 24),
      primaryIconTheme: const IconThemeData(color: AppColors.ink),

      // ListTile — Notebook × Score: icon/text 기본색 `ink`, 선택 상태는 Vermillion.
      // 36 파일 ListTile/RadioListTile/SwitchListTile 에 일괄 적용.
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.ink,
        textColor: AppColors.ink,
        selectedColor: AppColors.paperAccent,
        selectedTileColor: AppColors.paperAccentSoft,
      ),
    );
  }

  /// Dark theme
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,

      // Colors
      colorScheme: ColorScheme.dark(
        primary: AppColors.paper,
        onPrimary: AppColors.textPrimaryDark,
        primaryContainer: AppColors.ink,
        secondary: AppColors.paperAccent,
        onSecondary: AppColors.paper,
        secondaryContainer: AppColors.paperAccentSoft,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        error: AppColors.paperAccent,
        onError: AppColors.paper,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.backgroundDark,

      // AppBar — Notebook × Score: Playfair Display 타이틀 (dark 테마는 color override).
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryDark,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: NotebookTypography.appBarTitle.copyWith(
          color: AppColors.textPrimaryDark,
        ),
      ),

      // Dialog — Notebook × Score: AlertDialog 제목 Playfair (dark 테마는 color override).
      dialogTheme: DialogThemeData(
        titleTextStyle: NotebookTypography.dialogTitle.copyWith(
          color: AppColors.textPrimaryDark,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        margin: EdgeInsets.zero,
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.paper,
          foregroundColor: AppColors.backgroundDark,
          minimumSize: Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.paper,
          minimumSize: Size(double.infinity, AppSpacing.buttonHeight),
          side: const BorderSide(color: AppColors.paper),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondaryDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.paper, width: 2),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiaryDark,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.paper,
        unselectedItemColor: AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.caption,
        unselectedLabelStyle: AppTypography.caption,
      ),

      // TabBar — Notebook × Score: Vermillion 인디케이터는 dark 에서도 유지. 라벨색만 dark palette 로 override.
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.paperAccent,
        unselectedLabelColor: AppColors.textSecondaryDark,
        indicatorColor: AppColors.paperAccent,
        labelStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.bodyMedium,
        dividerColor: AppColors.borderDark,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 0,
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paper;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        side: const BorderSide(color: AppColors.borderDark, width: 2),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.paper,
        linearTrackColor: AppColors.borderDark,
      ),

      // SnackBar — Notebook × Score: dark 테마는 surfaceDark 배경 + paper 텍스트. 액션은 Vermillion 유지.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        actionTextColor: AppColors.paperAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),

      // Switch — Notebook × Score: Vermillion active 유지, unselected 는 dark palette.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return AppColors.textSecondaryDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccentSoft;
          }
          return AppColors.borderDark;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return AppColors.textSecondaryDark;
        }),
      ),

      // TextSelection — Notebook × Score: dark 에서도 Vermillion 커서/선택 유지.
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.paperAccent,
        selectionColor: AppColors.paperAccentSoft,
        selectionHandleColor: AppColors.paperAccent,
      ),

      // Icon — Notebook × Score: dark 에서는 아이콘 기본색 paper.
      iconTheme: const IconThemeData(color: AppColors.paper, size: 24),
      primaryIconTheme: const IconThemeData(color: AppColors.paper),

      // ListTile — Notebook × Score: dark 에서는 paper 기본, Vermillion 선택.
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.paper,
        textColor: AppColors.textPrimaryDark,
        selectedColor: AppColors.paperAccent,
        selectedTileColor: AppColors.paperAccentSoft,
      ),
    );
  }
}
