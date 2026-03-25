// 태그 이름 입력 필드 위젯
// 태그 생성/편집 시 사용되는 이름 입력 필드와 에러 표시를 담당한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 태그 이름 입력 필드 (라벨 + 텍스트필드 + 에러 메시지)
class TagNameField extends StatelessWidget {
  /// 텍스트 입력 컨트롤러
  final TextEditingController controller;

  /// 유효성 검증 에러 메시지 (null이면 에러 없음)
  final String? errorText;

  /// 텍스트 변경 시 콜백 (에러 초기화 등에 사용)
  final ValueChanged<String> onChanged;

  const TagNameField({
    super.key,
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '태그 이름',
          style: AppTypography.captionLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedContainer(
          duration: AppAnimation.normal,
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.10),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: errorText != null
                  ? ColorTokens.error.withValues(alpha: 0.6)
                  : context.themeColors.textPrimaryWithAlpha(0.20),
            ),
          ),
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            style: AppTypography.bodyLg.copyWith(
              color: context.themeColors.textPrimary,
            ),
            cursorColor: context.themeColors.textPrimary,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: '태그 이름 (최대 20자)',
              // WCAG: 힌트 텍스트 알파 0.55 이상으로 가독성 보장
              hintStyle: AppTypography.bodyLg.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.55),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lgXl,
              ),
              counterText: '',
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: AppTypography.captionMd.copyWith(
              color: ColorTokens.error.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );
  }
}
