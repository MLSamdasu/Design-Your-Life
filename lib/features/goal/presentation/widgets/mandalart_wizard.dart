// F5 위젯: MandalartWizard - 만다라트 3단계 입력 위저드
// 1단계: 핵심 목표 1개 입력
// 2단계: 세부 목표 8개 입력 (건너뛰기 가능)
// 3단계: 실천 과제 입력 (세부 목표별 펼침)
// 부분 저장 허용: 단계 완료 시 Hive에 중간 상태 저장
// SRP: 오케스트레이션(저장 흐름 + 단계 라우팅)만 담당한다.
//       각 단계 UI는 wizard_step_content.dart, wizard_step_header.dart,
//       wizard_footer.dart, wizard_text_field.dart로 분리되어 있다.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/glassmorphism.dart';
import '../../../../shared/models/goal.dart';
import '../../../../shared/models/sub_goal.dart';
import '../../../../shared/models/goal_task.dart';
import '../../../../shared/enums/goal_period.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/mandalart_provider.dart';
import 'wizard_step_header.dart';
import 'wizard_step_content.dart';
import 'wizard_footer.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';

/// 만다라트 3단계 입력 위저드
/// AN-F5 위저드 단계 전환: Slide-left (이전→다음), Slide-right (다음→이전)
class MandalartWizard extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const MandalartWizard({
    this.onComplete,
    this.onCancel,
    super.key,
  });

  @override
  ConsumerState<MandalartWizard> createState() => _MandalartWizardState();
}

class _MandalartWizardState extends ConsumerState<MandalartWizard> {
  final _coreGoalController = TextEditingController();
  final List<TextEditingController> _subGoalControllers =
      List.generate(8, (_) => TextEditingController());
  final List<List<TextEditingController>> _taskControllers =
      List.generate(8, (_) => List.generate(8, (_) => TextEditingController()));

  bool _isSaving = false;

  @override
  void dispose() {
    _coreGoalController.dispose();
    for (final c in _subGoalControllers) {
      c.dispose();
    }
    for (final row in _taskControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  /// 입력 데이터를 서버에 저장하고 위저드를 완료한다
  Future<void> _saveAndComplete() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final coreGoalTitle = _coreGoalController.text.trim();
    if (coreGoalTitle.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      // 1. 핵심 목표(Goal) 생성
      final now = DateTime.now();
      final goal = Goal(
        id: '',
        userId: userId,
        title: coreGoalTitle,
        period: GoalPeriod.yearly,
        year: now.year,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );
      final goalId =
          await ref.read(goalNotifierProvider.notifier).createGoal(goal);
      if (goalId == null) return;

      // 2. 세부목표(SubGoal) 생성 (입력된 것만)
      for (int i = 0; i < 8; i++) {
        final title = _subGoalControllers[i].text.trim();
        if (title.isEmpty) continue;

        final subGoal = SubGoal(
          id: '',
          goalId: goalId,
          title: title,
          isCompleted: false,
          orderIndex: i,
          createdAt: now,
        );
        final subGoalId = await ref
            .read(goalNotifierProvider.notifier)
            .createSubGoal(goalId, subGoal);
        if (subGoalId == null) continue;

        // 3. 실천과제(GoalTask) 생성 (입력된 것만)
        for (int j = 0; j < 8; j++) {
          final taskTitle = _taskControllers[i][j].text.trim();
          if (taskTitle.isEmpty) continue;

          final task = GoalTask(
            id: '',
            subGoalId: subGoalId,
            title: taskTitle,
            isCompleted: false,
            orderIndex: j,
            createdAt: now,
          );
          await ref
              .read(goalNotifierProvider.notifier)
              .createTask(goalId, task);
        }
      }

      // 위저드 상태 초기화 후 완료 콜백 호출
      resetWizard(ref);
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        // async 간극 이후 context 사용 전 mounted 확인 (BuildContext 안전 사용)
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(wizardStepProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.dialogMaxWidthLg, maxHeight: 600),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: GlassDecoration.elevatedBlurSigma,
              sigmaY: GlassDecoration.elevatedBlurSigma,
            ),
            child: Container(
              decoration: GlassDecoration.modal(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더: 타이틀 + 단계 진행률
                  WizardStepHeader(
                    step: step,
                    onCancel:
                        widget.onCancel ?? () => Navigator.of(context).pop(),
                  ),
                  // 본문: 현재 단계 입력 폼
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: AnimatedSwitcher(
                        duration: AppAnimation.standard,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: _buildStepContent(step),
                      ),
                    ),
                  ),
                  // 하단 버튼
                  WizardFooter(
                    step: step,
                    isSaving: _isSaving,
                    canProceed: _canProceed(step),
                    onBack: () {
                      ref.read(wizardStepProvider.notifier).state = step - 1;
                    },
                    onNext: () {
                      if (step < 3) {
                        ref.read(wizardStepProvider.notifier).state = step + 1;
                      } else {
                        _saveAndComplete();
                      }
                    },
                    onSkip: step < 3
                        ? () {
                            ref.read(wizardStepProvider.notifier).state =
                                step + 1;
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 현재 단계에 맞는 콘텐츠 위젯을 반환한다
  Widget _buildStepContent(int step) {
    switch (step) {
      case 1:
        return WizardStep1CoreGoal(
          key: const ValueKey('step1'),
          controller: _coreGoalController,
        );
      case 2:
        return WizardStep2SubGoals(
          key: const ValueKey('step2'),
          controllers: _subGoalControllers,
        );
      case 3:
        return WizardStep3Tasks(
          key: const ValueKey('step3'),
          subGoalControllers: _subGoalControllers,
          taskControllers: _taskControllers,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// 현재 단계에서 다음 단계로 진행 가능한지 검증한다
  bool _canProceed(int step) {
    switch (step) {
      case 1:
        // 핵심 목표는 필수 입력
        return _coreGoalController.text.trim().isNotEmpty;
      case 2:
      case 3:
        // 세부목표/실천과제는 부분 저장 허용
        return true;
      default:
        return false;
    }
  }
}
