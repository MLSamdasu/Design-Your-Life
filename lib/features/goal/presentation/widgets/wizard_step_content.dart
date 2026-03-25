// F5 위젯: WizardStepContent - 만다라트 위저드 단계별 입력 폼
// 1단계: 핵심 목표 / 2단계: 세부 목표 8개 / 3단계: 실천 과제
// 81칸 전부 필수 입력 (만다라트의 핵심 원칙)
// SRP 분리: 각 단계의 입력 UI만 담당한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'wizard_text_field.dart';
import 'wizard_info_box.dart';
import 'wizard_sub_goal_task_group.dart';

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
        WizardInfoBox(
          icon: Icons.lightbulb_outline_rounded,
          text: '만다라트는 핵심 목표를 중심에 두고, '
              '주변 8칸에 세부 목표, 각 세부 목표 주변 8칸에 실천 과제를 배치하는 '
              '목표 관리 도구입니다.\n\n'
              '81칸을 억지로라도 전부 채우는 과정 자체가 사고를 확장시킵니다. '
              '빈칸이 남으면 "아직 생각이 부족하다"는 신호입니다.',
        ),
        const SizedBox(height: AppSpacing.xl),
        // 핵심 목표 입력 필드
        WizardTextField(
          controller: controller,
          hintText: '예: ${DateTime.now().year}년 토익 900점 달성',
          maxLength: 200,
          autofocus: true,
        ),
      ],
    );
  }
}

/// 2단계: 세부 목표 8개 입력 (전부 필수)
class WizardStep2SubGoals extends StatelessWidget {
  final List<TextEditingController> controllers;

  const WizardStep2SubGoals({required this.controllers, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WizardInfoBox(
          icon: Icons.hub_rounded,
          text: '핵심 목표를 이루기 위한 8가지 카테고리를 입력하세요.\n'
              '예: 코딩 테스트, 포트폴리오, CS 지식, ML 역량 등\n\n'
              '8칸 전부 채우는 것이 만다라트의 핵심입니다!',
        ),
        const SizedBox(height: AppSpacing.xl),
        ...List.generate(GoalLayout.mandalartSubGoalCount, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: WizardTextField(
              controller: controllers[i],
              hintText: '세부 목표 ${i + 1}',
              maxLength: 200,
              prefixText: '${i + 1}',
            ),
          );
        }),
      ],
    );
  }
}

/// 3단계: 실천 과제 입력 (세부 목표별 확장, 전부 필수)
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WizardInfoBox(
          icon: Icons.checklist_rounded,
          text: '각 세부 목표마다 구체적인 실천 과제 8개를 입력하세요.\n'
              '예: "백준 골드 문제 주 5회 풀기"처럼 바로 실행 가능한 수준까지 '
              '내려가는 것이 포인트입니다.\n\n'
              '64칸 전부 채워야 만다라트가 완성됩니다!',
        ),
        const SizedBox(height: AppSpacing.xl),
        ...List.generate(GoalLayout.mandalartSubGoalCount, (i) {
          final subGoalTitle =
              widget.subGoalControllers[i].text.trim();
          // 세부 목표가 채워져있어야 해당 실천 과제 그룹을 표시한다
          if (subGoalTitle.isEmpty) return const SizedBox.shrink();

          // 해당 세부 목표의 실천 과제 입력 수 카운트
          final filledTasks = widget.taskControllers[i]
              .where((c) => c.text.trim().isNotEmpty)
              .length;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: WizardSubGoalTaskGroup(
              subGoalIndex: i,
              subGoalTitle: subGoalTitle,
              taskControllers: widget.taskControllers[i],
              isExpanded: _expandedIndices.contains(i),
              filledTasks: filledTasks,
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
      ],
    );
  }
}
