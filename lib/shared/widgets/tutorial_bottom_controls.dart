// 튜토리얼 하단 컨트롤 영역 위젯
// 단계 인디케이터 도트 + 이전/다음 버튼을 조합하여 렌더링한다.
// SRP 분리: 하단 컨트롤 영역 레이아웃만 담당한다.
import 'package:flutter/material.dart';

import '../../core/theme/spacing_tokens.dart';
import 'tutorial_button.dart';
import 'tutorial_step_dots.dart';

/// 튜토리얼 하단 컨트롤 영역
/// 도트 인디케이터와 이전/다음(또는 시작하기) 버튼을 포함한다
class TutorialBottomControls extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isFirstStep;
  final bool isLastStep;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const TutorialBottomControls({
    required this.currentStep,
    required this.totalSteps,
    required this.isFirstStep,
    required this.isLastStep,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        0,
        AppSpacing.xxxl,
        AppSpacing.huge,
      ),
      child: Column(
        children: [
          // 단계 인디케이터 (도트)
          TutorialStepDots(
            currentStep: currentStep,
            totalSteps: totalSteps,
          ),
          const SizedBox(height: AppSpacing.xxl),
          // 버튼 행
          Row(
            children: [
              // 이전 버튼
              if (!isFirstStep)
                Expanded(
                  child: TutorialButton(
                    label: '이전',
                    icon: Icons.arrow_back_rounded,
                    iconLeft: true,
                    isOutlined: true,
                    onTap: onBack,
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: AppSpacing.lg),
              // 다음 / 시작하기 버튼
              Expanded(
                child: TutorialButton(
                  label: isLastStep ? '시작하기' : '다음',
                  icon: isLastStep
                      ? Icons.rocket_launch_rounded
                      : Icons.arrow_forward_rounded,
                  iconLeft: false,
                  isOutlined: false,
                  onTap: onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
