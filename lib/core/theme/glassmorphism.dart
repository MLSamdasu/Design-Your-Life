// C0.5: 글래스모피즘(유리 효과) 데코레이션 유틸
// BackdropFilter + blur + 반투명 배경을 조합한 공용 BoxDecoration을 제공한다.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'color_tokens.dart';
import 'layout_tokens.dart';
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
  // ─── 그림자 상수 ──────────────────────────────────────────────────────
  /// 기본 그림자 블러 반지름
  static const double _shadowBlurDefault = 32;

  /// 강조 그림자 블러 반지름
  static const double _shadowBlurElevated = 40;

  /// 모달 그림자 블러 반지름
  static const double _shadowBlurModal = 48;

  /// 기본 그림자 오프셋
  static const Offset _shadowOffsetDefault = Offset(0, 8);

  /// 강조 그림자 오프셋
  static const Offset _shadowOffsetElevated = Offset(0, 12);

  /// 모달 그림자 오프셋
  static const Offset _shadowOffsetModal = Offset(0, 16);

  // ─── 기본 유리 카드 ───────────────────────────────────────────────────────
  /// 기본 유리 카드 데코레이션 (선명도 향상)
  /// 배경: rgba(255,255,255,0.22), Blur: 20px, Border Radius: 20px
  static BoxDecoration defaultCard() => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: ColorTokens.white.withValues(alpha: 0.35),
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.1),
            blurRadius: _shadowBlurDefault,
            offset: _shadowOffsetDefault,
          ),
        ],
      );

  // ─── 강조 유리 카드 ───────────────────────────────────────────────────────
  /// 강조 유리 카드 데코레이션 (정보 카드, 모달, 강조 컨텐츠, 선명도 향상)
  /// 배경: rgba(255,255,255,0.28), Blur: 24px, Border Radius: 24px
  static BoxDecoration elevatedCard() => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadius.dialog),
        border: Border.all(
          color: ColorTokens.white.withValues(alpha: 0.40),
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.15),
            blurRadius: _shadowBlurElevated,
            offset: _shadowOffsetElevated,
          ),
        ],
      );

  // ─── 보조 유리 카드 ───────────────────────────────────────────────────────
  /// 보조 유리 카드 데코레이션 (내부 섹션, 습관 필, D-day 카드, 선명도 향상)
  /// 배경: rgba(255,255,255,0.18), Border 없음, 그림자 없음
  static BoxDecoration subtleCard({double radius = AppRadius.xl}) => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(radius),
      );

  // ─── 다크 모드 유리 카드 ─────────────────────────────────────────────────
  /// 다크 모드 기본 유리 카드 데코레이션 (선명도 향상)
  /// 배경: rgba(255,255,255,0.14), Blur: 24px (약간 강화)
  static BoxDecoration darkDefaultCard() => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: ColorTokens.white.withValues(alpha: 0.22),
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.30),
            blurRadius: _shadowBlurDefault,
            offset: _shadowOffsetDefault,
          ),
        ],
      );

  // ─── Bottom Nav 유리 ──────────────────────────────────────────────────────
  /// 플로팅 캡슐 하단 네비게이션 데코레이션 (선명도 향상)
  /// 배경: rgba(255,255,255,0.25), Blur: 30px, Border Radius: 100px (완전한 캡슐)
  static BoxDecoration bottomNav() => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.circle),
        border: Border.all(
          color: ColorTokens.white.withValues(alpha: 0.30),
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.15),
            blurRadius: _shadowBlurDefault,
            offset: _shadowOffsetDefault,
          ),
        ],
      );

  /// 다크 모드 Bottom Nav 데코레이션 (선명도 향상)
  static BoxDecoration darkBottomNav() => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.circle),
        border: Border.all(
          color: ColorTokens.white.withValues(alpha: 0.22),
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.25),
            blurRadius: _shadowBlurDefault,
            offset: _shadowOffsetDefault,
          ),
        ],
      );

  // ─── 모달/다이얼로그 유리 ────────────────────────────────────────────────
  /// 모달/다이얼로그 유리 데코레이션 (선명도 향상)
  /// BackdropFilter blur와 함께 사용
  /// 배경: rgba(255,255,255,0.55), Blur: 24px, Border Radius: 28px
  static BoxDecoration modal() => BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.bottomSheet),
        border: Border.all(
          color: ColorTokens.white.withValues(alpha: 0.40),
          width: AppLayout.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase.withValues(alpha: 0.20),
            blurRadius: _shadowBlurModal,
            offset: _shadowOffsetModal,
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
