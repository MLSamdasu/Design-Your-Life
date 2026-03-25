// F6: 로그인 유도 타일 위젯
// 미로그인 상태에서 Google Drive 백업을 위한 로그인을 안내한다
import 'package:flutter/material.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 미로그인 상태에서 로그인을 유도하는 타일
class LoginPromptTile extends StatelessWidget {
  final VoidCallback onTap;

  const LoginPromptTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.themeColors.accentWithAlpha(0.08),
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          border: Border.all(
            color: context.themeColors.accentWithAlpha(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: AppLayout.iconXl,
              color: context.themeColors.accentWithAlpha(0.8),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '로그인하여 백업 활성화',
                    style: AppTypography.bodyLg.copyWith(
                      color: context.themeColors.accent,
                      fontWeight: AppTypography.weightSemiBold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '로그인하면 데이터를 Google Drive에 안전하게 보관할 수 있습니다',
                    style: AppTypography.captionMd.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.themeColors.accentWithAlpha(0.6),
              size: AppLayout.iconLg,
            ),
          ],
        ),
      ),
    );
  }
}
