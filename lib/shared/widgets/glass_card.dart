// 공용 위젯: GlassCard (테마 프리셋 인식 카드)
// 선택된 테마 프리셋에 따라 블러 유무, 데코레이션, 색상을 동적으로 적용한다.
// glassmorphism: ClipRRect + BackdropFilter + 반투명 배경
// minimal/retro: BackdropFilter 생략, 불투명 컨테이너만 사용 (성능 향상)
// neon: ClipRRect + BackdropFilter + 네온 글로우 보더
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/global_providers.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_preset_data.dart';

/// 글래스 카드 변형 유형
/// design-system.md의 3가지 Glass Card 스펙을 따른다
enum GlassCardVariant {
  /// 기본 카드: 대시보드 카드 등 일반 사용 (opacity 0.15, blur 20px)
  defaultCard,

  /// 강조 카드: 모달, 정보 강조 카드 (opacity 0.20, blur 24px)
  elevated,

  /// 보조 카드: 습관 필, D-day 내부 카드 (opacity 0.12, blur 16px)
  subtle,
}

/// 테마 프리셋 인식 카드 공용 위젯 (ConsumerWidget)
/// themePresetDataProvider를 구독하여 프리셋별 데코레이션/블러를 자동으로 적용한다.
/// 화면에 동시에 BackdropFilter가 있는 카드는 최대 5개까지만 사용한다 (성능 예산 준수)
class GlassCard extends ConsumerWidget {
  /// 카드 내부 자식 위젯
  final Widget child;

  /// 내부 패딩 (기본값: variant별 스펙에서 자동 결정)
  final EdgeInsetsGeometry? padding;

  /// 외부 마진
  final EdgeInsetsGeometry? margin;

  /// 외곽 모서리 반지름 (기본값: variant별 스펙)
  final double? borderRadius;

  /// 카드 변형 유형
  final GlassCardVariant variant;

  /// 카드 너비 (null이면 가로 확장)
  final double? width;

  /// 카드 높이 (null이면 자식 크기에 맞춤)
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.variant = GlassCardVariant.defaultCard,
    this.width,
    this.height,
  });

  /// variant별 블러 강도 결정 (프리셋 blurSigma로 오버라이드된다)
  double _blurSigma(ThemePresetData presetData) {
    // 프리셋이 블러를 비활성화했으면 0을 반환한다
    if (!presetData.useBlur) return 0;
    switch (variant) {
      case GlassCardVariant.defaultCard:
        // 프리셋 blurSigma를 기본으로 사용하고 variant별 배율을 적용한다
        return presetData.blurSigma;
      case GlassCardVariant.elevated:
        // 강조 카드는 기본보다 약간 강한 블러를 적용한다
        return presetData.blurSigma + 4.0;
      case GlassCardVariant.subtle:
        // 보조 카드는 기본보다 약한 블러를 적용한다
        return (presetData.blurSigma - 4.0).clamp(0.0, presetData.blurSigma);
    }
  }

  /// variant별 border radius 결정
  double get _borderRadius {
    if (borderRadius != null) return borderRadius!;
    switch (variant) {
      case GlassCardVariant.defaultCard:
        return AppRadius.card; // radius-3xl (20px)
      case GlassCardVariant.elevated:
        return AppRadius.massive; // radius-4xl (24px)
      case GlassCardVariant.subtle:
        return AppRadius.xxl; // radius-2xl (16px)
    }
  }

  /// 프리셋과 variant에 맞는 BoxDecoration을 반환한다
  BoxDecoration _resolveDecoration(
    ThemePresetData presetData, {
    required bool isDark,
  }) {
    switch (variant) {
      case GlassCardVariant.defaultCard:
        // isDark에 따라 라이트/다크 카드 데코레이션을 선택한다
        return presetData.resolveCardDecoration(isDark: isDark);
      case GlassCardVariant.elevated:
        return presetData.resolveElevatedDecoration(isDark: isDark);
      case GlassCardVariant.subtle:
        // 보조 카드는 별도 다크 데코레이션 없이 단일 함수 사용 (opacity만 조정)
        return presetData.subtleCardDecoration(radius: _borderRadius);
    }
  }

  /// variant별 기본 패딩 결정
  EdgeInsetsGeometry get _padding {
    if (padding != null) return padding!;
    switch (variant) {
      case GlassCardVariant.defaultCard:
        return const EdgeInsets.all(AppSpacing.cardPadding); // space-5 (20px)
      case GlassCardVariant.elevated:
        return const EdgeInsets.all(AppSpacing.dialogPadding); // space-6 (24px)
      case GlassCardVariant.subtle:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.lgXl, vertical: AppSpacing.mdLg); // space-3/space-3
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 테마 프리셋 데이터를 구독하여 프리셋 변경 시 자동으로 재빌드된다
    final presetData = ref.watch(themePresetDataProvider);
    final isDark = ref.watch(isDarkModeProvider);

    final decoration = _resolveDecoration(presetData, isDark: isDark);
    final sigma = _blurSigma(presetData);

    // 블러가 비활성화된 프리셋(minimal, retro): BackdropFilter 생략
    // ClipRRect 없이 단순 Container만 사용하여 성능을 향상시킨다
    if (!presetData.useBlur) {
      return Container(
        margin: margin,
        width: width,
        height: height,
        child: Container(
          decoration: decoration,
          padding: _padding,
          child: child,
        ),
      );
    }

    // 블러가 활성화된 프리셋(glassmorphism, neon):
    // ClipRRect → BackdropFilter → Container 순서로 감싼다
    // ClipRRect 없이 BackdropFilter 사용 시 전체 화면에 블러가 적용되어 성능 저하 발생
    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: sigma,
            sigmaY: sigma,
          ),
          child: Container(
            decoration: decoration,
            padding: _padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

