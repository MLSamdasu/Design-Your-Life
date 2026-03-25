// C0.5: Refined Glass 프리셋 데이터
// 딥 퍼플→바이올렛→마젠타→틸 리치 그라디언트 + 프로스트 글라스 카드 스타일을 정의한다.
import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'layout_tokens.dart';
import 'radius_tokens.dart';
import 'theme_preset_data.dart';

/// Refined Glass 프리셋: 리치 그라디언트 배경 + 프로스트 글라스 카드
/// Clean Minimal과의 차별화: 화려한 컬러 그라디언트 배경, 낮은 알파 카드, 강한 블러
/// Dark Glass와의 차별화: 컬러풀 그라디언트 (vs 거의 단색 다크), 네온 글로우 없음
ThemePresetData buildRefinedGlass() {
  // 라이트/다크 공통: 리치 그라디언트 배경 (항상 어두운 컬러풀 그라디언트)
  const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1145), // 딥 인디고 퍼플
      Color(0xFF4A2B8A), // 리치 바이올렛
      Color(0xFF6B2FA0), // 마젠타 바이올렛
      Color(0xFF1A5B6B), // 딥 틸
    ],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  // 프로스트 글라스 카드: 배경 그라디언트가 비쳐 보이는 반투명 카드
  BoxDecoration cardDeco() => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.huge),
        border: Border.all(
          color: ColorTokens.white.withValues(alpha: 0.25),
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.20),
            blurRadius: EffectLayout.blurRadiusLg,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // 강조 카드: 약간 더 불투명
  BoxDecoration elevatedDeco() => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(AppRadius.massive),
        border: Border.all(
          color: ColorTokens.white.withValues(alpha: 0.32),
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.25),
            blurRadius: EffectLayout.blurRadiusXxl,
            offset: const Offset(0, 8),
          ),
        ],
      );

  // Bottom Nav: 프로스트 캡슐
  BoxDecoration bottomNavDeco() => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.circle),
        border: Border.all(
          color: ColorTokens.white.withValues(alpha: 0.25),
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.20),
            blurRadius: EffectLayout.blurRadiusXxl,
            offset: const Offset(0, 8),
          ),
        ],
      );

  return ThemePresetData(
    // 항상 리치 그라디언트: 라이트/다크 배경 동일 (항상 어두운 컬러풀 배경)
    backgroundGradient: gradient,
    darkBackgroundGradient: gradient,
    // 프로스트 글라스 카드 (라이트/다크 동일)
    cardDecoration: cardDeco,
    darkCardDecoration: cardDeco,
    // 강조 카드 (라이트/다크 동일)
    elevatedCardDecoration: elevatedDeco,
    darkElevatedCardDecoration: elevatedDeco,
    // 보조 카드: 극미세 반투명
    subtleCardDecoration: ({double radius = AppRadius.xl}) => BoxDecoration(
      color: ColorTokens.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(radius),
    ),
    // 모달: 프로스트 효과 + 높은 불투명도 (가독성 보장)
    modalDecoration: () => BoxDecoration(
      color: const Color(0xFF1E1145).withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(
        color: ColorTokens.white.withValues(alpha: 0.20),
        width: AppLayout.borderThin,
      ),
      boxShadow: [
        BoxShadow(
          color: ColorTokens.shadowBase.withValues(alpha: 0.30),
          blurRadius: EffectLayout.blurRadiusMax,
          offset: const Offset(0, 16),
        ),
      ],
    ),
    // Bottom Nav (라이트/다크 동일)
    bottomNavDecoration: bottomNavDeco,
    darkBottomNavDecoration: bottomNavDeco,
    // 블러: 20.0으로 강한 글라스 효과
    useBlur: true,
    blurSigma: 20.0,
    // 텍스트: 항상 흰색 (어두운 그라디언트 배경 기준)
    textPrimary: ColorTokens.white,
    textSecondary: ColorTokens.white,
    darkTextPrimary: ColorTokens.white,
    darkTextSecondary: ColorTokens.white,
  );
}
