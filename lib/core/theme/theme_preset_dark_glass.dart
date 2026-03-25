// C0.5: Dark Glass 프리셋 데이터
// 딥 다크 배경 + 네온 글로우 보더 + 블러 효과의 다크 글라스모피즘을 정의한다.
import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'layout_tokens.dart';
import 'radius_tokens.dart';
import 'theme_preset_data.dart';

/// Dark Glass 프리셋: 딥 다크 배경 + 네온 글로우 보더 + 블러 효과
/// 항상 다크 테마이므로 라이트/다크 값이 동일하다
ThemePresetData buildDarkGlass() {
  // 공통 배경 그라디언트 (항상 다크, Apple 다크 기반)
  const bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1C1C1E), // Apple secondarySystemBackground 다크
      Color(0xFF0D0D0F), // Apple 니어 블랙
    ],
    stops: [0.0, 1.0],
  );

  // 공통 카드 데코레이션 (항상 다크)
  BoxDecoration cardDeco() => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.huge),
        border: Border.all(
          color: ColorTokens.main.withValues(alpha: 0.30),
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            // 기본 그림자
            color: ColorTokens.shadowBase.withValues(alpha: 0.25),
            blurRadius: EffectLayout.blurRadiusLg,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            // MAIN 색상 네온 글로우 효과
            color: ColorTokens.main.withValues(alpha: 0.08),
            blurRadius: EffectLayout.blurRadiusMd,
            spreadRadius: -2,
          ),
        ],
      );

  // 공통 강조 카드 데코레이션 (항상 다크)
  BoxDecoration elevatedDeco() => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.massive),
        border: Border.all(
          color: ColorTokens.main.withValues(alpha: 0.40),
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.30),
            blurRadius: EffectLayout.blurRadiusXxl,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: ColorTokens.main.withValues(alpha: 0.12),
            blurRadius: EffectLayout.blurRadiusLg,
            spreadRadius: -2,
          ),
        ],
      );

  // 공통 Bottom Nav 데코레이션 (항상 다크)
  BoxDecoration bottomNavDeco() => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.circle),
        border: Border.all(
          color: ColorTokens.main.withValues(alpha: 0.35),
          width: AppLayout.borderMedium,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.main.withValues(alpha: 0.15),
            blurRadius: EffectLayout.blurRadiusXxl,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.20),
            blurRadius: EffectLayout.blurRadiusXxl,
            offset: const Offset(0, 8),
          ),
        ],
      );

  return ThemePresetData(
    // 항상 다크: 라이트/다크 배경 동일
    backgroundGradient: bgGradient,
    darkBackgroundGradient: bgGradient,
    // 항상 다크: 라이트/다크 카드 동일
    cardDecoration: cardDeco,
    darkCardDecoration: cardDeco,
    // 항상 다크: 라이트/다크 강조 카드 동일
    elevatedCardDecoration: elevatedDeco,
    darkElevatedCardDecoration: elevatedDeco,
    // 보조 카드: 반투명 다크 + 약한 MAIN 보더
    subtleCardDecoration: ({double radius = AppRadius.xl}) => BoxDecoration(
      color: ColorTokens.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: ColorTokens.main.withValues(alpha: 0.15),
        width: AppLayout.borderThin,
      ),
    ),
    // 모달: Apple 다크 배경 + 글로우
    modalDecoration: () => BoxDecoration(
      color: const Color(0xFF1C1C1E).withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(AppRadius.massive),
      border: Border.all(
        color: ColorTokens.main.withValues(alpha: 0.50),
        width: AppLayout.borderMedium,
      ),
      boxShadow: [
        BoxShadow(
          color: ColorTokens.main.withValues(alpha: 0.20),
          blurRadius: EffectLayout.blurRadiusMax,
          spreadRadius: -4,
        ),
      ],
    ),
    // 항상 다크: 라이트/다크 Bottom Nav 동일
    bottomNavDecoration: bottomNavDeco,
    darkBottomNavDecoration: bottomNavDeco,
    // 블러 사용: 글라스 효과 유지
    useBlur: true,
    blurSigma: 16.0,
    // 텍스트: 항상 흰색 (다크 배경 기준)
    textPrimary: ColorTokens.white,
    textSecondary: ColorTokens.white,
    darkTextPrimary: ColorTokens.white,
    darkTextSecondary: ColorTokens.white,
  );
}
