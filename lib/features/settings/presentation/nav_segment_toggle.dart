// F6: 설정 화면 - 네비게이션 바 좌/우 위치 선택 위젯
// 세그먼트 토글 UI를 통해 네비 바의 좌/우 위치를 전환한다.
// SRP 분리: 세그먼트 토글 관심사만 담당한다.
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

/// 네비 바 좌/우 위치 선택 (세그먼트 버튼)
class NavSideSelector extends ConsumerWidget {
  final bool isLeft;
  const NavSideSelector({super.key, required this.isLeft});

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
        SegmentToggle(
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
class SegmentToggle extends StatelessWidget {
  final bool isLeft;
  final ValueChanged<bool> onChanged;

  const SegmentToggle({
    super.key,
    required this.isLeft,
    required this.onChanged,
  });

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
          SegmentItem(
            label: '왼쪽',
            icon: Icons.align_horizontal_left_rounded,
            isSelected: isLeft,
            onTap: () => onChanged(true),
          ),
          SegmentItem(
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
class SegmentItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const SegmentItem({
    super.key,
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
