// F3 위젯: TodoFormFields - 투두 다이얼로그 공용 폼 필드 (SRP 분리)
// todo_create_dialog.dart에서 추출한다.
// 포함: TodoGlassTextField, TodoPrimaryButton, TodoDialogHeader, TodoColorSection
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/color_picker.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// Glass 스타일 텍스트 필드 (투두 다이얼로그용)
class TodoGlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final String? Function(String?)? validator;

  const TodoGlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: AppLayout.todoTitleMaxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      // 카운터 위젯을 숨겨 시각적 노이즈를 제거한다
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
      validator: validator,
      style: AppTypography.bodyLg.copyWith(color: context.themeColors.textPrimary),
      cursorColor: context.themeColors.textPrimary,
      decoration: InputDecoration(
        hintText: hintText,
        // WCAG: 힌트 텍스트 알파 0.55 이상으로 가독성 보장
        hintStyle: AppTypography.bodyLg.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.55),
        ),
        filled: true,
        fillColor: context.themeColors.textPrimaryWithAlpha(0.10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: context.themeColors.textPrimaryWithAlpha(0.20)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: context.themeColors.textPrimaryWithAlpha(0.20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: context.themeColors.textPrimaryWithAlpha(0.50)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(
            color: ColorTokens.error.withValues(alpha: 0.6),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lgXl,
        ),
      ),
    );
  }
}

/// Primary CTA 버튼 (투두 다이얼로그용)
class TodoPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const TodoPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lgXl),
        decoration: BoxDecoration(
          color: ColorTokens.main,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.main.withValues(alpha: AppLayout.badgeShadowAlpha),
              blurRadius: AppLayout.ctaShadowBlur,
              offset: const Offset(0, AppLayout.ctaShadowOffsetY),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
            style: AppTypography.titleMd.copyWith(color: ColorTokens.white),
          ),
        ),
      ),
    );
  }
}

/// 다이얼로그 헤더 (제목 텍스트 + 닫기 버튼)
/// [title]: 헤더 제목 (기본값: '할 일 추가', 수정 모드에서는 '할 일 수정' 전달)
class TodoDialogHeader extends StatelessWidget {
  final VoidCallback onClose;
  final String title;

  const TodoDialogHeader({
    super.key,
    required this.onClose,
    this.title = '할 일 추가',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.titleMd.copyWith(color: context.themeColors.textPrimary),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onClose,
          child: Icon(
            Icons.close_rounded,
            color: context.themeColors.textPrimaryWithAlpha(0.6),
            size: AppLayout.iconXl,
          ),
        ),
      ],
    );
  }
}

/// 색상 선택 섹션 (투두 다이얼로그용)
class TodoColorSection extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const TodoColorSection({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '색상',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.8),
          ),
        ),
        const SizedBox(height: AppSpacing.mdLg),
        ColorPickerWidget(
          selectedIndex: selectedIndex,
          onColorSelected: onSelected,
        ),
      ],
    );
  }
}
