// F4 위젯: HabitPresetSheet - 인기 습관 프리셋 선택 바텀 시트
// 미리 정의된 5개 인기 습관 중 선택하여 빠르게 습관을 등록한다.
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/habit.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';


/// 인기 습관 프리셋 선택 바텀 시트
class HabitPresetSheet extends StatelessWidget {
  final ValueChanged<HabitPreset> onSelected;

  const HabitPresetSheet({required this.onSelected, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.15),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: context.themeColors.textPrimaryWithAlpha(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '인기 습관으로 시작하기',
                style: AppTypography.titleMd.copyWith(color: context.themeColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xl),
              // 프리셋이 많을 경우 화면 높이의 50%로 제한하여 오버플로우 방지
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: HabitPreset.presets.length,
                  itemBuilder: (context, index) {
                    final preset = HabitPreset.presets[index];
                    return GestureDetector(
                      onTap: () => onSelected(preset),
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
                            Text(preset.icon,
                                style: AppTypography.emojiLg),
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
                              Icons.add_circle_outline_rounded,
                              color: context.themeColors.textPrimaryWithAlpha(0.6),
                              size: AppLayout.iconXl,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
