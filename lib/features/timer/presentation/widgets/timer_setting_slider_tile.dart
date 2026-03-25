// F6: 타이머 설정 슬라이더 타일 위젯
// 라벨 + 아이콘 + 현재값 뱃지 + 슬라이더를 하나의 행으로 제공한다.
// timer_settings_sheet.dart에서 각 설정 항목에 사용된다.
import 'package:flutter/material.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// 슬라이더가 포함된 설정 항목 타일
/// 라벨 + 아이콘 + 현재값 표시 + 슬라이더를 제공한다
class TimerSettingSliderTile extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final void Function(int) onChanged;

  const TimerSettingSliderTile({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 슬라이더의 divisions 수 계산 (범위 / 단위)
    final divisions = (max - min) ~/ step;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨 + 현재값 표시 행
        _buildLabelRow(context),

        const SizedBox(height: AppSpacing.sm),

        // 슬라이더
        _buildSlider(context, divisions),
      ],
    );
  }

  /// 아이콘 + 라벨 + 현재값 뱃지를 한 행에 배치한다
  Widget _buildLabelRow(BuildContext context) {
    return Row(
      children: [
        // 카테고리 아이콘
        Container(
          width: AppLayout.containerMd,
          height: AppLayout.containerMd,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: iconColor, size: AppLayout.iconSm),
        ),
        const SizedBox(width: AppSpacing.md),
        // 라벨
        Text(
          label,
          style: AppTypography.bodyLg.copyWith(
            color: context.themeColors.textPrimary,
            fontWeight: AppTypography.weightMedium,
          ),
        ),
        const Spacer(),
        // 현재값 뱃지
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.mdLg,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: context.themeColors.accentWithAlpha(0.15),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Text(
            '$value$unit',
            style: AppTypography.bodyMd.copyWith(
              color: context.themeColors.accent,
              fontWeight: AppTypography.weightSemiBold,
            ),
          ),
        ),
      ],
    );
  }

  /// 테마 적용된 슬라이더를 생성한다
  Widget _buildSlider(BuildContext context, int divisions) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: context.themeColors.accent,
        inactiveTrackColor: context.themeColors.textPrimaryWithAlpha(0.15),
        thumbColor: context.themeColors.accent,
        overlayColor: context.themeColors.accentWithAlpha(0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      child: Slider(
        value: value.toDouble(),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: divisions,
        onChanged: (val) {
          // step 단위로 반올림하여 정수 값으로 전달한다
          final stepped = (val / step).round() * step;
          onChanged(stepped.clamp(min, max));
        },
      ),
    );
  }
}
