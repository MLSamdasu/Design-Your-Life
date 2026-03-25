// F6: 설정 화면 - 네비게이션 바 크기 슬라이더
// sideNavWidthMin(48px) ~ sideNavWidthMax(80px) 범위로 캡슐 너비를 조절한다.
// SRP 분리: 네비 바 크기 슬라이더 관심사만 담당한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';

/// 네비 바 크기 슬라이더
/// sideNavWidthMin(48px) ~ sideNavWidthMax(80px) 범위로 캡슐 너비를 조절한다
/// 아이콘/패딩도 비례 스케일링되어 자연스러운 크기 변화를 제공한다
class NavSizeSlider extends ConsumerWidget {
  final double navSize;
  const NavSizeSlider({super.key, required this.navSize});

  /// 슬라이더 값을 한국어 크기 라벨로 변환한다
  String _sizeLabel(double value) {
    if (value <= 52) return '작게';
    if (value <= 60) return '보통';
    if (value <= 70) return '크게';
    return '최대';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.aspect_ratio_rounded,
              color: context.themeColors.textPrimary,
              size: AppLayout.iconXl,
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              '크기',
              style: AppTypography.bodyLg.copyWith(
                color: context.themeColors.textPrimary,
              ),
            ),
            const Spacer(),
            // 현재 크기를 텍스트로 표시한다
            Text(
              _sizeLabel(navSize),
              style: AppTypography.captionLg.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // 슬라이더: 48px(작게) ~ 80px(최대) 범위
        Row(
          children: [
            // 최소 라벨
            Text(
              '소',
              style: AppTypography.captionSm.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.4),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  // 테마 인식 슬라이더 색상
                  activeTrackColor: context.themeColors.accentWithAlpha(0.5),
                  inactiveTrackColor:
                      context.themeColors.textPrimaryWithAlpha(0.12),
                  thumbColor: context.themeColors.accent,
                  overlayColor: context.themeColors.accentWithAlpha(0.15),
                  trackHeight: AppSpacing.xxs,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: Slider(
                  value: navSize,
                  min: AppLayout.sideNavWidthMin,
                  max: AppLayout.sideNavWidthMax,
                  // 4px 단위로 스냅한다 (48, 52, 56, 60, 64, 68, 72, 76, 80)
                  divisions: 8,
                  onChanged: (value) {
                    ref.read(navSizeProvider.notifier).state = value;
                  },
                  // 드래그가 끝나면 Hive에 영속 저장한다
                  onChangeEnd: (value) {
                    ref.read(hiveCacheServiceProvider).saveSetting(
                      AppConstants.settingsKeyNavSize,
                      value,
                    );
                  },
                ),
              ),
            ),
            // 최대 라벨
            Text(
              '대',
              style: AppTypography.captionSm.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.4),
              ),
            ),
          ],
        ),
        // 초기화 버튼: 기본 크기로 리셋
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              // 기본 크기(56px)로 초기화한다
              ref.read(navSizeProvider.notifier).state = AppLayout.sideNavWidth;
              ref.read(hiveCacheServiceProvider).saveSetting(
                AppConstants.settingsKeyNavSize,
                AppLayout.sideNavWidth,
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '기본 크기로 초기화',
                style: AppTypography.captionMd.copyWith(
                  color: context.themeColors.accentWithAlpha(0.7),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
