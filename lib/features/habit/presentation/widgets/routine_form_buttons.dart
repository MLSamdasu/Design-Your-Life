// F4 위젯: RoutineFormButtons - 루틴 폼 버튼 컴포넌트
// RoutineTimeButton(시간 선택)과 RoutineSubmitButton(생성 완료)을 포함한다 (SRP 분리)
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 단일 시간 선택 버튼
class RoutineTimeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const RoutineTimeButton({required this.label, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.mdLg),
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.10),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: context.themeColors.textPrimaryWithAlpha(0.20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time_rounded,
                  size: AppLayout.iconSm, color: context.themeColors.textPrimaryWithAlpha(0.6)),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: AppTypography.bodyMd.copyWith(color: context.themeColors.textPrimary)),
            ],
          ),
        ),
      );
}

/// 루틴 생성 완료 버튼
class RoutineSubmitButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const RoutineSubmitButton({required this.enabled, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          height: AppLayout.formButtonHeight,
          decoration: BoxDecoration(
            color: enabled ? ColorTokens.main : context.themeColors.textPrimaryWithAlpha(0.12),
            borderRadius: BorderRadius.circular(AppRadius.xlLg),
            boxShadow: enabled
                ? [BoxShadow(color: ColorTokens.main.withValues(alpha: 0.4),
                    blurRadius: EffectLayout.shadowBlurMd, offset: const Offset(0, EffectLayout.shadowOffsetSm))]
                : null,
          ),
          child: Center(
            child: Text('루틴 만들기',
              style: AppTypography.titleMd.copyWith(
                // MAIN 컬러 배경(#7C3AED) 위이므로 활성 시 흰색이 적절하다
                color: enabled ? ColorTokens.white : context.themeColors.textPrimaryWithAlpha(0.35))),
          ),
        ),
      );
}
