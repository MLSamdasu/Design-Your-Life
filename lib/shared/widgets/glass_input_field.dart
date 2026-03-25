// 공용 위젯: GlassInputField (글래스 스타일 텍스트 입력 필드)
// 라벨, 힌트, 에러 텍스트를 지원하며 design-system.md 4.5절 스펙을 따른다.
// 포커스 시 border opacity가 0.20 -> 0.50으로 전환된다.
import 'package:flutter/material.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';
import 'glass_input_decoration.dart';

export 'glass_input_decoration.dart';

/// 글래스 스타일 텍스트 입력 필드
class GlassInputField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final int maxLines;
  final int? maxLength;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final bool obscureText;
  final bool autofocus;

  const GlassInputField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.obscureText = false,
    this.autofocus = false,
  });

  @override
  State<GlassInputField> createState() => _GlassInputFieldState();
}

class _GlassInputFieldState extends State<GlassInputField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // 포커스 상태 변경 감지로 border 색상을 전환한다
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨 텍스트 (선택)
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.captionLg.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.70),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // 입력 필드 본체
        AnimatedContainer(
          duration: AppAnimation.normal,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: context.themeColors.overlayLight,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(
              color: hasError
                  ? ColorTokens.error.withValues(alpha: 0.60)
                  : _isFocused
                      ? context.themeColors.textPrimaryWithAlpha(0.50)
                      : context.themeColors.textPrimaryWithAlpha(0.20),
              width: _isFocused ? AppLayout.borderMedium : AppLayout.borderThin,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted != null
                ? (_) => widget.onSubmitted!()
                : null,
            cursorColor: context.themeColors.textPrimary,
            style: AppTypography.bodyLg.copyWith(color: context.themeColors.textPrimary),
            decoration: GlassInputDecorationBuilder.build(
              context: context,
              hint: widget.hint,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              onSuffixIconTap: widget.onSuffixIconTap,
            ),
          ),
        ),
        // 에러 텍스트 (선택)
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          AnimatedOpacity(
            opacity: 1.0,
            duration: AppAnimation.normal,
            child: Text(
              widget.errorText!,
              style: AppTypography.captionMd.copyWith(
                color: ColorTokens.error.withValues(alpha: 0.80),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
