// 세로 네비게이션 개별 아이템 위젯
// 최소 터치 타겟 44x44px 보장 (WCAG 2.1 기준)
// 활성 상태: 아이콘 + 라벨 (강조 배경) / 비활성: 아이콘만 (페이드)
// navSize에 따라 아이콘 크기/패딩이 비례 스케일링된다
import 'package:flutter/material.dart';

import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// 세로 네비게이션 개별 아이템
/// 최소 터치 타겟 44x44px 보장 (WCAG 2.1 기준)
/// 활성 상태: 아이콘 + 라벨 (강조 배경) / 비활성: 아이콘만 (페이드)
/// navSize에 따라 아이콘 크기/패딩이 비례 스케일링된다
class SideNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;

  /// 부모 SideNavRail에서 전달받는 캡슐 너비
  final double navSize;

  const SideNavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.navSize,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    // navSize를 기본값(56px) 대비 비율로 환산하여 아이콘/패딩을 비례 스케일링한다
    final sizeRatio = navSize / AppLayout.sideNavWidth;
    final iconSize = AppLayout.iconNav * sizeRatio;
    // 아이템 너비: 캡슐 너비에서 좌우 패딩을 뺀 값
    final itemWidth = navSize - AppSpacing.md;

    // 접근성: 탭 이름 + 선택 상태를 스크린 리더에 전달한다
    return Semantics(
      label: '$label 탭',
      selected: isActive,
      button: true,
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppAnimation.standard,
          curve: Curves.easeInOutCubic,
          // 캡슐 내부 폭에 맞춘다 (navSize - 좌우 패딩)
          width: itemWidth,
          padding: EdgeInsets.symmetric(
            vertical: isActive
                ? AppSpacing.mdLg * sizeRatio
                : AppSpacing.md * sizeRatio,
          ),
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: isActive
                ? context.themeColors.textPrimaryWithAlpha(0.25)
                : ColorTokens.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘 (활성 시 풀 스케일, 비활성 시 축소)
              AnimatedScale(
                scale: isActive ? 1.0 : 0.85,
                duration: AppAnimation.normal,
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: context.themeColors.textPrimaryWithAlpha(
                      isActive ? 1.0 : 0.45),
                  size: iconSize,
                ),
              ),
              // 활성 탭만 라벨을 표시한다 (AnimatedSize로 부드럽게 전환)
              AnimatedSize(
                duration: AppAnimation.standard,
                curve: Curves.easeInOutCubic,
                child: isActive
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Text(
                          label,
                          // captionSm 토큰 사용 (네비게이션 라벨)
                          style: AppTypography.captionSm.copyWith(
                            color: context.themeColors.textPrimary,
                            fontWeight: AppTypography.weightSemiBold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
