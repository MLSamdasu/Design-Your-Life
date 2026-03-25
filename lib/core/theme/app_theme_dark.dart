// C0.5-D: 다크 모드 ThemeData 정의
// 디자인 시스템의 컬러/타이포그래피 토큰을 기반으로 다크 모드 ThemeData를 생성한다.
// 출력: ThemeData (다크 테마)
import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'layout_tokens.dart';
import 'radius_tokens.dart';
import 'spacing_tokens.dart';
import 'typography_tokens.dart';

/// 다크 모드 ThemeData 빌더
/// ColorScheme, TextTheme, AppBar, Button, Input, SnackBar, Dialog 스타일을 정의한다
ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: ColorScheme.dark(
      primary: ColorTokens.main,
      onPrimary: ColorTokens.white,
      primaryContainer: ColorTokens.main.withValues(alpha: 0.15),
      onPrimaryContainer: ColorTokens.mainLight,
      secondary: ColorTokens.mainLight,
      onSecondary: ColorTokens.gray900,
      surface: ColorTokens.gray900,
      onSurface: ColorTokens.gray50,
      error: ColorTokens.errorLight,
      onError: ColorTokens.gray900,
      outline: ColorTokens.gray700,
      outlineVariant: ColorTokens.gray600,
    ),

    fontFamily: AppTypography.fontFamily,

    textTheme: TextTheme(
      displayLarge: AppTypography.displayLg.copyWith(color: ColorTokens.gray50),
      displayMedium: AppTypography.displayMd.copyWith(color: ColorTokens.gray50),
      headlineLarge: AppTypography.headingLg.copyWith(color: ColorTokens.gray50),
      headlineMedium: AppTypography.headingMd.copyWith(color: ColorTokens.gray50),
      headlineSmall: AppTypography.headingSm.copyWith(color: ColorTokens.gray50),
      titleLarge: AppTypography.titleLg.copyWith(color: ColorTokens.gray50),
      titleMedium: AppTypography.titleMd.copyWith(color: ColorTokens.gray200),
      bodyLarge: AppTypography.bodyLg.copyWith(color: ColorTokens.gray200),
      bodyMedium: AppTypography.bodyMd.copyWith(color: ColorTokens.gray200),
      bodySmall: AppTypography.bodySm.copyWith(color: ColorTokens.gray300),
      labelLarge: AppTypography.captionLg.copyWith(color: ColorTokens.gray200),
      labelSmall: AppTypography.captionSm.copyWith(color: ColorTokens.gray300),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: ColorTokens.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.titleLg.copyWith(color: ColorTokens.white),
      iconTheme: const IconThemeData(color: ColorTokens.white),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorTokens.main,
        foregroundColor: ColorTokens.white,
        textStyle: AppTypography.titleMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.lgXl,
        ),
        elevation: 0,
      ),
    ),

    // InputDecoration: 다크 모드 입력 필드 기본 스타일
    // 어두운 배경(Glassmorphism/Neon 포함) 위에서 고대비 가독성을 확보한다
    // Material TimePicker/DatePicker 등 기본 Material 위젯에 적용된다
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorTokens.white.withValues(alpha: 0.15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(
          color: ColorTokens.white.withValues(alpha: 0.30),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(
          color: ColorTokens.white.withValues(alpha: 0.30),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(
          color: ColorTokens.white.withValues(alpha: 0.60),
          width: AppLayout.borderMedium,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(
          color: ColorTokens.errorLight.withValues(alpha: 0.70),
        ),
      ),
      hintStyle: AppTypography.bodyLg.copyWith(
        color: ColorTokens.white.withValues(alpha: 0.70),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lgXl,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    ),

    // Dialog: 다크 모드 AlertDialog는 BackdropFilter 없이 단독 표시되므로
    // 충분히 불투명한 배경을 적용하여 텍스트 가독성을 보장한다
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.bottomSheet),
      ),
      backgroundColor: ColorTokens.gray800.withValues(alpha: 0.95),
      elevation: 0,
    ),
  );
}
