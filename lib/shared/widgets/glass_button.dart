// 공용 위젯: GlassButton (글래스 스타일 버튼)
// Primary(MAIN 채움) / Secondary(유리) / Ghost(투명) 3가지 변형을 지원한다.
// design-system.md 4.4절 Glass Button 스펙을 따른다.
import 'package:flutter/material.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// 글래스 버튼 변형 유형
enum GlassButtonVariant {
  /// Primary: MAIN(#7C3AED) 단색 배경, CTA 버튼 (5.70:1 대비비)
  primary,

  /// Secondary: 반투명 유리 배경, 보조 버튼
  secondary,

  /// Ghost: 투명 배경, 텍스트 링크 스타일
  ghost,
}

/// 글래스 스타일 버튼 공용 위젯
class GlassButton extends StatefulWidget {
  /// 버튼 텍스트
  final String label;

  /// 탭 콜백 (null이면 비활성화)
  final VoidCallback? onTap;

  /// 버튼 변형 유형
  final GlassButtonVariant variant;

  /// 앞 아이콘 (선택)
  final IconData? leadingIcon;

  /// 뒤 아이콘 (선택)
  final IconData? trailingIcon;

  /// 전체 너비 여부
  final bool fullWidth;

  const GlassButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = GlassButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.fullWidth = false,
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
                    blurRadius: AppLayout.ctaShadowBlur,
                    offset: const Offset(0, AppLayout.ctaShadowOffsetY),
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

  /// variant별 패딩
  EdgeInsetsGeometry _buildPadding() {
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

    return Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingIcon != null) ...[
          Icon(widget.leadingIcon, color: textColor, size: AppLayout.iconLg),
          const SizedBox(width: AppSpacing.md),
        ],
        Text(widget.label, style: textStyle),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.md),
          Icon(widget.trailingIcon, color: textColor, size: AppLayout.iconLg),
        ],
      ],
    );
  }
}
