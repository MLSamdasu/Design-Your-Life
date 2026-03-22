// 공용 위젯: GlassmorphicCard
// BackdropFilter + blur + 반투명 배경을 적용한 글래스모피즘 카드 컴포넌트.
// 홈 대시보드, 습관 카드, 목표 카드 등 여러 Feature에서 공통 사용한다.
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/glassmorphism.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';

/// 글래스모피즘 카드 위젯
/// ClipRRect + BackdropFilter 패턴으로 올바른 blur 영역 클리핑을 보장한다
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final GlassVariant variant;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassmorphicCard({
    required this.child,
    this.variant = GlassVariant.defaultCard,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    super.key,
  });

  /// variant에 따른 BoxDecoration 반환
  BoxDecoration _decoration() {
    switch (variant) {
      case GlassVariant.elevated:
        return GlassDecoration.elevatedCard();
      case GlassVariant.subtle:
        return GlassDecoration.subtleCard();
      case GlassVariant.darkDefault:
        return GlassDecoration.darkDefaultCard();
      case GlassVariant.defaultCard:
        return GlassDecoration.defaultCard();
    }
  }

  /// variant에 따른 blur sigma 반환
  double _blurSigma() {
    switch (variant) {
      case GlassVariant.elevated:
        return GlassDecoration.elevatedBlurSigma;
      case GlassVariant.subtle:
        return GlassDecoration.subtleBlurSigma;
      case GlassVariant.darkDefault:
        return GlassDecoration.elevatedBlurSigma;
      case GlassVariant.defaultCard:
        return GlassDecoration.defaultBlurSigma;
    }
  }

  /// variant에 따른 border radius 반환
  double _borderRadius() {
    switch (variant) {
      case GlassVariant.elevated:
        return AppRadius.massive;
      case GlassVariant.subtle:
        return AppRadius.xl;
      case GlassVariant.darkDefault:
        return AppRadius.card;
      case GlassVariant.defaultCard:
        return AppRadius.card;
    }
  }

  /// variant에 따른 기본 패딩 반환
  EdgeInsetsGeometry _defaultPadding() {
    switch (variant) {
      case GlassVariant.elevated:
        return const EdgeInsets.all(AppSpacing.dialogPadding);
      case GlassVariant.subtle:
        return const EdgeInsets.all(AppSpacing.lg);
      case GlassVariant.darkDefault:
        return const EdgeInsets.all(AppSpacing.cardPadding);
      case GlassVariant.defaultCard:
        return const EdgeInsets.all(AppSpacing.cardPadding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sigma = _blurSigma();
    final radius = _borderRadius();
    final effectivePadding = padding ?? _defaultPadding();

    // RepaintBoundary로 감싸 BackdropFilter 리페인트가 상위 위젯으로 전파되는 것을 차단한다
    // 스크롤 중 불필요한 BackdropFilter 재합성을 방지하여 투명도 깜빡임을 해소한다
    Widget card = RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            width: width,
            height: height,
            padding: effectivePadding,
            decoration: _decoration(),
            // Material 위젯을 제공하여 InkWell, Switch, PopupMenuButton 등
            // Material 조상이 필요한 자식 위젯의 크래시를 방지한다
            child: Material(
              type: MaterialType.transparency,
              child: child,
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}
