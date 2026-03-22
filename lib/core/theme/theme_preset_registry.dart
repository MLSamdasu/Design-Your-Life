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

  // ─── Refined Glass 프리셋 (기본, 리치 그라디언트 글라스모피즘) ─────────────
  /// Refined Glass 프리셋: 딥 퍼플→바이올렛→마젠타→틸 리치 그라디언트 + 프로스트 글라스
  /// Clean Minimal과의 차별화: 화려한 컬러 그라디언트 배경, 낮은 알파 카드, 강한 블러
  /// Dark Glass와의 차별화: 컬러풀 그라디언트 (vs 거의 단색 다크), 네온 글로우 없음
  static ThemePresetData _refinedGlass() {
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
              blurRadius: AppLayout.blurRadiusLg,
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
              blurRadius: AppLayout.blurRadiusXxl,
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
              blurRadius: AppLayout.blurRadiusXxl,
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
            blurRadius: AppLayout.blurRadiusMax,
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

  // ─── Clean Minimal 프리셋 (밝은 단색 배경 + 블러 없음) ────────────────────
  /// Clean Minimal 프리셋: 불투명 카드 + 미세 그림자 + 블러 없음
  static ThemePresetData _cleanMinimal() => ThemePresetData(
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
