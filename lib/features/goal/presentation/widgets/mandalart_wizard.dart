// F5 위젯: MandalartWizard - 만다라트 3단계 입력 위저드
// 1단계: 핵심 목표 1개 입력 (필수)
// 2단계: 세부 목표 8개 입력 (필수 — 81칸 전부 채우는 것이 만다라트의 핵심)
// 3단계: 실천 과제 입력 (필수 — 세부 목표별 8개씩 총 64개)
// 부분 저장 금지: 81칸 전부 채워야 완료 가능
// 채울 수 없으면 '다 채워줘'(자동 채우기) 또는 '취소' 선택
// SRP: 오케스트레이션(저장 흐름 + 단계 라우팅)만 담당한다.
//       각 단계 UI는 wizard_step_content.dart, wizard_step_header.dart,
//       wizard_footer.dart, wizard_text_field.dart로 분리되어 있다.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../shared/models/goal.dart';
import '../../../../shared/enums/goal_period.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../providers/goal_provider.dart';
import '../../providers/mandalart_provider.dart';
import 'wizard_step_header.dart';
import 'wizard_step_content.dart';
import 'wizard_footer.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

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
      List.generate(AppLayout.mandalartSubGoalCount,
          (_) => TextEditingController());
  final List<List<TextEditingController>> _taskControllers =
      List.generate(
          AppLayout.mandalartSubGoalCount,
          (_) => List.generate(
              AppLayout.mandalartSubGoalCount, (_) => TextEditingController()));

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

  /// 텍스트 입력 변경 시 _canProceed 재평가를 위해 리빌드한다
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

  /// 빈 칸에 자동 채우기 (만다라트 원칙: 억지로라도 81칸 전부 채운다)
  /// 세부 목표: '세부 목표 N' 형식
  /// 실천 과제: '(세부목표명) - 과제 N' 형식
  void _autoFill() {
    final step = ref.read(wizardStepProvider);
    if (step == 2) {
      // 세부 목표 빈 칸 자동 채우기
      for (int i = 0; i < _subGoalControllers.length; i++) {
        if (_subGoalControllers[i].text.trim().isEmpty) {
          _subGoalControllers[i].text = '세부 목표 ${i + 1}';
        }
      }
    } else if (step == 3) {
      // 실천 과제 빈 칸 자동 채우기
      for (int i = 0; i < _subGoalControllers.length; i++) {
        final sgTitle = _subGoalControllers[i].text.trim();
        for (int j = 0; j < _taskControllers[i].length; j++) {
          if (_taskControllers[i][j].text.trim().isEmpty) {
            _taskControllers[i][j].text = '$sgTitle - 과제 ${j + 1}';
          }
        }
      }
    }
    setState(() {});
  }

  /// 현재 단계의 입력 완료 수를 반환한다
  int _filledCount(int step) {
    switch (step) {
      case 2:
        return _subGoalControllers
            .where((c) => c.text.trim().isNotEmpty)
            .length;
      case 3:
        int count = 0;
        for (int i = 0; i < _subGoalControllers.length; i++) {
          for (int j = 0; j < _taskControllers[i].length; j++) {
            if (_taskControllers[i][j].text.trim().isNotEmpty) count++;
          }
        }
        return count;
      default:
        return 0;
    }
  }

  /// 현재 단계의 총 필드 수를 반환한다
  int _totalCount(int step) {
    switch (step) {
      case 2:
        return AppLayout.mandalartSubGoalCount; // 8
      case 3:
        return AppLayout.mandalartSubGoalCount *
            AppLayout.mandalartSubGoalCount; // 64
      default:
        return 0;
    }
  }

  /// 입력 데이터를 로컬 Hive에 원자적으로 저장하고 위저드를 완료한다
  /// state 변경과 버전 갱신을 한 번만 수행하여 크래시를 방지한다
  Future<void> _saveAndComplete() async {
    // 로컬 퍼스트: 로그인 없이도 저장 가능하도록 폴백 사용자 ID를 적용한다
    final userId =
        ref.read(currentUserIdProvider) ?? AppConstants.localUserId;

    final coreGoalTitle = _coreGoalController.text.trim();
    if (coreGoalTitle.isEmpty) return;

    setState(() => _isSaving = true);

    try {
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

      // 세부 목표 제목 8개 수집
      final subGoalTitles = _subGoalControllers
          .map((c) => c.text.trim())
          .toList();

      // 실천 과제 제목 8×8 수집
      final taskTitles = <List<String>>[];
      for (int i = 0; i < _taskControllers.length; i++) {
        taskTitles.add(
          _taskControllers[i].map((c) => c.text.trim()).toList(),
        );
      }

      // 원자적 생성: Goal + 8 SubGoal + 64 GoalTask 한 번에 저장
      final goalId = await ref
          .read(goalNotifierProvider.notifier)
          .createMandalart(goal, subGoalTitles, taskTitles);

      if (goalId == null) {
        if (mounted) {
          AppSnackBar.showError(context, '만다라트 저장에 실패했습니다');
        }
        return;
      }

      // 위저드 상태 초기화 후 완료 콜백 호출
      resetWizard(ref);
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '만다라트 저장에 실패했습니다');
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
        constraints: const BoxConstraints(
            maxWidth: AppLayout.dialogMaxWidthLg,
            maxHeight: AppLayout.dialogMaxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: GlassDecoration.elevatedBlurSigma,
              sigmaY: GlassDecoration.elevatedBlurSigma,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                decoration: GlassDecoration.modal(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 헤더: 타이틀 + 단계 진행률
                    WizardStepHeader(
                      step: step,
                      onCancel: widget.onCancel ??
                          () => Navigator.of(context).pop(),
                    ),
                    // 본문: 현재 단계 입력 폼
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xxxl, 0, AppSpacing.xxxl, AppSpacing.xxxl),
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
                      filledCount: _filledCount(step),
                      totalCount: _totalCount(step),
                      onBack: () {
                        ref.read(wizardStepProvider.notifier).state =
                            step - 1;
                      },
                      onNext: () {
                        if (step < AppLayout.wizardStepCount) {
                          ref.read(wizardStepProvider.notifier).state =
                              step + 1;
                        } else {
                          _saveAndComplete();
                        }
                      },
                      onAutoFill: (step >= 2 && !_canProceed(step))
                          ? _autoFill
                          : null,
                    ),
                  ],
                ),
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
  /// 만다라트는 81칸 전부 필수이므로 부분 입력으로 진행할 수 없다
  bool _canProceed(int step) {
    switch (step) {
      case 1:
        // 핵심 목표 필수
        return _coreGoalController.text.trim().isNotEmpty;
      case 2:
        // 세부 목표 8개 전부 필수
        return _subGoalControllers
            .every((c) => c.text.trim().isNotEmpty);
      case 3:
        // 실천 과제 64개 전부 필수
        for (int i = 0; i < _taskControllers.length; i++) {
          for (int j = 0; j < _taskControllers[i].length; j++) {
            if (_taskControllers[i][j].text.trim().isEmpty) return false;
          }
        }
        return true;
      default:
        return false;
    }
  }
}
