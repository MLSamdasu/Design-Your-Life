// F4 서브위젯: HabitPresetList - 프리셋 선택 목록
// HabitPresetSheet에서 분리된 1단계 프리셋 목록 위젯
import 'package:flutter/material.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/models/habit.dart';

/// 인기 습관 프리셋 목록 (단계 1)
class HabitPresetList extends StatelessWidget {
  /// 프리셋을 탭했을 때 호출되는 콜백
  final ValueChanged<HabitPreset> onPresetTap;

  const HabitPresetList({required this.onPresetTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('preset_list'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '인기 습관으로 시작하기',
          style: AppTypography.titleMd
              .copyWith(color: context.themeColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xl),
        // 프리셋이 많을 경우 화면 높이의 50%로 제한하여 오버플로우 방지
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                MiscLayout.bottomSheetContentMaxRatio,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: HabitPreset.presets.length,
            itemBuilder: (context, index) {
              final preset = HabitPreset.presets[index];
              return _PresetTile(
                preset: preset,
                onTap: () => onPresetTap(preset),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// 프리셋 목록의 개별 타일
class _PresetTile extends StatelessWidget {
  final HabitPreset preset;
  final VoidCallback onTap;

  const _PresetTile({required this.preset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.1),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
              color: context.themeColors.textPrimaryWithAlpha(0.15)),
        ),
        child: Row(
          children: [
            // emojiLg 토큰 사용 (22px 이모지 전용)
            Text(preset.icon, style: AppTypography.emojiLg),
            const SizedBox(width: AppSpacing.lg),
            // 긴 프리셋명 오버플로우 방지
            Expanded(
              child: Text(
                preset.name,
                style: AppTypography.bodyMd
                    .copyWith(color: context.themeColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: context.themeColors.textPrimaryWithAlpha(0.4),
              size: AppLayout.iconSm,
            ),
          ],
        ),
      ),
    );
  }
}
