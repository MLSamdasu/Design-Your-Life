// C0.5-L: 라이트 모드 ThemeData 정의
// 디자인 시스템의 컬러/타이포그래피 토큰을 기반으로 라이트 모드 ThemeData를 생성한다.
// 출력: ThemeData (라이트 테마)
import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'layout_tokens.dart';
import 'radius_tokens.dart';
import 'spacing_tokens.dart';
import 'typography_tokens.dart';

/// 라이트 모드 ThemeData 빌더
/// ColorScheme, TextTheme, AppBar, Button, Input, SnackBar, Dialog 스타일을 정의한다
ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // ColorScheme: Glassmorphism 배경 위에서는 Material 색상보다 토큰을 직접 사용한다
    colorScheme: ColorScheme.light(
      primary: ColorTokens.main,
      onPrimary: ColorTokens.white,
      primaryContainer: ColorTokens.sub,
      onPrimaryContainer: ColorTokens.main,
      secondary: ColorTokens.mainLight,
      onSecondary: ColorTokens.white,
      surface: ColorTokens.gray50,
      onSurface: ColorTokens.gray900,
      error: ColorTokens.error,
      onError: ColorTokens.white,
      outline: ColorTokens.gray200,
      outlineVariant: ColorTokens.gray300,
    ),

    // 폰트 패밀리
    fontFamily: AppTypography.fontFamily,

    // TextTheme: Material 위젯에서 기본으로 사용하는 텍스트 스타일
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLg.copyWith(color: ColorTokens.gray900),
      displayMedium: AppTypography.displayMd.copyWith(color: ColorTokens.gray900),
      headlineLarge: AppTypography.headingLg.copyWith(color: ColorTokens.gray900),
      headlineMedium: AppTypography.headingMd.copyWith(color: ColorTokens.gray900),
      headlineSmall: AppTypography.headingSm.copyWith(color: ColorTokens.gray900),
      titleLarge: AppTypography.titleLg.copyWith(color: ColorTokens.gray900),
      titleMedium: AppTypography.titleMd.copyWith(color: ColorTokens.gray700),
      bodyLarge: AppTypography.bodyLg.copyWith(color: ColorTokens.gray700),
      bodyMedium: AppTypography.bodyMd.copyWith(color: ColorTokens.gray700),
      bodySmall: AppTypography.bodySm.copyWith(color: ColorTokens.gray700),
      labelLarge: AppTypography.captionLg.copyWith(color: ColorTokens.gray700),
      labelSmall: AppTypography.captionSm.copyWith(color: ColorTokens.gray600),
    ),

    // AppBar: 투명 배경, 텍스트/아이콘 색상은 colorScheme에서 자동 상속한다
    // 라이트 테마에서는 onSurface(gray900)를 사용하여 밝은 배경 위 가독성을 확보한다
    appBarTheme: AppBarTheme(
      backgroundColor: ColorTokens.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.titleLg.copyWith(color: ColorTokens.gray900),
      iconTheme: const IconThemeData(color: ColorTokens.gray900),
    ),

    // ElevatedButton: CTA 버튼 기본 스타일
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

    // InputDecoration: 라이트 모드 입력 필드 기본 스타일
    // 밝은 배경 테마에서 가독성을 확보하기 위해 gray 기반 색상을 사용한다
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorTokens.gray900.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(
          color: ColorTokens.gray900.withValues(alpha: 0.15),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(
          color: ColorTokens.gray900.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(
          color: ColorTokens.gray900.withValues(alpha: 0.40),
          width: AppLayout.borderMedium,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(
          color: ColorTokens.error.withValues(alpha: 0.60),
        ),
      ),
      hintStyle: AppTypography.bodyLg.copyWith(
        color: ColorTokens.gray900.withValues(alpha: 0.55),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lgXl,
      ),
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    ),

    // Dialog: 라이트 모드에서는 반투명 흰색 대신 불투명 흰색을 사용한다
    // 실제 배경은 각 테마 프리셋의 modalDecoration에서 오버라이드된다
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.bottomSheet),
      ),
      backgroundColor: ColorTokens.white.withValues(alpha: 0.95),
      elevation: 0,
    ),
  );
}
