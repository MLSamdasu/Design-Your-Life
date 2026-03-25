// F5 위젯: GoalDialogActionButtons - 목표 다이얼로그 하단 액션 버튼
// 취소/추가(저장) 버튼 행을 표시한다.
// SRP 분리: goal_create_dialog.dart에서 추출된 액션 버튼 위젯
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 다이얼로그 하단 버튼 행 (취소 / 추가 또는 저장)
class GoalDialogActionButtons extends StatelessWidget {
  final bool isSubmitting;
  final String submitLabel;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const GoalDialogActionButtons({
    super.key,
    required this.isSubmitting,
    this.submitLabel = '추가',
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 취소 버튼
        Expanded(
          child: TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lgXl),
              foregroundColor: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
            child: Text(
              '취소',
              style: AppTypography.titleMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.7),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        // 추가 버튼 (로딩 중 비활성화)
        Expanded(
          child: ElevatedButton(
            onPressed: isSubmitting ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorTokens.main,
              foregroundColor: ColorTokens.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lgXl),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              elevation: EffectLayout.elevationNone,
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: AppLayout.iconMd,
                    height: AppLayout.iconMd,
                    child: CircularProgressIndicator(
                      strokeWidth: GoalLayout.spinnerStrokeWidth,
                      // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
                      color: ColorTokens.white,
                    ),
                  )
                : Text(
                    submitLabel,
                    style: AppTypography.titleMd.copyWith(
                      // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
                      color: ColorTokens.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
