// F6: 튜토리얼 보기 카드
// 앱 사용법 안내(5탭 온보딩 가이드)를 설정에서 다시 볼 수 있도록 제공한다.
// settings_screen.dart에서 SRP 분리하여 200줄 제한을 준수한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/providers/tutorial_provider.dart';

/// 튜토리얼 보기 카드
/// 앱 사용법 안내(5탭 온보딩 가이드)를 설정에서 다시 볼 수 있도록 제공한다
/// 탭 시 showTutorialProvider를 true로 변경하고, 설정 모달을 닫아 MainShell 튜토리얼을 표시한다
class SettingsTutorialCard extends ConsumerWidget {
  const SettingsTutorialCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: GestureDetector(
        onTap: () {
          // 튜토리얼 표시 요청
          ref.read(showTutorialProvider.notifier).state = true;
          // 설정 모달을 닫아야 MainShell의 튜토리얼 오버레이가 표시된다
          Navigator.of(context).pop();
        },
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Icon(
              Icons.school_outlined,
              color: context.themeColors.accent,
              size: AppLayout.iconXl,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '튜토리얼 보기',
                    style: AppTypography.bodyLg.copyWith(
                      color: context.themeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '앱 사용법 안내를 다시 볼 수 있어요',
                    style: AppTypography.captionMd.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.themeColors.textPrimaryWithAlpha(0.5),
              size: AppLayout.iconLg,
            ),
          ],
        ),
      ),
    );
  }
}
