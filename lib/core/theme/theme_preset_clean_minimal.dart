// C0.5: Clean Minimal 프리셋 데이터
// 불투명 카드 + 미세 그림자 + 블러 없음의 플랫 디자인 스타일을 정의한다.
import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'layout_tokens.dart';
import 'radius_tokens.dart';
import 'theme_preset_data.dart';

/// Clean Minimal 프리셋: 밝은 단색 배경 + 불투명 카드 + 블러 없음
ThemePresetData buildCleanMinimal() => ThemePresetData(
      // 라이트 배경: Apple 쿨 화이트 → 순백색
      backgroundGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF8F8FA), // Apple 쿨 화이트
          ColorTokens.white,
        ],
        stops: [0.0, 1.0],
      ),
      // 다크 배경: gray900 → Apple 딥 다크
      darkBackgroundGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ColorTokens.gray900,
          const Color(0xFF141416), // Apple 딥 다크
        ],
        stops: const [0.0, 1.0],
      ),
      // 라이트 카드: 불투명 흰색 + gray200 보더 + 미세 그림자
      cardDecoration: () => BoxDecoration(
        color: ColorTokens.white,
        borderRadius: BorderRadius.circular(AppRadius.huge),
        border: Border.all(
          color: ColorTokens.gray200,
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.04),
            blurRadius: EffectLayout.blurRadiusXs,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // 다크 카드: gray800 불투명 + gray700 보더
      darkCardDecoration: () => BoxDecoration(
        color: ColorTokens.gray800,
        borderRadius: BorderRadius.circular(AppRadius.huge),
        border: Border.all(
          color: ColorTokens.gray700,
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.20),
            blurRadius: EffectLayout.blurRadiusSm,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // 강조 카드: 더 선명한 그림자
      elevatedCardDecoration: () => BoxDecoration(
        color: ColorTokens.white,
        borderRadius: BorderRadius.circular(AppRadius.massive),
        border: Border.all(
          color: ColorTokens.gray200,
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.08),
            blurRadius: EffectLayout.blurRadiusLg,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // 다크 강조 카드
      darkElevatedCardDecoration: () => BoxDecoration(
        color: ColorTokens.gray800,
        borderRadius: BorderRadius.circular(AppRadius.massive),
        border: Border.all(
          color: ColorTokens.gray700,
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.30),
            blurRadius: EffectLayout.blurRadiusLg,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // 보조 카드: 연한 gray100 배경
      subtleCardDecoration: ({double radius = AppRadius.xl}) => BoxDecoration(
        color: ColorTokens.gray100,
        borderRadius: BorderRadius.circular(radius),
      ),
      // 모달: 흰색 + 강한 그림자
      modalDecoration: () => BoxDecoration(
        color: ColorTokens.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: ColorTokens.gray200,
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.10),
            blurRadius: EffectLayout.blurRadiusXxxl,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      // Bottom Nav: 반투명 캡슐 (밝은 배경 테마)
      bottomNavDecoration: () => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.circle),
        border: Border.all(
          color: ColorTokens.white.withValues(alpha: 0.35),
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.12),
            blurRadius: EffectLayout.blurRadiusXxl,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // 다크 Bottom Nav
      darkBottomNavDecoration: () => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.circle),
        border: Border.all(
          color: ColorTokens.white.withValues(alpha: 0.22),
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.30),
            blurRadius: EffectLayout.blurRadiusXxl,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // 블러 없음: 플랫 디자인 원칙
      useBlur: false,
      blurSigma: 0.0,
      // 텍스트: 어두운 색상 (밝은 배경 위에서 가독성 최적)
      textPrimary: ColorTokens.gray800,
      textSecondary: ColorTokens.gray500,
      darkTextPrimary: ColorTokens.gray50,
      darkTextSecondary: ColorTokens.gray400,
    );
