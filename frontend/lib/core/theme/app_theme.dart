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
      scaffoldBackgroundColor: AppColors.paper,

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

      // Dialog — Notebook × Score: AlertDialog 표면을 `paper` 로 승격, M3 tint/elevation 제거.
      // 기존에는 `titleTextStyle` 만 등록되어 backgroundColor/shape/surfaceTintColor 가 M3 기본값(
      // `surfaceContainerHigh` 회색 tint + radius 28 + elevation 6)으로 폴백됐다.
      // 312 Dialog/AlertDialog 호출부 전반에 Notebook 질감(paper + radiusLarge + flat)을 단일 지점으로 보급.
      // bottomSheetTheme 와 동일한 시그니처 — modal 표면 일관성 확보.
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        titleTextStyle: NotebookTypography.dialogTitle,
      ),

      // BottomSheet — §7.117 각진 전수: top edge 도 zero 로 전환.
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        modalBackgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: AppColors.inkScrim,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: AppColors.inkQuaternary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      // Card — §7.117 각진.
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        margin: EdgeInsets.zero,
      ),

      // ElevatedButton — §7.117 각진.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          minimumSize: Size(double.infinity, AppSpacing.buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: AppTypography.button,
        ),
      ),

      // FilledButton — §7.117 각진.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.paperAccent,
          foregroundColor: AppColors.paper,
          minimumSize: Size(double.infinity, AppSpacing.buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: AppTypography.button,
        ),
      ),

      // OutlinedButton — §7.117 각진.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: Size(double.infinity, AppSpacing.buttonHeight),
          side: const BorderSide(color: AppColors.ink),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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

      // FloatingActionButton — Notebook × Score: .extended FAB 18개(15 파일) 기본 배경을 Vermillion 으로 승격.
      // 기존에는 6개 호출부만 인라인 `backgroundColor: paperAccent` 를 지정했고, 9개 호출부는 M3 기본값
      // (colorScheme.primaryContainer = inkQuaternary 회색)로 폴백돼 Notebook CTA 시그니처가 끊겼다.
      // filledButtonTheme 와 동일한 Vermillion·paper·elevation 0 시그니처로 CTA 색상 일관성 확보.
      // .extended 의 StadiumBorder() 기본값은 유지 — Notebook ticket/pill 형태와 조화.
      // 인라인 `backgroundColor` / `foregroundColor` 오버라이드 6건은 Flutter 속성 우선순위로 유지 — 회귀 0.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.paperAccent,
        foregroundColor: AppColors.paper,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        // Hyen 표준 H8 — 터치 타깃 44px. M3 기본 56 은 크림 종이 위에서 과하게 무겁다.
        // .extended FAB 은 extendedSizeConstraints 를 쓰므로 영향 없음.
        sizeConstraints: const BoxConstraints.tightFor(width: 44, height: 44),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        extendedTextStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.paper,
        ),
      ),

      // Input — §7.117 각진.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.inkQuaternary),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.inkQuaternary),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.ink, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.paperAccent),
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

      // Checkbox — §7.117 각진.
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.ink;
          }
          return Colors.transparent;
        }),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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

      // SnackBar — §7.117 각진.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.paper,
        ),
        actionTextColor: AppColors.paperAccent,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.paper,
        surfaceTintColor: AppColors.paper,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.ink, width: 2),
        ),
        textStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // DropdownMenu — §7.117 각진.
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.paper),
          surfaceTintColor: WidgetStateProperty.all(AppColors.paper),
          elevation: WidgetStateProperty.all(2),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: AppColors.ink, width: 2),
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.ink, width: 2),
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

      // TimePicker — §7.117 각진.
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.paper,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.ink, width: 2),
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
        hourMinuteShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
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

      // Dialog — Notebook × Score: dark 테마에서도 동일 설계 — AlertDialog 표면을 surfaceDark 로 승격.
      // bottomSheetTheme(surfaceDark) 와 시그니처 통일 — 라이트/다크 전환 시 modal 표면 일관성 확보.
      // M3 기본 tint/radius 28/elevation 6 폴백 제거, Notebook 질감(flat + radiusLarge) 유지.
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        titleTextStyle: NotebookTypography.dialogTitle.copyWith(
          color: AppColors.textPrimaryDark,
        ),
      ),

      // BottomSheet — §7.117 각진.
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        modalBackgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: AppColors.inkScrimStrong,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: AppColors.borderDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      // Card — §7.117 각진.
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        margin: EdgeInsets.zero,
      ),

      // ElevatedButton — §7.117 각진.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.paper,
          foregroundColor: AppColors.backgroundDark,
          minimumSize: Size(double.infinity, AppSpacing.buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: AppTypography.button,
        ),
      ),

      // FilledButton — §7.117 각진.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.paperAccent,
          foregroundColor: AppColors.paper,
          minimumSize: Size(double.infinity, AppSpacing.buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: AppTypography.button,
        ),
      ),

      // OutlinedButton — §7.117 각진.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.paper,
          minimumSize: Size(double.infinity, AppSpacing.buttonHeight),
          side: const BorderSide(color: AppColors.paper),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: AppTypography.button,
        ),
      ),

      // TextButton — Notebook × Score: dark 테마에서도 TextButton foreground 를 paper 로 고정.
      // light 테마에서는 ink(검정) 로 등록했으나 dark 테마에서는 미등록 상태였다 — 다크 표면 위
      // 기본 colorScheme.primary(purple) 로 폴백돼 Notebook 팔레트 외 색상이 혼입될 수 있었다.
      // light 테마와 동일 시그니처(bodyMedium w500) 로 밝기 전환 시 텍스트 버튼 타이포 일관성 확보.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.paper,
          textStyle: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // FloatingActionButton — Notebook × Score: dark 테마에서도 Vermillion CTA 시그니처 유지.
      // filledButtonTheme(dark) 와 동일한 paperAccent·paper·elevation 0 — light/dark 전환 시 FAB 색상 일관성 확보.
      // dark 표면 위 paperAccent 는 충분한 대비, foregroundColor 는 paper 로 밝은 라벨 유지.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.paperAccent,
        foregroundColor: AppColors.paper,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        // Hyen 표준 H8 — 터치 타깃 44px. M3 기본 56 은 크림 종이 위에서 과하게 무겁다.
        // .extended FAB 은 extendedSizeConstraints 를 쓰므로 영향 없음.
        sizeConstraints: const BoxConstraints.tightFor(width: 44, height: 44),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        extendedTextStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.paper,
        ),
      ),

      // Input — §7.117 각진.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondaryDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.paper, width: 2),
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

      // Checkbox — §7.117 각진.
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.paper;
          }
          return Colors.transparent;
        }),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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

      // SnackBar — §7.117 각진.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        actionTextColor: AppColors.paperAccent,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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

      // PopupMenu — §7.117 각진.
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surfaceDark,
        surfaceTintColor: AppColors.surfaceDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.paper, width: 2),
        ),
        textStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // DropdownMenu — §7.117 각진.
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.surfaceDark),
          surfaceTintColor: WidgetStateProperty.all(AppColors.surfaceDark),
          elevation: WidgetStateProperty.all(2),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: AppColors.paper, width: 2),
            ),
          ),
        ),
        textStyle: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // DatePicker — §7.117 각진.
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: AppColors.surfaceDark,
        headerBackgroundColor: AppColors.surfaceDark,
        headerForegroundColor: AppColors.textPrimaryDark,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.paper, width: 2),
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

      // TimePicker — §7.117 각진.
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.paper, width: 2),
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
        hourMinuteShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}
