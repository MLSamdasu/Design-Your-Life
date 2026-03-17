// C0.5: 테마 프리셋 레지스트리
// 3가지 프리셋별 구체적인 ThemePresetData 인스턴스를 정적 팩토리로 제공한다.
// 새로운 프리셋 추가 시 이 파일에만 데이터를 추가하면 된다.
import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'layout_tokens.dart';
import 'radius_tokens.dart';
import 'theme_preset.dart';
import 'theme_preset_data.dart';

/// 테마 프리셋 레지스트리
/// enum과 ThemePresetData를 1:1로 매핑하는 정적 팩토리를 제공한다
abstract class ThemePresetRegistry {
  /// 프리셋 enum에 대응하는 ThemePresetData를 반환한다
  static ThemePresetData dataFor(ThemePreset preset) {
    return switch (preset) {
      ThemePreset.refinedGlass => _refinedGlass(),
      ThemePreset.cleanMinimal => _cleanMinimal(),
      ThemePreset.darkGlass => _darkGlass(),
    };
  }

  // ─── Refined Glass 프리셋 (기본, 밝은 배경 + 미묘한 글라스 효과) ─────────
  /// Refined Glass 프리셋: 밝은 라벤더 배경 + 반투명 카드 + 블러 효과
  static ThemePresetData _refinedGlass() => ThemePresetData(
        // 라이트 배경: 밝은 라벤더 → 서브 → 핑크 라벤더 3색 그라디언트
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5F3FF), // refinedGradientStart
            Color(0xFFEDE9FE), // refinedGradientMid (SUB와 동일)
            Color(0xFFFDF4FF), // refinedGradientEnd
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        // 다크 배경: 기존 다크 그라디언트 유지
        darkBackgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorTokens.darkGradientStart,
            ColorTokens.darkGradientEnd,
          ],
          stops: [0.0, 1.0],
        ),
        // 라이트 카드: 반투명 white alpha 0.70 + 블러 효과
        cardDecoration: () => BoxDecoration(
          color: ColorTokens.white.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(
            color: ColorTokens.white.withValues(alpha: 0.50),
            width: AppLayout.borderThin,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.06),
              blurRadius: AppLayout.blurRadiusMd,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // 다크 카드: 반투명 다크 글라스
        darkCardDecoration: () => BoxDecoration(
          color: ColorTokens.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(
            color: ColorTokens.white.withValues(alpha: 0.22),
            width: AppLayout.borderThin,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.30),
              blurRadius: AppLayout.blurRadiusXxl,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // 강조 카드: 더 높은 알파 + 더 선명한 그림자
        elevatedCardDecoration: () => BoxDecoration(
          color: ColorTokens.white.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(AppRadius.massive),
          border: Border.all(
            color: ColorTokens.white.withValues(alpha: 0.60),
            width: AppLayout.borderThin,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.08),
              blurRadius: AppLayout.blurRadiusXxl,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // 다크 강조 카드
        darkElevatedCardDecoration: () => BoxDecoration(
          color: ColorTokens.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.massive),
          border: Border.all(
            color: ColorTokens.white.withValues(alpha: 0.28),
            width: AppLayout.borderThin,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.35),
              blurRadius: AppLayout.blurRadiusXxxl,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        // 보조 카드: 반투명 white alpha 0.50, 보더 없음
        subtleCardDecoration: ({double radius = AppRadius.xl}) => BoxDecoration(
          color: ColorTokens.white.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(radius),
        ),
        // 모달: 높은 알파로 선명하게 표시
        modalDecoration: () => BoxDecoration(
          color: ColorTokens.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: ColorTokens.white.withValues(alpha: 0.60),
            width: AppLayout.borderThin,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.12),
              blurRadius: AppLayout.blurRadiusMax,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        // Bottom Nav: 반투명 캡슐
        bottomNavDecoration: () => BoxDecoration(
          color: ColorTokens.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
            color: ColorTokens.white.withValues(alpha: 0.45),
            width: AppLayout.borderThin,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.08),
              blurRadius: AppLayout.blurRadiusXxl,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // 다크 Bottom Nav
        darkBottomNavDecoration: () => BoxDecoration(
          color: ColorTokens.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
            color: ColorTokens.white.withValues(alpha: 0.22),
            width: AppLayout.borderThin,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.25),
              blurRadius: AppLayout.blurRadiusXxl,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // 블러: 미묘한 글라스 효과
        useBlur: true,
        blurSigma: 12.0,
        // 텍스트: 밝은 배경 위에서 가독성 최적 (어두운 텍스트)
        textPrimary: ColorTokens.gray800,
        textSecondary: ColorTokens.gray500,
        // 다크 모드: 흰색 텍스트
        darkTextPrimary: ColorTokens.white,
        darkTextSecondary: ColorTokens.white,
      );

  // ─── Clean Minimal 프리셋 (밝은 단색 배경 + 블러 없음) ────────────────────
  /// Clean Minimal 프리셋: 불투명 카드 + 미세 그림자 + 블러 없음
  static ThemePresetData _cleanMinimal() => ThemePresetData(
        // 라이트 배경: 매우 밝은 그레이 → 순백색
        backgroundGradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF9FAFB),
            ColorTokens.white,
          ],
          stops: [0.0, 1.0],
        ),
        // 다크 배경: gray900 → 딥 다크
        darkBackgroundGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorTokens.gray900,
            const Color(0xFF151419),
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
              blurRadius: AppLayout.blurRadiusXs,
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
              blurRadius: AppLayout.blurRadiusSm,
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
              blurRadius: AppLayout.blurRadiusLg,
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
              blurRadius: AppLayout.blurRadiusLg,
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
              blurRadius: AppLayout.blurRadiusXxxl,
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
              blurRadius: AppLayout.blurRadiusXxl,
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
              blurRadius: AppLayout.blurRadiusXxl,
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

  // ─── Dark Glass 프리셋 (어두운 배경 + 글라스 효과 유지) ──────────────────
  /// Dark Glass 프리셋: 딥 다크 배경 + 네온 글로우 보더 + 블러 효과
  /// 항상 다크 테마이므로 라이트/다크 값이 동일하다
  static ThemePresetData _darkGlass() {
    // 공통 배경 그라디언트 (항상 다크)
    const bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1A1130),
        Color(0xFF0F0B1A),
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
              blurRadius: AppLayout.blurRadiusLg,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              // MAIN 색상 네온 글로우 효과
              color: ColorTokens.main.withValues(alpha: 0.08),
              blurRadius: AppLayout.blurRadiusMd,
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
              blurRadius: AppLayout.blurRadiusXxl,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: ColorTokens.main.withValues(alpha: 0.12),
              blurRadius: AppLayout.blurRadiusLg,
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
              blurRadius: AppLayout.blurRadiusXxl,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.20),
              blurRadius: AppLayout.blurRadiusXxl,
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
      // 모달: 강한 글로우 + 진한 배경
      modalDecoration: () => BoxDecoration(
        color: const Color(0xFF1A1130).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadius.massive),
        border: Border.all(
          color: ColorTokens.main.withValues(alpha: 0.50),
          width: AppLayout.borderMedium,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.main.withValues(alpha: 0.20),
            blurRadius: AppLayout.blurRadiusMax,
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
}
