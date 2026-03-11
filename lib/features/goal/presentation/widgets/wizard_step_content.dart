// F5 위젯: WizardStepContent - 만다라트 위저드 단계별 입력 폼
// 1단계: 핵심 목표 / 2단계: 세부 목표 8개 / 3단계: 실천 과제
// SRP: 각 단계의 입력 UI만 담당한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import 'wizard_text_field.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 1단계: 핵심 목표 입력
class WizardStep1CoreGoal extends StatelessWidget {
  final TextEditingController controller;

  const WizardStep1CoreGoal({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "만다라트란?" 설명 박스
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.08),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: AppLayout.iconMd,
                // 배경 테마에 맞는 악센트 색상으로 팁 아이콘을 표시한다
                color: context.themeColors.accent,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  '만다라트는 핵심 목표를 중심에 두고, '
                  '주변 8칸에 세부 목표, 각 세부 목표 주변 8칸에 실천 과제를 배치하는 목표 관리 도구입니다.',
                  style: AppTypography.captionMd.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // 핵심 목표 입력 필드
        WizardTextField(
          controller: controller,
          hintText: '예: 2025년 토익 900점 달성',
          maxLength: 200,
          autofocus: true,
        ),
      ],
    );
  }
}

/// 2단계: 세부 목표 8개 입력
class WizardStep2SubGoals extends StatelessWidget {
  final List<TextEditingController> controllers;

  const WizardStep2SubGoals({required this.controllers, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(8, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: WizardTextField(
            controller: controllers[i],
            hintText: '세부 목표 ${i + 1} (선택)',
            maxLength: 200,
            prefixText: '${i + 1}',
          ),
        );
      }),
    );
  }
}

/// 3단계: 실천 과제 입력 (세부 목표별 확장)
class WizardStep3Tasks extends StatefulWidget {
  final List<TextEditingController> subGoalControllers;
  final List<List<TextEditingController>> taskControllers;

  const WizardStep3Tasks({
    required this.subGoalControllers,
    required this.taskControllers,
    super.key,
  });

  @override
  State<WizardStep3Tasks> createState() => _WizardStep3TasksState();
}

class _WizardStep3TasksState extends State<WizardStep3Tasks> {
  final Set<int> _expandedIndices = {0};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(8, (i) {
        final subGoalTitle = widget.subGoalControllers[i].text.trim();
        // 입력된 세부 목표만 표시한다
        if (subGoalTitle.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: WizardSubGoalTaskGroup(
            subGoalIndex: i,
            subGoalTitle: subGoalTitle,
            taskControllers: widget.taskControllers[i],
            isExpanded: _expandedIndices.contains(i),
            onToggle: () {
              setState(() {
                if (_expandedIndices.contains(i)) {
                  _expandedIndices.remove(i);
                } else {
                  _expandedIndices.add(i);
                }
              });
            },
          ),
        );
      }),
    );
  }
}

/// 세부 목표 그룹 (확장/축소 가능)
class WizardSubGoalTaskGroup extends StatelessWidget {
  final int subGoalIndex;
  final String subGoalTitle;
  final List<TextEditingController> taskControllers;
  final bool isExpanded;
  final VoidCallback onToggle;

  const WizardSubGoalTaskGroup({
    required this.subGoalIndex,
    required this.subGoalTitle,
    required this.taskControllers,
    required this.isExpanded,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeColors.textPrimaryWithAlpha(0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          // 세부 목표 헤더 (탭하여 확장/축소)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  // 순번 뱃지
                  Container(
                    width: 20,
                    height: 20,
                    // 순번 뱃지: 배경 테마에 맞는 악센트 색상으로 표시한다
                    decoration: BoxDecoration(
                      color: context.themeColors.accentWithAlpha(0.5),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Center(
                      child: Text(
                        '${subGoalIndex + 1}',
                        style: AppTypography.captionSm.copyWith(
                    color: context.themeColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      subGoalTitle,
                      style: AppTypography.bodyMd.copyWith(
                    color: context.themeColors.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: AppAnimation.normal,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: AppLayout.iconMd,
                      color: context.themeColors.textPrimaryWithAlpha(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 실천 과제 입력 (확장 시)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: List.generate(8, (j) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: WizardTextField(
                      controller: taskControllers[j],
                      hintText: '실천 과제 ${j + 1} (선택)',
                      maxLength: 200,
                      prefixText: '${j + 1}',
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
