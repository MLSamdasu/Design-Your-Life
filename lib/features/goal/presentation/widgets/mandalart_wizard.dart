// F5 위젯: MandalartWizard — 만다라트 3단계 입력 위저드
// SRP 분리: 오케스트레이션(저장 흐름 + 단계 라우팅)만 담당한다.
// 하위 모듈: wizard_field_helpers / wizard_save_handler / wizard_glass_container
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../providers/mandalart_provider.dart';
import 'wizard_field_helpers.dart';
import 'wizard_footer.dart';
import 'wizard_glass_container.dart';
import 'wizard_save_handler.dart';
import 'wizard_step_content.dart';
import 'wizard_step_header.dart';

/// 만다라트 3단계 입력 위저드
/// 81칸 전부 채워야 완료 가능 (만다라트의 핵심 원칙)
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
      List.generate(GoalLayout.mandalartSubGoalCount,
          (_) => TextEditingController());
  final List<List<TextEditingController>> _taskControllers =
      List.generate(
          GoalLayout.mandalartSubGoalCount,
          (_) => List.generate(
              GoalLayout.mandalartSubGoalCount,
              (_) => TextEditingController()));

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 모든 텍스트 필드 변경 시 _canProceed 재평가를 위해 리빌드를 트리거한다
    _coreGoalController.addListener(_onTextChanged);
    for (final c in _subGoalControllers) {
      c.addListener(_onTextChanged);
    }
    for (final row in _taskControllers) {
      for (final c in row) {
        c.addListener(_onTextChanged);
      }
    }
  }

  /// 텍스트 입력 변경 시 리빌드한다
  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _coreGoalController.removeListener(_onTextChanged);
    _coreGoalController.dispose();
    for (final c in _subGoalControllers) {
      c.removeListener(_onTextChanged);
      c.dispose();
    }
    for (final row in _taskControllers) {
      for (final c in row) {
        c.removeListener(_onTextChanged);
        c.dispose();
      }
    }
    super.dispose();
  }

  /// 자동 채우기 후 리빌드를 트리거한다
  void _autoFill() {
    autoFillWizardStep(
      step: ref.read(wizardStepProvider),
      subGoalControllers: _subGoalControllers,
      taskControllers: _taskControllers,
    );
    setState(() {});
  }

  /// 저장 완료 처리를 위임하고 결과에 따라 화면을 닫는다
  Future<void> _saveAndComplete() async {
    setState(() => _isSaving = true);
    try {
      final success = await saveMandalartAndComplete(
        ref: ref,
        context: context,
        coreGoalController: _coreGoalController,
        subGoalControllers: _subGoalControllers,
        taskControllers: _taskControllers,
      );
      if (!success) return;
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// 다음 단계 진행 가능 여부를 wizard_field_helpers에 위임한다
  bool _canProceed(int step) => canProceedWizardStep(
        step: step,
        coreGoalController: _coreGoalController,
        subGoalControllers: _subGoalControllers,
        taskControllers: _taskControllers,
      );

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(wizardStepProvider);

    return WizardGlassContainer(
      children: [
        WizardStepHeader(
          step: step,
          onCancel: widget.onCancel ?? () => Navigator.of(context).pop(),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxxl, 0, AppSpacing.xxxl, AppSpacing.xxxl),
            child: AnimatedSwitcher(
              duration: AppAnimation.standard,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _buildStepContent(step),
            ),
          ),
        ),
        WizardFooter(
          step: step,
          isSaving: _isSaving,
          canProceed: _canProceed(step),
          filledCount: wizardFilledCount(
            step: step,
            subGoalControllers: _subGoalControllers,
            taskControllers: _taskControllers,
          ),
          totalCount: wizardTotalCount(step),
          onBack: () =>
              ref.read(wizardStepProvider.notifier).state = step - 1,
          onNext: () {
            if (step < GoalLayout.wizardStepCount) {
              ref.read(wizardStepProvider.notifier).state = step + 1;
            } else {
              _saveAndComplete();
            }
          },
          onAutoFill:
              (step >= 2 && !_canProceed(step)) ? _autoFill : null,
        ),
      ],
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
}
