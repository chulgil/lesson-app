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

      // BottomSheet — Notebook × Score: 앱 전반 showModalBottomSheet 호출부에 paper 표면과 flat elevation 을 단일 지점으로 보급.
      // 기존 호출부 다수는 backgroundColor: Colors.transparent 로 sheet 내부 컨테이너가 배경을 그리는 패턴(오버라이드 유지).
      // 오버라이드 없는 호출부는 Material 기본 흰 배경이 노출돼 Notebook 질감이 끊겼는데, 테마 기본값을 paper 로 올려 승격.
      // surfaceTintColor: transparent 로 M3 tint 제거, elevation 0 으로 flat Notebook 유지.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        modalBackgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black54,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: AppColors.inkQuaternary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLarge),
          ),
        ),
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

      // FilledButton — Notebook × Score: M3 primary action 버튼의 기본 채움색을 Vermillion(paperAccent) 으로 승격.
      // 전 코드베이스 74개 호출부 중 21개가 `style: FilledButton.styleFrom(backgroundColor: AppColors.paperAccent)` 인라인을 반복.
      // 테마 단일지점 등록으로 동일한 Notebook CTA 를 53개 오버라이드 없는 호출부에도 자동 보급.
      // elevation 0 · shape radiusLarge · AppTypography.button — ElevatedButton 테마와 시그니처 통일.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.paperAccent,
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

      // Radio — Notebook × Score: 선택된 Radio 의 링·도트를 Vermillion 으로 통일.
      // 개별 activeColor override 없는 Radio 도 자동 Vermillion 적용 → Material blue 제거.
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.inkTertiary;
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return AppColors.inkQuaternary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return AppColors.paperAccentSoft;
          }
          return Colors.transparent;
        }),
      ),

      // Slider — Notebook × Score: BPM/튜닝/녹음 임계값 등 7개 Slider 의 active track + thumb 를 Vermillion 으로 통일.
      // Material blue 트랙/썸 제거. value indicator 는 ink 배경 + paper 텍스트 ("악보 위 잉크 방울").
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.paperAccent,
        inactiveTrackColor: AppColors.inkQuaternary,
        thumbColor: AppColors.paperAccent,
        overlayColor: AppColors.paperAccentSoft,
        valueIndicatorColor: AppColors.ink,
        valueIndicatorTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.paper,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Chip — Notebook × Score: FilterChip/ChoiceChip/ActionChip 의 선택 상태를 Vermillion 으로 통일.
      // Material blue 선택색 제거. 개별 호출부가 selectedColor/backgroundColor 를 override 하지 않은 경우의 기본값.
      // elevation 0 으로 Notebook flat 원칙 유지, checkmark 는 Vermillion.
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paperDark,
        selectedColor: AppColors.paperAccentSoft,
        disabledColor: AppColors.inkQuaternary,
        secondarySelectedColor: AppColors.paperAccentSoft,
        labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.ink),
        secondaryLabelStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.paperAccent,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: AppColors.paperAccent,
        elevation: 0,
        pressElevation: 0,
        side: const BorderSide(color: AppColors.inkQuaternary, width: 1),
        brightness: Brightness.light,
      ),

      // ExpansionTile — Notebook × Score: FAQ/진단/요일설정 등 접기/펼치기 타일을 flat 한 잉크 경계로 통일.
      // Material 기본은 primaryColor(보라) 기반의 iconColor/textColor 를 사용해 구형 보라 UI 잔재가 남는 문제가 있었음.
      // shape/collapsedShape 를 Border() 로 지정해 펼쳤을 때 상하 구분선을 제거 (Card 가 경계를 담당).
      // backgroundColor/collapsedBackgroundColor 는 투명 — Card 배경이 그대로 노출되도록 함.
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: AppColors.ink,
        collapsedIconColor: AppColors.inkSecondary,
        textColor: AppColors.ink,
        collapsedTextColor: AppColors.ink,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: Border(),
        collapsedShape: Border(),
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

      // IconButton — Notebook × Score: 전역 IconButton 기본 foreground 를 `ink` 로 승격.
      // colorScheme 에 `onSurfaceVariant` 를 지정하지 않아 M3 기본값(회색 슬레이트) 이 적용되던 문제를 해소.
      // 175 IconButton(+ .filled/.outlined/.styleFrom 변형) 중 21개 인라인 `icon: Icon(..., color: ...)`
      // 오버라이드는 Flutter 속성 우선순위로 유지 — 나머지 호출부가 ink 기본값으로 자동 승격.
      // appBarTheme.foregroundColor == ink 와 일치시켜 AppBar actions 내부 IconButton 의 색상 일관성 확보.
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.ink),
      ),

      // ListTile — Notebook × Score: icon/text 기본색 `ink`, 선택 상태는 Vermillion.
      // 36 파일 ListTile/RadioListTile/SwitchListTile 에 일괄 적용.
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.ink,
        textColor: AppColors.ink,
        selectedColor: AppColors.paperAccent,
        selectedTileColor: AppColors.paperAccentSoft,
      ),

      // PopupMenu — Notebook × Score: 메뉴 배경을 종이색, 테두리 2px ink.
      // 21 파일의 `PopupMenuButton` / `showMenu` 호출에 일괄 적용.
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.paper,
        surfaceTintColor: AppColors.paper,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        textStyle: const TextStyle(
          color: AppColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // DropdownMenu — Notebook × Score: 15 파일 DropdownMenu/DropdownButton 에 적용.
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.paper),
          surfaceTintColor: WidgetStateProperty.all(AppColors.paper),
          elevation: WidgetStateProperty.all(2),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: AppColors.ink, width: 2),
            ),
          ),
        ),
        textStyle: const TextStyle(
          color: AppColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // DatePicker — Notebook × Score: Material 기본 blue 을 Vermillion 으로 치환.
      // 15 파일 showDatePicker / showDateRangePicker 에 일괄 적용.
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: AppColors.paper,
        headerBackgroundColor: AppColors.paper,
        headerForegroundColor: AppColors.ink,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.paper;
          if (states.contains(WidgetState.disabled)) {
            return AppColors.inkTertiary;
          }
          return AppColors.ink;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return null;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.paper;
          return AppColors.paperAccent;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return null;
        }),
        todayBorder: const BorderSide(color: AppColors.paperAccent, width: 1),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.paper;
          return AppColors.ink;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return null;
        }),
        dividerColor: AppColors.ink,
      ),

      // TimePicker — Notebook × Score: Vermillion 선택 + paperAccentSoft 기본.
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.paper,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        hourMinuteColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return AppColors.paperAccentSoft;
        }),
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.paper;
          return AppColors.ink;
        }),
        dayPeriodColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return AppColors.paperAccentSoft;
        }),
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.paper;
          return AppColors.ink;
        }),
        dialHandColor: AppColors.paperAccent,
        dialBackgroundColor: AppColors.paperAccentSoft,
        dialTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.paper;
          return AppColors.ink;
        }),
        entryModeIconColor: AppColors.ink,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
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

      // BottomSheet — Notebook × Score: dark 테마의 modal 시트는 surfaceDark 를 paper 대체로 사용.
      // drag handle 은 borderDark — dark 표면 위에서 inkQuaternary 보다 가독성 확보.
      // modalBarrierColor 는 black87 로 dark 환경 강조 (light 는 black54).
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        modalBackgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black87,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: AppColors.borderDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLarge),
          ),
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

      // FilledButton — Notebook × Score: dark 테마에서도 Vermillion(paperAccent) CTA 유지.
      // dark surface 위의 paperAccent 는 충분한 대비 확보 — foregroundColor 는 paper 로 밝은 라벨 유지.
      // light 테마와 동일 시그니처로 라이트/다크 전환 시 CTA 색상 일관성 보장.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.paperAccent,
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

      // Radio — Notebook × Score: dark 에서도 선택 Radio 는 Vermillion. 미선택 은 borderDark.
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textSecondaryDark;
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return AppColors.borderDark;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return AppColors.paperAccentSoft;
          }
          return Colors.transparent;
        }),
      ),

      // Slider — Notebook × Score: dark 테마에서도 active track + thumb 는 Vermillion 유지.
      // inactive track 만 borderDark 로 교체, value indicator 는 surfaceDark 배경 + textPrimaryDark.
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.paperAccent,
        inactiveTrackColor: AppColors.borderDark,
        thumbColor: AppColors.paperAccent,
        overlayColor: AppColors.paperAccentSoft,
        valueIndicatorColor: AppColors.surfaceDark,
        valueIndicatorTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Chip — Notebook × Score: dark 테마의 FilterChip/ChoiceChip/ActionChip 기본 외형.
      // 배경은 surfaceDark, 선택색은 paperAccentSoft 유지 (light 와 동일 Vermillion 레이어).
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.paperAccentSoft,
        disabledColor: AppColors.borderDark,
        secondarySelectedColor: AppColors.paperAccentSoft,
        labelStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        secondaryLabelStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.paperAccent,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: AppColors.paperAccent,
        elevation: 0,
        pressElevation: 0,
        side: const BorderSide(color: AppColors.borderDark, width: 1),
        brightness: Brightness.dark,
      ),

      // ExpansionTile — Notebook × Score: dark 테마에서 Card 위 flat ExpansionTile.
      // 아이콘/텍스트는 textPrimaryDark 계열로, 접힌 화살표만 textSecondaryDark 로 한 단계 낮춰 위계 표현.
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: AppColors.textPrimaryDark,
        collapsedIconColor: AppColors.textSecondaryDark,
        textColor: AppColors.textPrimaryDark,
        collapsedTextColor: AppColors.textPrimaryDark,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: Border(),
        collapsedShape: Border(),
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

      // IconButton — Notebook × Score: dark 에서도 동일 설계 — IconButton foreground 를 textPrimaryDark 로 승격.
      // appBarTheme.foregroundColor == textPrimaryDark 와 일치시켜 라이트/다크 전환 시 AppBar 내부 IconButton 색상 이질감 제거.
      // 인라인 `icon: Icon(..., color: ...)` 오버라이드는 우선순위로 유지.
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textPrimaryDark),
      ),

      // ListTile — Notebook × Score: dark 에서는 paper 기본, Vermillion 선택.
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.paper,
        textColor: AppColors.textPrimaryDark,
        selectedColor: AppColors.paperAccent,
        selectedTileColor: AppColors.paperAccentSoft,
      ),

      // PopupMenu — Notebook × Score: dark 에서는 surfaceDark 배경 + paper 테두리.
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceDark,
        surfaceTintColor: AppColors.surfaceDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.paper, width: 2),
        ),
        textStyle: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // DropdownMenu — Notebook × Score: dark 대응.
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.surfaceDark),
          surfaceTintColor: WidgetStateProperty.all(AppColors.surfaceDark),
          elevation: WidgetStateProperty.all(2),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: AppColors.paper, width: 2),
            ),
          ),
        ),
        textStyle: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // DatePicker — Notebook × Score: dark 에서는 surfaceDark + paper 텍스트.
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: AppColors.surfaceDark,
        headerBackgroundColor: AppColors.surfaceDark,
        headerForegroundColor: AppColors.textPrimaryDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.paper, width: 2),
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.paper;
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textSecondaryDark;
          }
          return AppColors.textPrimaryDark;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return null;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.paper;
          return AppColors.paperAccent;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return null;
        }),
        todayBorder: const BorderSide(color: AppColors.paperAccent, width: 1),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.paper;
          return AppColors.textPrimaryDark;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return null;
        }),
        dividerColor: AppColors.paper,
      ),

      // TimePicker — Notebook × Score: dark 대응.
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.paper, width: 2),
        ),
        hourMinuteColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return AppColors.borderDark;
        }),
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.paper;
          return AppColors.textPrimaryDark;
        }),
        dayPeriodColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paperAccent;
          }
          return AppColors.borderDark;
        }),
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.paper;
          return AppColors.textPrimaryDark;
        }),
        dialHandColor: AppColors.paperAccent,
        dialBackgroundColor: AppColors.borderDark,
        dialTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.paper;
          return AppColors.textPrimaryDark;
        }),
        entryModeIconColor: AppColors.paper,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
