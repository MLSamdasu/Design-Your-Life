// F6: 설정 화면 - 네비게이션 바 위치 설정 카드
// 네비 바 좌/우 위치 전환 + 수직 높낮이 슬라이더 + 크기 슬라이더를 제공한다.
// SRP 분리: 네비게이션 설정 카드의 구성만 담당하며, 개별 위젯은 별도 파일에 분리한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../shared/widgets/glass_card.dart';
import 'nav_segment_toggle.dart';
import 'nav_size_slider.dart';
import 'nav_vertical_slider.dart';

/// 네비게이션 바 위치/높낮이 설정 카드
/// 좌/우 토글 + 수직 슬라이더로 네비 레일 위치를 실시간 조절한다
class SettingsNavCard extends ConsumerWidget {
  const SettingsNavCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLeft = ref.watch(navSideLeftProvider);
    final verticalPos = ref.watch(navVerticalPosProvider);
    final navSize = ref.watch(navSizeProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목
          Text(
            '네비게이션 바',
            style: AppTypography.titleMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 좌/우 위치 토글
          NavSideSelector(isLeft: isLeft),
          const SizedBox(height: AppSpacing.xl),

          // 수직 위치 슬라이더
          NavVerticalSlider(verticalPos: verticalPos),
          const SizedBox(height: AppSpacing.xl),

          // 네비 바 크기 슬라이더
          NavSizeSlider(navSize: navSize),
        ],
      ),
    );
  }
}
