// 공용 위젯: HabitPillCheckbox (습관 원형 체크박스)
// HabitPill에서 사용하는 원형 체크박스 + 스케일 바운스 애니메이션 (SRP 분리)
// design-system.md 14.2절 습관 체크(원형) 스펙 참조
import 'package:flutter/material.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';

/// 습관 필 원형 체크박스 위젯
/// AnimationController를 외부에서 받아 스케일 바운스를 적용한다
class HabitPillCheckbox extends StatelessWidget {
  final String habitName;
  final bool isCompleted;
  final AnimationController controller;
  final VoidCallback? onToggle;

  const HabitPillCheckbox({
    required this.habitName,
    required this.isCompleted,
    required this.controller,
    this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 접근성: Semantics + 최소 44x44px 터치 타겟
    return Semantics(
      label: '$habitName 습관 완료 토글',
      checked: isCompleted,
      button: true,
      child: SizedBox(
        width: AppLayout.minTouchTarget,
        height: AppLayout.minTouchTarget,
        child: GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final value = controller.value;
                // Scale bounce: 1.0 -> 0.85 -> 1.15 -> 1.0
                final scale = value > 0
                    ? 1.0 + (value * 0.15).clamp(-0.15, 0.15) * (1 - value)
                    : 1.0;
                return Transform.scale(
                  scale: scale.clamp(0.85, 1.15),
                  child: AnimatedContainer(
                    duration: AppAnimation.normal,
                    width: AppLayout.iconNav,
                    height: AppLayout.iconNav,
                    decoration: BoxDecoration(
                      // 완료: habitCheck 토큰 기반 초록 배경
                      color: isCompleted
                          ? ColorTokens.habitCheck.withValues(alpha: 0.40)
                          : ColorTokens.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted
                            ? ColorTokens.habitCheck.withValues(alpha: 0.60)
                            : context.themeColors.textPrimaryWithAlpha(0.30),
                        width: AppLayout.borderThick,
                      ),
                    ),
                    // 체크 아이콘: habitCheck 배경이 alpha 0.40이므로
                    // 라이트 테마에서 흰색이 안 보인다. 테마 인식 색상 사용
                    child: isCompleted
                        ? Icon(Icons.check, color: context.themeColors.textPrimary, size: AppSpacing.lg)
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
