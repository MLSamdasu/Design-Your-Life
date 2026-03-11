// F6: 설정 화면 테마 선택 카드
// 4가지 테마 프리셋을 시각적 미리보기 카드로 표시한다.
// 선택 시 themePresetProvider를 업데이트하고 Hive에 영속 저장한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/theme_preset.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../shared/widgets/glass_card.dart';
import 'theme_preview_card.dart';
import '../../../core/theme/spacing_tokens.dart';

/// 설정 화면 테마 선택 카드
/// 2x2 그리드로 4개의 프리셋 미리보기를 표시하고 선택을 처리한다
class SettingsThemeCard extends ConsumerWidget {
  const SettingsThemeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 현재 선택된 프리셋을 구독한다
    final currentPreset = ref.watch(themePresetProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 타이틀
          Text(
            '테마 선택',
            style: AppTypography.titleMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // 섹션 설명
          Text(
            '앱의 시각적 스타일을 변경합니다',
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 3x2 그리드: 6개의 테마 프리셋 미리보기
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            // GridView 내부 스크롤 비활성화 (SingleChildScrollView와 충돌 방지)
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            // 미리보기 카드의 가로:세로 비율 (가로가 더 넓은 카드 형태)
            childAspectRatio: 1.2,
            children: ThemePreset.values.map((preset) {
              return ThemePreviewCard(
                preset: preset,
                isSelected: preset == currentPreset,
                onTap: () {
                  // 프리셋 상태를 업데이트하고 Hive에 영속 저장한다
                  ref.read(themePresetProvider.notifier).state = preset;
                  ref
                      .read(hiveCacheServiceProvider)
                      .saveSetting('themePreset', preset.name);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
