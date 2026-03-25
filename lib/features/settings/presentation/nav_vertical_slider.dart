// F6: 설정 화면 - 네비게이션 바 수직 위치 슬라이더
// -1.0(상단) ~ 0.0(중앙) ~ 1.0(하단) 범위로 네비 레일 높낮이를 조절한다.
// SRP 분리: 수직 위치 슬라이더 관심사만 담당한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';

/// 네비 바 수직 위치 슬라이더
/// -1.0(상단) ~ 0.0(중앙) ~ 1.0(하단) 범위로 네비 레일 높낮이를 조절한다
class NavVerticalSlider extends ConsumerWidget {
  final double verticalPos;
  const NavVerticalSlider({super.key, required this.verticalPos});

  /// 슬라이더 값을 한국어 라벨로 변환한다
  String _posLabel(double value) {
    if (value <= -0.6) return '상단';
    if (value <= -0.2) return '중상단';
    if (value <= 0.2) return '중앙';
    if (value <= 0.6) return '중하단';
    return '하단';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.height_rounded,
              color: context.themeColors.textPrimary,
              size: AppLayout.iconXl,
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              '높낮이',
              style: AppTypography.bodyLg.copyWith(
                color: context.themeColors.textPrimary,
              ),
            ),
            const Spacer(),
            // 현재 위치를 텍스트로 표시한다
            Text(
              _posLabel(verticalPos),
              style: AppTypography.captionLg.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // 슬라이더: -1.0(상단) ~ 1.0(하단) 범위
        Row(
          children: [
            // 상단 라벨
            Text(
              '상',
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
                  value: verticalPos,
                  min: -1.0,
                  max: 1.0,
                  // 0.1 단위로 스냅하여 미세 조정을 지원한다
                  divisions: 20,
                  onChanged: (value) {
                    ref.read(navVerticalPosProvider.notifier).state = value;
                  },
                  // 드래그가 끝나면 Hive에 영속 저장한다
                  onChangeEnd: (value) {
                    ref.read(hiveCacheServiceProvider).saveSetting(
                      AppConstants.settingsKeyNavVerticalPos,
                      value,
                    );
                  },
                ),
              ),
            ),
            // 하단 라벨
            Text(
              '하',
              style: AppTypography.captionSm.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.4),
              ),
            ),
          ],
        ),
        // 초기화 버튼: 중앙으로 리셋
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              // 수직 위치를 중앙(0.0)으로 초기화한다
              ref.read(navVerticalPosProvider.notifier).state = 0.0;
              ref.read(hiveCacheServiceProvider).saveSetting(
                AppConstants.settingsKeyNavVerticalPos,
                0.0,
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '중앙으로 초기화',
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
