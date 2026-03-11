// F5 위젯: WizardFooter - 만다라트 위저드 하단 버튼 영역
// 이전/다음/건너뛰기/완료 버튼을 포함한다.
// SRP: 위저드 하단 내비게이션 버튼 UI만 담당한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 위저드 하단 버튼 영역
class WizardFooter extends StatelessWidget {
  final int step;
  final bool isSaving;
  final bool canProceed;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback? onSkip;

  const WizardFooter({
    required this.step,
    required this.isSaving,
    required this.canProceed,
    required this.onBack,
    required this.onNext,
    this.onSkip,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          // 이전 버튼 (1단계에서는 숨김)
          if (step > 1)
            TextButton(
              onPressed: onBack,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lgXl, horizontal: AppSpacing.xl),
                foregroundColor: context.themeColors.textPrimaryWithAlpha(0.6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded,
                      size: AppLayout.iconMd, color: context.themeColors.textPrimaryWithAlpha(0.6)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '이전',
                    style: AppTypography.titleMd.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.6),
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // 건너뛰기 버튼 (2~3단계)
          if (onSkip != null)
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lgXl, horizontal: AppSpacing.lg),
                foregroundColor: context.themeColors.textPrimaryWithAlpha(0.5),
              ),
              child: Text(
                '건너뛰기',
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.5),
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.md),
          // 다음/완료 버튼
          ElevatedButton(
            onPressed: (canProceed && !isSaving) ? onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorTokens.main,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.lgXl, horizontal: AppSpacing.xxl),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              elevation: 0,
              disabledBackgroundColor:
                  ColorTokens.main.withValues(alpha: 0.4),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        step < 3 ? '다음' : '완료',
                        style: AppTypography.titleMd.copyWith(
                          // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
                          color: Colors.white,
                        ),
                      ),
                      if (step < 3) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.arrow_forward_rounded, size: AppLayout.iconMd),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
