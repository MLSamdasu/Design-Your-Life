// C0.5: ThemeData 정의 (라이트/다크 모드)
// 디자인 시스템의 컬러 토큰과 타이포그래피 토큰을 기반으로 MaterialApp의 ThemeData를 생성한다.
// OUT: ThemeData (라이트/다크 테마)
import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'radius_tokens.dart';
import 'spacing_tokens.dart';
import 'typography_tokens.dart';

/// 앱 테마 팩토리 (C0.5)
/// color_tokens.dart와 typography_tokens.dart 토큰을 조합하여 ThemeData를 생성한다
/// Glassmorphism 테마는 그라디언트 배경 위에 유리 카드를 올리는 구조로,
/// Material 기본 테마를 최소화하고 커스텀 위젯에 직접 토큰을 적용한다
abstract class AppTheme {
  // ─── 라이트 모드 테마 ─────────────────────────────────────────────────────
  /// 라이트 모드 ThemeData
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ColorScheme: Glassmorphism 배경 위에서는 Material 색상보다 토큰을 직접 사용한다
      colorScheme: ColorScheme.light(
        primary: ColorTokens.main,
        onPrimary: Colors.white,
        primaryContainer: ColorTokens.sub,
        onPrimaryContainer: ColorTokens.main,
        secondary: ColorTokens.mainLight,
        onSecondary: Colors.white,
        surface: ColorTokens.gray50,
        onSurface: ColorTokens.gray900,
        error: ColorTokens.error,
        onError: Colors.white,
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
        bodySmall: AppTypography.bodySm.copyWith(color: ColorTokens.gray600),
        labelLarge: AppTypography.captionLg.copyWith(color: ColorTokens.gray700),
        labelSmall: AppTypography.captionSm.copyWith(color: ColorTokens.gray500),
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
          foregroundColor: Colors.white,
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
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: ColorTokens.error.withValues(alpha: 0.60),
          ),
        ),
        hintStyle: AppTypography.bodyLg.copyWith(
          color: ColorTokens.gray900.withValues(alpha: 0.40),
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
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        elevation: 0,
      ),
    );
  }

  // ─── 다크 모드 테마 ───────────────────────────────────────────────────────
  /// 다크 모드 ThemeData
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.dark(
        primary: ColorTokens.main,
        onPrimary: Colors.white,
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
        labelSmall: AppTypography.captionSm.copyWith(color: ColorTokens.gray400),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: ColorTokens.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLg.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.main,
          foregroundColor: Colors.white,
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
      // 어두운 배경 위에서 가독성을 확보하기 위해 흰색 기반 색상을 사용한다
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.20),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.20),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.50),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: ColorTokens.errorLight.withValues(alpha: 0.60),
          ),
        ),
        hintStyle: AppTypography.bodyLg.copyWith(
          color: Colors.white.withValues(alpha: 0.40),
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

      // Dialog: 다크 모드에서는 반투명 흰색 배경으로 유리 효과를 유지한다
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.bottomSheet),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.20),
        elevation: 0,
      ),
    );
  }
}
