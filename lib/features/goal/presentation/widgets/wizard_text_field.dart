// F5 위젯: WizardTextField - 만다라트 위저드 텍스트 입력 필드
// Glass 스타일 단일 라인 입력 필드를 제공한다.
// SRP 분리: 위저드 내 텍스트 입력 UI만 담당한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 위저드 텍스트 필드 (Glass 스타일)
class WizardTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLength;
  final bool autofocus;
  final String? prefixText;

  const WizardTextField({
    required this.controller,
    required this.hintText,
    required this.maxLength,
    this.autofocus = false,
    this.prefixText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      autofocus: autofocus,
      style: AppTypography.bodyLg.copyWith(color: context.themeColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.bodyLg.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.35),
        ),
        counterStyle: AppTypography.captionSm.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.3),
        ),
        prefixText: prefixText != null ? '$prefixText. ' : null,
        prefixStyle: AppTypography.captionLg.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.5),
        ),
        filled: true,
        fillColor: context.themeColors.textPrimaryWithAlpha(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          borderSide: BorderSide(color: context.themeColors.textPrimaryWithAlpha(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          borderSide: BorderSide(color: context.themeColors.textPrimaryWithAlpha(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          borderSide: BorderSide(color: context.themeColors.textPrimaryWithAlpha(0.4)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.mdLg,
        ),
        isDense: true,
      ),
    );
  }
}
