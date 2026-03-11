// C0.5: 글래스모피즘(유리 효과) 데코레이션 유틸
// BackdropFilter + blur + 반투명 배경을 조합한 공용 BoxDecoration을 제공한다.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'color_tokens.dart';
import 'radius_tokens.dart';

/// 글래스모피즘 카드 변형 유형
enum GlassVariant {
  /// 기본 유리 카드 (대시보드 카드 등)
  defaultCard,

  /// 강조 유리 카드 (정보 카드, 모달)
  elevated,

  /// 보조 유리 카드 (내부 섹션, 습관 필, D-day 카드)
  subtle,

  /// 다크 모드 기본 카드
  darkDefault,
}

/// 글래스모피즘 데코레이션 팩토리
/// design-system.md의 Glass Card 스펙을 Flutter BoxDecoration으로 구현한다
/// 반드시 ClipRRect + BackdropFilter 조합과 함께 사용한다
abstract class GlassDecoration {
  // ─── 기본 유리 카드 ───────────────────────────────────────────────────────
  /// 기본 유리 카드 데코레이션
  /// 배경: rgba(255,255,255,0.15), Blur: 20px, Border Radius: 20px
  static BoxDecoration defaultCard() => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.card),
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
      );

  // ─── 강조 유리 카드 ───────────────────────────────────────────────────────
  /// 강조 유리 카드 데코레이션 (정보 카드, 모달, 강조 컨텐츠)
  /// 배경: rgba(255,255,255,0.20), Blur: 24px, Border Radius: 24px
  static BoxDecoration elevatedCard() => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppRadius.dialog),
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
      );

  // ─── 보조 유리 카드 ───────────────────────────────────────────────────────
  /// 보조 유리 카드 데코레이션 (내부 섹션, 습관 필, D-day 카드)
  /// 배경: rgba(255,255,255,0.12), Border 없음, 그림자 없음
  static BoxDecoration subtleCard({double radius = 12}) => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      );

  // ─── 다크 모드 유리 카드 ─────────────────────────────────────────────────
  /// 다크 모드 기본 유리 카드 데코레이션
  /// 배경: rgba(255,255,255,0.08), Blur: 24px (약간 강화)
  static BoxDecoration darkDefaultCard() => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
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
      );

  // ─── Bottom Nav 유리 ──────────────────────────────────────────────────────
  /// 플로팅 캡슐 하단 네비게이션 데코레이션
  /// 배경: rgba(255,255,255,0.18), Blur: 30px, Border Radius: 100px (완전한 캡슐)
  static BoxDecoration bottomNav() => BoxDecoration(
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
      );

  /// 다크 모드 Bottom Nav 데코레이션
  static BoxDecoration darkBottomNav() => BoxDecoration(
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
      );

  // ─── 모달/다이얼로그 유리 ────────────────────────────────────────────────
  /// 모달/다이얼로그 유리 데코레이션
  /// 배경: rgba(255,255,255,0.20), Blur: 24px, Border Radius: 28px
  static BoxDecoration modal() => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppRadius.bottomSheet),
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
      );

  // ─── 블러 필터 값 ────────────────────────────────────────────────────────
  /// 기본 Glass 블러 강도 (sigmaX/sigmaY)
  static const double defaultBlurSigma = 20.0;

  /// 강조 Glass 블러 강도
  static const double elevatedBlurSigma = 24.0;

  /// Bottom Nav 블러 강도
  static const double navBlurSigma = 30.0;

  /// 보조 Glass 블러 강도
  static const double subtleBlurSigma = 16.0;

  // ─── ImageFilter 헬퍼 ────────────────────────────────────────────────────
  /// 기본 블러 필터
  static ImageFilter get defaultBlur =>
      ImageFilter.blur(sigmaX: defaultBlurSigma, sigmaY: defaultBlurSigma);

  /// 강조 블러 필터
  static ImageFilter get elevatedBlur =>
      ImageFilter.blur(sigmaX: elevatedBlurSigma, sigmaY: elevatedBlurSigma);

  /// Bottom Nav 블러 필터
  static ImageFilter get navBlur =>
      ImageFilter.blur(sigmaX: navBlurSigma, sigmaY: navBlurSigma);
}
