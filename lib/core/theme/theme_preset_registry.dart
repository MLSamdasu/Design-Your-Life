// C0.5: 테마 프리셋 레지스트리
// 4가지 프리셋별 구체적인 ThemePresetData 인스턴스를 정적 팩토리로 제공한다.
// 새로운 프리셋 추가 시 이 파일에만 데이터를 추가하면 된다.
import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'radius_tokens.dart';
import 'theme_preset.dart';
import 'theme_preset_data.dart';

/// 테마 프리셋 레지스트리
/// enum과 ThemePresetData를 1:1로 매핑하는 정적 팩토리를 제공한다
abstract class ThemePresetRegistry {
  /// 프리셋 enum에 대응하는 ThemePresetData를 반환한다
  static ThemePresetData dataFor(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.glassmorphism:
        return _glassmorphism();
      case ThemePreset.minimal:
        return _minimal();
      case ThemePreset.retro:
        return _retro();
      case ThemePreset.neon:
        return _neon();
      case ThemePreset.clean:
        return _clean();
      case ThemePreset.soft:
        return _soft();
    }
  }

  // ─── Glassmorphism 프리셋 (기본, 현재 앱과 동일) ──────────────────────────
  /// 글래스모피즘 프리셋: 반투명 유리 카드 + 그라디언트 배경 + 블러 효과
  static ThemePresetData _glassmorphism() => ThemePresetData(
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorTokens.gradientStart,
            ColorTokens.gradientMid,
            ColorTokens.gradientEnd,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        darkBackgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorTokens.darkGradientStart,
            ColorTokens.darkGradientEnd,
          ],
          stops: [0.0, 1.0],
        ),
        // 라이트 모드: 기존 GlassDecoration.defaultCard()와 동일한 값
        cardDecoration: () => BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.1),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // 다크 모드: 기존 GlassDecoration.darkDefaultCard()와 동일한 값
        darkCardDecoration: () => BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.30),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // 강조 카드: 기존 GlassDecoration.elevatedCard()와 동일한 값
        elevatedCardDecoration: () => BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(AppRadius.massive),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.30),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        darkElevatedCardDecoration: () => BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.massive),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.35),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        // 보조 카드: 기존 GlassDecoration.subtleCard()와 동일한 값
        subtleCardDecoration: ({double radius = 12}) => BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(radius),
        ),
        // 모달: 기존 GlassDecoration.modal()과 동일한 값
        modalDecoration: () => BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.30),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.20),
              blurRadius: 48,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        // Bottom Nav: 기존 GlassDecoration.bottomNav()와 동일한 값
        bottomNavDecoration: () => BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.20),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.15),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        darkBottomNavDecoration: () => BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.25),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // 블러 설정: 기존 기본값 그대로
        useBlur: true,
        blurSigma: 20.0,
        // 텍스트: 흰색 (그라디언트 배경 위에서 가독성 최적)
        textPrimary: Colors.white,
        textSecondary: Colors.white,
        darkTextPrimary: Colors.white,
        darkTextSecondary: Colors.white,
      );

  // ─── Minimal 프리셋 ────────────────────────────────────────────────────────
  /// 미니멀 프리셋: 불투명 카드 + 미세 그림자 + 블러 없음
  static ThemePresetData _minimal() => ThemePresetData(
        // 라이트 배경: gray50 → white 단색 그라디언트
        backgroundGradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorTokens.gray50,
            Colors.white,
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
        // 라이트 카드: 불투명 흰색 + 미세 그림자 + gray200 보더
        cardDecoration: () => BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: ColorTokens.gray200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // 다크 카드: gray800 불투명 + 미세 그림자 + gray700 보더
        darkCardDecoration: () => BoxDecoration(
          color: ColorTokens.gray800,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: ColorTokens.gray700,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // 강조 카드: 더 선명한 그림자
        elevatedCardDecoration: () => BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(
            color: ColorTokens.gray200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        darkElevatedCardDecoration: () => BoxDecoration(
          color: ColorTokens.gray800,
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(
            color: ColorTokens.gray700,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // 보조 카드: 연한 gray100 배경
        subtleCardDecoration: ({double radius = 12}) => BoxDecoration(
          color: ColorTokens.gray100,
          borderRadius: BorderRadius.circular(radius),
        ),
        // 모달: 흰색 + 강한 그림자
        modalDecoration: () => BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: ColorTokens.gray200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.10),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        // Bottom Nav: 흰색 + 보더 + 그림자
        bottomNavDecoration: () => BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
            color: ColorTokens.gray200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        darkBottomNavDecoration: () => BoxDecoration(
          color: ColorTokens.gray800,
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
            color: ColorTokens.gray700,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(alpha: 0.25),
              blurRadius: 24,
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

  // ─── Retro 프리셋 ─────────────────────────────────────────────────────────
  /// 레트로 프리셋: 따뜻한 크림색 배경 + 두꺼운 보더 + 종이 질감 느낌
  static ThemePresetData _retro() => ThemePresetData(
        // 라이트 배경: 따뜻한 크림색 그라디언트
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF8F0),
            Color(0xFFF5EDE3),
          ],
          stops: [0.0, 1.0],
        ),
        // 다크 배경: 따뜻한 다크 브라운
        darkBackgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2318),
            Color(0xFF1E1A14),
          ],
          stops: [0.0, 1.0],
        ),
        // 라이트 카드: 크림 불투명 + 더블 보더(두께 2px) + soft shadow
        cardDecoration: () => BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(AppRadius.massive),
          border: Border.all(
            color: const Color(0xFFE8DFD0),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              // 외부 소프트 그림자로 종이 질감을 표현한다
              color: const Color(0xFF4A3F33).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              // 내부 하이라이트로 입체감을 추가한다
              color: Colors.white.withValues(alpha: 0.80),
              blurRadius: 0,
              offset: const Offset(0, 1),
              spreadRadius: -1,
            ),
          ],
        ),
        // 다크 카드: 따뜻한 다크 브라운 카드
        darkCardDecoration: () => BoxDecoration(
          color: const Color(0xFF332D24),
          borderRadius: BorderRadius.circular(AppRadius.massive),
          border: Border.all(
            color: const Color(0xFF4A4036),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E1A14).withValues(alpha: 0.40),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // 강조 카드: 더 두드러진 보더와 그림자
        elevatedCardDecoration: () => BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: const Color(0xFFD4C8B8),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A3F33).withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.80),
              blurRadius: 0,
              offset: const Offset(0, 1),
              spreadRadius: -1,
            ),
          ],
        ),
        darkElevatedCardDecoration: () => BoxDecoration(
          color: const Color(0xFF3D3528),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: const Color(0xFF56493A),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E1A14).withValues(alpha: 0.50),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // 보조 카드: 연한 크림 배경
        subtleCardDecoration: ({double radius = 12}) => BoxDecoration(
          color: const Color(0xFFFFF8F0),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: const Color(0xFFE8DFD0),
            width: 1,
          ),
        ),
        // 모달: 크림 배경 + 두꺼운 보더
        modalDecoration: () => BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(AppRadius.pillLg),
          border: Border.all(
            color: const Color(0xFFE8DFD0),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A3F33).withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        // Bottom Nav: 크림 배경 + 두꺼운 보더
        bottomNavDecoration: () => BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
            color: const Color(0xFFE8DFD0),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A3F33).withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        darkBottomNavDecoration: () => BoxDecoration(
          color: const Color(0xFF332D24),
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
            color: const Color(0xFF4A4036),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E1A14).withValues(alpha: 0.40),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // 블러 없음: 종이 질감 원칙 (투명 레이어 없음)
        useBlur: false,
        blurSigma: 0.0,
        // 텍스트: 따뜻한 브라운 계열
        textPrimary: const Color(0xFF4A3F33),
        textSecondary: const Color(0xFF8B7E6E),
        darkTextPrimary: const Color(0xFFF5EDE3),
        darkTextSecondary: const Color(0xFFA89A88),
      );

  // ─── Neon 프리셋 ──────────────────────────────────────────────────────────
  /// 네온 프리셋: 어두운 배경 + 네온 글로우 보더 + 약한 블러
  static ThemePresetData _neon() => ThemePresetData(
        // 라이트 배경: 네온은 항상 다크톤 (딥 네이비-퍼플)
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F0B1A),
            Color(0xFF1A1130),
          ],
          stops: [0.0, 1.0],
        ),
        // 다크 배경: 더 깊은 검정 계열
        darkBackgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF080510),
            Color(0xFF0F0A1E),
          ],
          stops: [0.0, 1.0],
        ),
        // 라이트 카드: 반투명 다크 + 네온 글로우 보더
        cardDecoration: () => BoxDecoration(
          color: const Color(0xFF1C1530).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            // MAIN 컬러로 네온 글로우 보더를 표현한다
            color: ColorTokens.main.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              // 네온 글로우 효과: MAIN 컬러로 발광하는 느낌
              color: ColorTokens.main.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: -2,
            ),
          ],
        ),
        // 다크 카드: 더 어두운 반투명 + 동일한 네온 글로우
        darkCardDecoration: () => BoxDecoration(
          color: const Color(0xFF120F22).withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: ColorTokens.main.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.main.withValues(alpha: 0.20),
              blurRadius: 20,
              spreadRadius: -2,
            ),
          ],
        ),
        // 강조 카드: 더 강한 네온 글로우
        elevatedCardDecoration: () => BoxDecoration(
          color: const Color(0xFF1C1530).withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(
            color: ColorTokens.main.withValues(alpha: 0.55),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.main.withValues(alpha: 0.25),
              blurRadius: 32,
              spreadRadius: -2,
            ),
          ],
        ),
        darkElevatedCardDecoration: () => BoxDecoration(
          color: const Color(0xFF120F22).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(
            color: ColorTokens.main.withValues(alpha: 0.65),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.main.withValues(alpha: 0.30),
              blurRadius: 32,
              spreadRadius: -2,
            ),
          ],
        ),
        // 보조 카드: 미니멀 다크 + 약한 네온 보더
        subtleCardDecoration: ({double radius = 12}) => BoxDecoration(
          color: const Color(0xFF1C1530).withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: ColorTokens.main.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        // 모달: 강한 네온 글로우 + 진한 배경
        modalDecoration: () => BoxDecoration(
          color: const Color(0xFF1C1530).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppRadius.massive),
          border: Border.all(
            color: ColorTokens.main.withValues(alpha: 0.60),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.main.withValues(alpha: 0.30),
              blurRadius: 48,
              spreadRadius: -4,
            ),
          ],
        ),
        // Bottom Nav: 네온 글로우 캡슐
        bottomNavDecoration: () => BoxDecoration(
          color: const Color(0xFF1C1530).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
            color: ColorTokens.main.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.main.withValues(alpha: 0.20),
              blurRadius: 24,
              spreadRadius: -2,
            ),
          ],
        ),
        darkBottomNavDecoration: () => BoxDecoration(
          color: const Color(0xFF120F22).withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
            color: ColorTokens.main.withValues(alpha: 0.55),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.main.withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: -2,
            ),
          ],
        ),
        // 블러 사용: 약한 블러로 깊이감 표현
        useBlur: true,
        blurSigma: 12.0,
        // 텍스트: 흰색 + 네온 악센트 (어두운 배경 기준)
        textPrimary: Colors.white,
        textSecondary: Colors.white,
        darkTextPrimary: Colors.white,
        darkTextSecondary: Colors.white,
      );

  // ─── Clean 프리셋 ──────────────────────────────────────────────────────────
  /// 깔끔한 프리셋: 화이트 스페이스 중심 + 얇은 보더 + 클린 블루 악센트
  /// 전문적이고 정돈된 느낌의 미니멀리스트 디자인
  static ThemePresetData _clean() => ThemePresetData(
        // 라이트 배경: 매우 밝은 그레이 → 순백색 그라디언트
        backgroundGradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFFFFFFF),
          ],
          stops: [0.0, 1.0],
        ),
        // 다크 배경: 딥 네이비 그라디언트
        darkBackgroundGradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16162A),
          ],
          stops: [0.0, 1.0],
        ),
        // 라이트 카드: 순백 배경 + 얇은 보더 + 미세 그림자
        cardDecoration: () => BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: const Color(0xFFE8ECF0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // 다크 카드: 딥 네이비 배경 + 보더
        darkCardDecoration: () => BoxDecoration(
          color: const Color(0xFF22223A),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: const Color(0xFF2E2E4A),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A0A15).withValues(alpha: 0.30),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // 강조 카드: 약간 더 강한 그림자
        elevatedCardDecoration: () => BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xlLg),
          border: Border.all(
            color: const Color(0xFFE0E5EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        darkElevatedCardDecoration: () => BoxDecoration(
          color: const Color(0xFF282845),
          borderRadius: BorderRadius.circular(AppRadius.xlLg),
          border: Border.all(
            color: const Color(0xFF363654),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A0A15).withValues(alpha: 0.40),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // 보조 카드: 매우 연한 그레이 배경
        subtleCardDecoration: ({double radius = 12}) => BoxDecoration(
          color: const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: const Color(0xFFEBEEF2),
            width: 1,
          ),
        ),
        // 모달: 순백 배경 + 선명한 그림자
        modalDecoration: () => BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: const Color(0xFFE0E5EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.10),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        // Bottom Nav: 순백 캡슐 + 얇은 보더
        bottomNavDecoration: () => BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
            color: const Color(0xFFE0E5EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        darkBottomNavDecoration: () => BoxDecoration(
          color: const Color(0xFF22223A),
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
            color: const Color(0xFF2E2E4A),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A0A15).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // 블러 없음: 깔끔한 플랫 디자인
        useBlur: false,
        blurSigma: 0.0,
        // 텍스트: 어두운 네이비 (밝은 배경 위에서 가독성 최적)
        textPrimary: const Color(0xFF1A1A2E),
        textSecondary: const Color(0xFF6B7280),
        darkTextPrimary: const Color(0xFFF0F1F5),
        darkTextSecondary: const Color(0xFF9CA3AF),
      );

  // ─── Soft 프리셋 ───────────────────────────────────────────────────────────
  /// 부드러운 프리셋: 따뜻한 파스텔 크림 배경 + 소프트 코랄 악센트 + 둥근 모서리
  /// 아늑하고 부드러운 느낌의 디자인
  static ThemePresetData _soft() => ThemePresetData(
        // 라이트 배경: 따뜻한 크림/베이지 그라디언트
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF8F0),
            Color(0xFFFAF5EF),
          ],
          stops: [0.0, 1.0],
        ),
        // 다크 배경: 따뜻한 다크 브라운
        darkBackgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C2420),
            Color(0xFF231E1A),
          ],
          stops: [0.0, 1.0],
        ),
        // 라이트 카드: 따뜻한 아이보리 + 소프트 그림자 + 둥근 모서리
        cardDecoration: () => BoxDecoration(
          color: const Color(0xFFFFFDF9),
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(
            color: const Color(0xFFF0E6D8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              // 따뜻한 톤의 소프트 그림자
              color: const Color(0xFFD4A98C).withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // 다크 카드: 따뜻한 다크 브라운
        darkCardDecoration: () => BoxDecoration(
          color: const Color(0xFF362F28),
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(
            color: const Color(0xFF4A4038),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1510).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // 강조 카드: 더 뚜렷한 소프트 그림자
        elevatedCardDecoration: () => BoxDecoration(
          color: const Color(0xFFFFFDF9),
          borderRadius: BorderRadius.circular(AppRadius.massive),
          border: Border.all(
            color: const Color(0xFFEADDD0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4A98C).withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        darkElevatedCardDecoration: () => BoxDecoration(
          color: const Color(0xFF3D3530),
          borderRadius: BorderRadius.circular(AppRadius.massive),
          border: Border.all(
            color: const Color(0xFF564A40),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1510).withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // 보조 카드: 연한 피치 배경
        subtleCardDecoration: ({double radius = 12}) => BoxDecoration(
          color: const Color(0xFFFFF5ED),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: const Color(0xFFF0E6D8),
            width: 1,
          ),
        ),
        // 모달: 아이보리 배경 + 소프트 그림자
        modalDecoration: () => BoxDecoration(
          color: const Color(0xFFFFFDF9),
          borderRadius: BorderRadius.circular(AppRadius.massive),
          border: Border.all(
            color: const Color(0xFFEADDD0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4A98C).withValues(alpha: 0.18),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        // Bottom Nav: 아이보리 캡슐 + 소프트 보더
        bottomNavDecoration: () => BoxDecoration(
          color: const Color(0xFFFFFDF9),
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
            color: const Color(0xFFF0E6D8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4A98C).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        darkBottomNavDecoration: () => BoxDecoration(
          color: const Color(0xFF362F28),
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
            color: const Color(0xFF4A4038),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1510).withValues(alpha: 0.40),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // 블러 없음: 부드러운 플랫 디자인
        useBlur: false,
        blurSigma: 0.0,
        // 텍스트: 따뜻한 다크 브라운 (밝은 크림 배경 위에서 가독성 최적)
        textPrimary: const Color(0xFF3D2C2E),
        textSecondary: const Color(0xFF8B7A72),
        darkTextPrimary: const Color(0xFFF5EDE3),
        darkTextSecondary: const Color(0xFFA89888),
      );
}
