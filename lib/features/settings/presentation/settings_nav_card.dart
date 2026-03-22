// F6: 설정 화면 - 네비게이션 바 위치 설정 카드
// 네비 바 좌/우 위치 전환 + 수직 높낮이 슬라이더를 제공한다.
// SRP: 네비게이션 설정 관심사를 별도 파일로 분리한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../shared/widgets/glass_card.dart';

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
          _NavSideSelector(isLeft: isLeft),
          const SizedBox(height: AppSpacing.xl),

          // 수직 위치 슬라이더
          _NavVerticalSlider(verticalPos: verticalPos),
          const SizedBox(height: AppSpacing.xl),

          // 네비 바 크기 슬라이더
          _NavSizeSlider(navSize: navSize),
        ],
      ),
    );
  }
}

/// 네비 바 좌/우 위치 선택 (세그먼트 버튼)
class _NavSideSelector extends ConsumerWidget {
  final bool isLeft;
  const _NavSideSelector({required this.isLeft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Icon(
          Icons.swap_horiz_rounded,
          color: context.themeColors.textPrimary,
          size: AppLayout.iconXl,
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(
            '위치',
            style: AppTypography.bodyLg.copyWith(
              color: context.themeColors.textPrimary,
            ),
          ),
        ),
        // 좌/우 세그먼트 토글
        _SegmentToggle(
          isLeft: isLeft,
          onChanged: (value) {
            ref.read(navSideLeftProvider.notifier).state = value;
            // Hive에 영속 저장한다
            ref.read(hiveCacheServiceProvider).saveSetting(
              AppConstants.settingsKeyNavSide,
              value ? 'left' : 'right',
            );
          },
        ),
      ],
    );
  }
}

/// 좌/우 세그먼트 토글 위젯
/// 두 옵션 중 하나를 선택하는 작은 토글 UI
class _SegmentToggle extends StatelessWidget {
  final bool isLeft;
  final ValueChanged<bool> onChanged;

  const _SegmentToggle({required this.isLeft, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeColors.textPrimaryWithAlpha(0.08),
        borderRadius: BorderRadius.circular(AppRadius.huge),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentItem(
            label: '왼쪽',
            icon: Icons.align_horizontal_left_rounded,
            isSelected: isLeft,
            onTap: () => onChanged(true),
          ),
          _SegmentItem(
            label: '오른쪽',
            icon: Icons.align_horizontal_right_rounded,
            isSelected: !isLeft,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

/// 세그먼트 토글 개별 아이템
class _SegmentItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.standard,
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          // 선택된 세그먼트에 악센트 색상 배경을 적용한다
          color: isSelected
              ? context.themeColors.accentWithAlpha(0.3)
              : ColorTokens.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: isSelected
              ? Border.all(color: context.themeColors.accentWithAlpha(0.5))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppLayout.iconSm,
              color: isSelected
                  ? context.themeColors.textPrimary
                  : context.themeColors.textPrimaryWithAlpha(0.45),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.captionLg.copyWith(
                color: isSelected
                    ? context.themeColors.textPrimary
                    : context.themeColors.textPrimaryWithAlpha(0.45),
                fontWeight: isSelected
                    ? AppTypography.weightSemiBold
                    : AppTypography.weightRegular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 네비 바 수직 위치 슬라이더
/// -1.0(상단) ~ 0.0(중앙) ~ 1.0(하단) 범위로 네비 레일 높낮이를 조절한다
class _NavVerticalSlider extends ConsumerWidget {
  final double verticalPos;
  const _NavVerticalSlider({required this.verticalPos});

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

/// 네비 바 크기 슬라이더
/// sideNavWidthMin(48px) ~ sideNavWidthMax(80px) 범위로 캡슐 너비를 조절한다
/// 아이콘/패딩도 비례 스케일링되어 자연스러운 크기 변화를 제공한다
class _NavSizeSlider extends ConsumerWidget {
  final double navSize;
  const _NavSizeSlider({required this.navSize});

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
