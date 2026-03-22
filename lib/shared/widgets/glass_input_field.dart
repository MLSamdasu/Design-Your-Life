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

/// 글래스 스타일 텍스트 입력 필드
class GlassInputField extends StatefulWidget {
  /// 입력 컨트롤러
  final TextEditingController? controller;

  /// 필드 상단 라벨 텍스트 (선택)
  final String? label;

  /// 플레이스홀더 힌트 텍스트 (선택)
  final String? hint;

  /// 에러 메시지 (null이면 에러 상태 아님)
  final String? errorText;

  /// 최대 줄 수 (기본 1)
  final int maxLines;

  /// 최대 입력 길이
  final int? maxLength;

  /// 키보드 유형
  final TextInputType keyboardType;

  /// 텍스트 변경 콜백
  final ValueChanged<String>? onChanged;

  /// 제출 콜백 (엔터 키)
  final VoidCallback? onSubmitted;

  /// 앞 아이콘 (선택)
  final IconData? prefixIcon;

  /// 뒤 아이콘 (선택, 탭 가능)
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;

  /// 비밀번호 입력 여부
  final bool obscureText;

  /// 자동 포커스 여부
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
            borderRadius: BorderRadius.circular(AppRadius.input), // radius-lg (12px)
            border: Border.all(
              color: hasError
                  // 에러 상태: 빨간색 border
                  ? ColorTokens.error.withValues(alpha: 0.60)
                  : _isFocused
                      // 포커스 상태: 0.50 opacity
                      ? context.themeColors.textPrimaryWithAlpha(0.50)
                      // 기본 상태: 0.20 opacity
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
            // 커서 색상: 테마 인식
            cursorColor: context.themeColors.textPrimary,
            style: AppTypography.bodyLg.copyWith(color: context.themeColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.bodyLg.copyWith(
                color: context.themeColors.hintColor,
              ),
              // Material 기본 border 제거 (커스텀 AnimatedContainer가 대체)
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lgXl,
              ),
              // 앞 아이콘 (선택)
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: context.themeColors.textPrimaryWithAlpha(0.60),
                      size: AppLayout.iconXl,
                    )
                  : null,
              // 뒤 아이콘 (선택, 탭 가능)
              suffixIcon: widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixIconTap,
                      child: Icon(
                        widget.suffixIcon,
                        color: context.themeColors.textPrimaryWithAlpha(0.60),
                        size: AppLayout.iconXl,
                      ),
                    )
                  : null,
              // maxLength 카운터 숨김
              counterText: '',
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
