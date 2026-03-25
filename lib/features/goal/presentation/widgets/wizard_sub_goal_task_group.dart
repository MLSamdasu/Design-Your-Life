// F5 위젯: WizardSubGoalTaskGroup - 세부 목표별 실천 과제 그룹
// 확장/축소가 가능하며, 각 세부 목표의 실천 과제 입력 수를 표시한다.
// SRP 분리: 세부 목표 1개에 대한 과제 입력 그룹 UI만 담당한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'wizard_text_field.dart';

/// 세부 목표 그룹 (확장/축소 가능 + 과제 입력 수 표시)
class WizardSubGoalTaskGroup extends StatelessWidget {
  final int subGoalIndex;
  final String subGoalTitle;
  final List<TextEditingController> taskControllers;
  final bool isExpanded;
  final int filledTasks;
  final VoidCallback onToggle;

  const WizardSubGoalTaskGroup({
    required this.subGoalIndex,
    required this.subGoalTitle,
    required this.taskControllers,
    required this.isExpanded,
    required this.filledTasks,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete =
        filledTasks == GoalLayout.mandalartSubGoalCount;

    return Container(
      decoration: BoxDecoration(
        color: context.themeColors.textPrimaryWithAlpha(0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          // 세부 목표 헤더 (탭하여 확장/축소)
          _buildHeader(context, isComplete),
          // 실천 과제 입력 (확장 시)
          _buildTaskFields(),
        ],
      ),
    );
  }

  /// 세부 목표 헤더 — 순번 뱃지 + 제목 + 진행률 + 화살표
  Widget _buildHeader(BuildContext context, bool isComplete) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // 순번 뱃지
            _buildIndexBadge(context),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                subGoalTitle,
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimary,
                ),
              ),
            ),
            // 과제 입력 수 표시
            _buildProgressBadge(context, isComplete),
            const SizedBox(width: AppSpacing.sm),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: AppAnimation.normal,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppLayout.iconMd,
                color: context.themeColors
                    .textPrimaryWithAlpha(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 순번 뱃지 위젯
  Widget _buildIndexBadge(BuildContext context) {
    return Container(
      width: GoalLayout.badgeSm,
      height: GoalLayout.badgeSm,
      decoration: BoxDecoration(
        color: context.themeColors.accentWithAlpha(0.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Center(
        child: Text(
          '${subGoalIndex + 1}',
          style: AppTypography.captionSm.copyWith(
            color: context.themeColors.textPrimary,
            fontWeight: AppTypography.weightBold,
          ),
        ),
      ),
    );
  }

  /// 과제 완료 진행률 뱃지
  Widget _buildProgressBadge(BuildContext context, bool isComplete) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isComplete
            ? context.themeColors.accentWithAlpha(0.2)
            : context.themeColors
                .textPrimaryWithAlpha(0.1),
        borderRadius:
            BorderRadius.circular(AppRadius.huge),
      ),
      child: Text(
        '$filledTasks/${GoalLayout.mandalartSubGoalCount}',
        style: AppTypography.captionSm.copyWith(
          color: isComplete
              ? context.themeColors.accent
              : context.themeColors
                  .textPrimaryWithAlpha(0.5),
          fontWeight: isComplete
              ? AppTypography.weightSemiBold
              : AppTypography.weightMedium,
        ),
      ),
    );
  }

  /// 실천 과제 입력 필드 목록 (확장/축소 애니메이션)
  Widget _buildTaskFields() {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          children: List.generate(
              GoalLayout.mandalartSubGoalCount, (j) {
            return Padding(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.sm),
              child: WizardTextField(
                controller: taskControllers[j],
                hintText: '실천 과제 ${j + 1}',
                maxLength: 200,
                prefixText: '${j + 1}',
              ),
            );
          }),
        ),
      ),
      crossFadeState: isExpanded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: AppAnimation.normal,
      sizeCurve: Curves.easeOutCubic,
    );
  }
}
