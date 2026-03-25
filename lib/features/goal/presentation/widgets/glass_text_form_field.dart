// F5 위젯: GlassTextFormField - Glass 스타일 텍스트 입력 필드
// SRP 분리: goal_create_form_fields.dart에서 텍스트 입력 위젯을 추출
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

// ─── Glass 텍스트 폼 필드 ─────────────────────────────────────────────────

/// Glass 스타일 텍스트 입력 필드 (Form 유효성 검사 지원)
/// GoalCreateDialog의 제목/설명 입력에 사용한다
class GlassTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLength;
  final int maxLines;
  final String? Function(String?)? validator;

  const GlassTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.maxLength,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
      style: AppTypography.bodyLg.copyWith(color: context.themeColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        // WCAG 최소 대비: 힌트 텍스트 0.55 이상 보장
        hintStyle: AppTypography.bodyLg.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.55),
        ),
        // WCAG 최소 대비: 글자 수 카운터 텍스트 0.55 이상 보장
        counterStyle: AppTypography.captionSm.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.55),
        ),
        filled: true,
        fillColor: context.themeColors.textPrimaryWithAlpha(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(
            color: context.themeColors.textPrimaryWithAlpha(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(
            color: context.themeColors.textPrimaryWithAlpha(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(
            color: context.themeColors.textPrimaryWithAlpha(0.5),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(
            color: ColorTokens.error.withValues(alpha: AppAnimation.errorBorderAlpha),
          ),
        ),
        errorStyle: AppTypography.captionMd.copyWith(
          color: ColorTokens.errorLight,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lgXl,
        ),
      ),
    );
  }
}
