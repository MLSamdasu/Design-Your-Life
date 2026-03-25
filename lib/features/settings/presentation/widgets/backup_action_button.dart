// F6: 백업/복원 액션 버튼 위젯
// 백업하기 또는 복원하기 등의 액션을 제공하는 공통 버튼이다
// isOutlined가 true이면 아웃라인 스타일, false이면 채워진 스타일로 표시한다
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 백업/복원 액션 버튼
class BackupActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final bool isOutlined;
  final VoidCallback? onTap;

  const BackupActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isLoading,
    this.isOutlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.mdLg,
          horizontal: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isOutlined
              ? ColorTokens.transparent
              : isDisabled
                  ? context.themeColors.accentWithAlpha(0.4)
                  : context.themeColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          border: isOutlined
              ? Border.all(
                  color: isDisabled
                      ? context.themeColors.textPrimaryWithAlpha(0.2)
                      : context.themeColors.accent,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: AppLayout.iconMd,
                height: AppLayout.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: GoalLayout.spinnerStrokeWidth,
                  // 채워진 버튼: 항상 흰색, 아웃라인 버튼: 테마 악센트
                  color: isOutlined
                      ? context.themeColors.accent
                      : ColorTokens.white,
                ),
              )
            else
              Icon(
                icon,
                size: AppLayout.iconMd,
                // WCAG: 비활성 아이콘 알파 0.45 이상으로 가독성 보장
                color: isOutlined
                    ? isDisabled
                        ? context.themeColors.textPrimaryWithAlpha(0.45)
                        : context.themeColors.accent
                    : ColorTokens.white,
              ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.bodySm.copyWith(
                // WCAG: 비활성 텍스트 알파 0.45 이상으로 가독성 보장
                color: isOutlined
                    ? isDisabled
                        ? context.themeColors.textPrimaryWithAlpha(0.45)
                        : context.themeColors.accent
                    : ColorTokens.white,
                fontWeight: AppTypography.weightSemiBold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
