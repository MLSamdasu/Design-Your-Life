// 공용 위젯: GlassButton — Primary/Secondary/Ghost 3변형 글래스 버튼
import 'package:flutter/material.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// 글래스 버튼 변형 유형
/// Primary: MAIN 단색, Secondary: 반투명 유리, Ghost: 투명
enum GlassButtonVariant { primary, secondary, ghost }

/// 글래스 스타일 버튼 공용 위젯
class GlassButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final GlassButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool fullWidth;
  /// 컴팩트 모드 — 패딩·아이콘·간격 축소 (3버튼 Row용)
  final bool compact;

  const GlassButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = GlassButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.fullWidth = false,
    this.compact = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) {
          if (!isDisabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (!isDisabled) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (!isDisabled) setState(() => _isPressed = false);
        },
        onTap: isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          curve: Curves.easeOutCubic,
          width: widget.fullWidth ? double.infinity : null,
          decoration: _buildDecoration(isDisabled),
          padding: _buildPadding(),
          child: _buildContent(isDisabled),
        ),
      ),
    );
  }

  /// variant + 상태에 따른 버튼 데코레이션 결정
  BoxDecoration _buildDecoration(bool isDisabled) {
    switch (widget.variant) {
      case GlassButtonVariant.primary:
        // MAIN 단색, 비활성 시 40% opacity
        Color bgColor = isDisabled
            ? ColorTokens.main.withValues(alpha: 0.40)
            : _isPressed
                ? ColorTokens.mainPressed // #5B24BA
                : ColorTokens.main; // #7C3AED
        return BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.button), // radius-lg
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    // CTA 버튼 전용 MAIN 컬러 그림자 (shadow-cta)
                    color: ColorTokens.main.withValues(alpha: 0.30),
                    blurRadius: EffectLayout.ctaShadowBlur,
                    offset: const Offset(0, EffectLayout.ctaShadowOffsetY),
                  ),
                ],
        );

      case GlassButtonVariant.secondary:
        // 반투명 유리 배경 (테마 인식)
        final tc = context.themeColors;
        return BoxDecoration(
          color: isDisabled
              ? tc.overlayLight
              : _isPressed
                  ? tc.textPrimaryWithAlpha(0.30)
                  : tc.overlayStrong,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: tc.textPrimaryWithAlpha(0.30),
            width: AppLayout.borderThin,
          ),
        );

      case GlassButtonVariant.ghost:
        // 투명 배경, hover/pressed 시 미세한 배경
        return BoxDecoration(
          color: isDisabled
              ? ColorTokens.transparent
              : _isPressed
                  ? context.themeColors.overlayLight
                  : ColorTokens.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg), // radius-lg (8px)
        );
    }
  }

  /// variant별 패딩 — compact 모드에서는 패딩 축소
  EdgeInsetsGeometry _buildPadding() {
    if (widget.compact) {
      return const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      );
    }
    switch (widget.variant) {
      case GlassButtonVariant.primary:
      case GlassButtonVariant.secondary:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl, vertical: AppSpacing.lgXl);
      case GlassButtonVariant.ghost:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md);
    }
  }

  /// 버튼 내부 콘텐츠 (아이콘 + 텍스트)
  Widget _buildContent(bool isDisabled) {
    final tc = context.themeColors;
    // 텍스트 색상: primary 버튼은 항상 흰색(MAIN 컬러 배경), 나머지는 테마 인식
    Color textColor;
    if (widget.variant == GlassButtonVariant.primary) {
      // Primary 버튼은 MAIN 컬러 배경이므로 항상 흰색 텍스트
      textColor = isDisabled
          ? ColorTokens.white.withValues(alpha: 0.50)
          : ColorTokens.white;
    } else if (widget.variant == GlassButtonVariant.ghost) {
      textColor = isDisabled
          // WCAG 대비 기준: 비활성 텍스트 최소 alpha 0.45
          ? tc.textPrimaryWithAlpha(0.45)
          : tc.textPrimaryWithAlpha(0.70);
    } else {
      textColor = isDisabled
          ? tc.textPrimaryWithAlpha(0.50)
          : tc.textPrimary;
    }

    // 텍스트 스타일: ghost는 body-lg(medium), 나머지는 title-md(semibold)
    final textStyle = widget.variant == GlassButtonVariant.ghost
        ? AppTypography.bodyMd.copyWith(color: textColor)
        : AppTypography.titleMd.copyWith(color: textColor);

    // compact 모드에서 아이콘/텍스트 크기·간격 축소
    final iconSize = widget.compact ? AppLayout.iconMd : AppLayout.iconLg;
    final iconGap = widget.compact ? AppSpacing.xs : AppSpacing.md;
    final labelStyle = widget.compact
        ? AppTypography.bodyMd.copyWith(color: textColor)
        : textStyle;

    return Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingIcon != null) ...[
          Icon(widget.leadingIcon, color: textColor, size: iconSize),
          SizedBox(width: iconGap),
        ],
        Flexible(child: Text(widget.label, style: labelStyle, overflow: TextOverflow.ellipsis, maxLines: 1)),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.md),
          Icon(widget.trailingIcon, color: textColor, size: AppLayout.iconLg),
        ],
      ],
    );
  }
}
