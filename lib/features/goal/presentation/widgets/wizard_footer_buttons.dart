// F5 위젯: WizardFooter - 만다라트 위저드 하단 버튼 영역
// 이전/다음/다 채워줘/완료 버튼을 포함한다.
// 81칸 전부 필수이므로 '건너뛰기' 대신 '다 채워줘' 자동 채우기 버튼을 제공한다.
// SRP 분리: 위저드 하단 내비게이션 버튼 UI만 담당한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'wizard_filled_counter.dart';

/// 위저드 하단 버튼 영역
class WizardFooter extends StatelessWidget {
  final int step;
  final bool isSaving;
  final bool canProceed;
  final int filledCount;
  final int totalCount;
  final VoidCallback onBack;
  final VoidCallback onNext;
  /// 빈 칸 자동 채우기 (null이면 버튼 숨김)
  final VoidCallback? onAutoFill;

  const WizardFooter({
    required this.step,
    required this.isSaving,
    required this.canProceed,
    this.filledCount = 0,
    this.totalCount = 0,
    required this.onBack,
    required this.onNext,
    this.onAutoFill,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxxl, 0, AppSpacing.xxxl, AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 입력 진행 카운터 (2~3단계에서만 표시)
          if (step >= 2 && totalCount > 0) ...[
            WizardFilledCounter(
              filled: filledCount,
              total: totalCount,
              isComplete: canProceed,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Row(
            children: [
              // 이전 버튼 (1단계에서는 숨김)
              if (step > 1)
                TextButton(
                  onPressed: onBack,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lgXl,
                        horizontal: AppSpacing.xl),
                    foregroundColor:
                        context.themeColors.textPrimaryWithAlpha(0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded,
                          size: AppLayout.iconMd,
                          color: context.themeColors
                              .textPrimaryWithAlpha(0.6)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '이전',
                        style: AppTypography.titleMd.copyWith(
                          color: context.themeColors
                              .textPrimaryWithAlpha(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              // '다 채워줘' 자동 채우기 버튼 (빈 칸이 있을 때만 표시)
              if (onAutoFill != null) ...[
                TextButton(
                  onPressed: onAutoFill,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lgXl,
                        horizontal: AppSpacing.lg),
                    foregroundColor:
                        context.themeColors.accentWithAlpha(0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_fix_high_rounded,
                          size: AppLayout.iconMd,
                          color: context.themeColors
                              .accentWithAlpha(0.8)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '다 채워줘',
                        style: AppTypography.bodyMd.copyWith(
                          color: context.themeColors
                              .accentWithAlpha(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              // 다음/완료 버튼
              ElevatedButton(
                onPressed: (canProceed && !isSaving) ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorTokens.main,
                  foregroundColor: ColorTokens.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lgXl,
                      horizontal: AppSpacing.xxl),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  elevation: EffectLayout.elevationNone,
                  disabledBackgroundColor: ColorTokens.main
                      .withValues(alpha: AppAnimation.disabledAlpha),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: GoalLayout.spinnerSm,
                        height: GoalLayout.spinnerSm,
                        child: CircularProgressIndicator(
                          strokeWidth: GoalLayout.spinnerStrokeWidth,
                          color: ColorTokens.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            step < GoalLayout.wizardStepCount
                                ? '다음'
                                : '완료',
                            style: AppTypography.titleMd.copyWith(
                              color: ColorTokens.white,
                            ),
                          ),
                          if (step < GoalLayout.wizardStepCount) ...[
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(Icons.arrow_forward_rounded,
                                size: AppLayout.iconMd),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
