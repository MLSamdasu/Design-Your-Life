// F5 위젯: GoalCheckpointInputSection - 목표 생성 시 체크포인트 입력 섹션
// 각 체크포인트는 SubGoal로 저장되어 진행률 자동 계산에 사용된다.
// SRP 분리: goal_create_dialog.dart에서 추출된 체크포인트 입력 위젯
import 'package:flutter/material.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import 'goal_create_form_fields.dart';

/// 목표 생성 시 체크포인트(중간 단계) 입력 섹션
/// 각 체크포인트는 SubGoal로 저장되어 진행률 자동 계산에 사용된다
class GoalCheckpointInputSection extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const GoalCheckpointInputSection({
    super.key,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Text(
          '체크포인트 (선택)',
          style: AppTypography.captionLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '목표 달성 과정의 중간 단계를 추가하세요',
          style: AppTypography.captionMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.4),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // 체크포인트 목록
        ...List.generate(controllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                // 순번 뱃지
                Container(
                  width: GoalLayout.badgeSm,
                  height: GoalLayout.badgeSm,
                  decoration: BoxDecoration(
                    color: context.themeColors.accentWithAlpha(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTypography.captionSm.copyWith(
                        // WCAG 대비: accent 배경 위에서 테마 텍스트 색상으로 고대비 확보
                        color: context.themeColors.textPrimaryWithAlpha(0.85),
                        fontWeight: AppTypography.weightSemiBold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // 입력 필드
                Expanded(
                  child: GlassTextFormField(
                    controller: controllers[index],
                    hintText: '체크포인트 ${index + 1}',
                    maxLength: 200,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // 삭제 버튼
                GestureDetector(
                  onTap: () => onRemove(index),
                  child: SizedBox(
                    width: AppLayout.minTouchTarget,
                    height: AppLayout.minTouchTarget,
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: AppLayout.iconMd,
                        color: context.themeColors.textPrimaryWithAlpha(0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        // 추가 버튼
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: context.themeColors.textPrimaryWithAlpha(0.2),
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: AppLayout.iconMd,
                  // WCAG 고대비: 밝은 배경에서도 선명하게 보이도록 alpha 제거
                  color: context.themeColors.accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '체크포인트 추가',
                  style: AppTypography.bodyMd.copyWith(
                    // WCAG 고대비: 밝은 배경에서도 선명하게 보이도록 alpha 제거
                    color: context.themeColors.accent,
                    fontWeight: AppTypography.weightMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
