// 튜토리얼 정보 카드 위젯
// 현재 단계의 탭 아이콘, 이름, 설명, 기능 목록을 카드 형태로 표시한다.
// SRP 분리: 튜토리얼 카드 UI 렌더링만 담당한다.
import 'package:flutter/material.dart';

import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/typography_tokens.dart';
import 'tutorial_animated_icon.dart';
import 'tutorial_tab_info.dart';

/// 튜토리얼 탭 정보 카드
/// 아이콘 + 탭명 + 설명 + 기능 목록을 표시한다
class TutorialCard extends StatelessWidget {
  final TutorialTabInfo tabInfo;
  final int stepIndex;
  final int totalSteps;

  const TutorialCard({
    required this.tabInfo,
    required this.stepIndex,
    required this.totalSteps,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: AppLayout.dialogMaxWidthLg),
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      decoration: BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: ColorTokens.white.withValues(alpha: 0.2),
          width: AppLayout.borderThin,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 탭 아이콘 (원형 배경 + 글로우 펄스)
          TutorialAnimatedIcon(icon: tabInfo.icon, stepIndex: stepIndex),
          const SizedBox(height: AppSpacing.xl),
          // 단계 표시 텍스트
          Text(
            '${stepIndex + 1} / $totalSteps',
            style: AppTypography.captionLg.copyWith(
              color: ColorTokens.mainLight.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // 탭 이름
          Text(
            tabInfo.title,
            style: AppTypography.headingLg.copyWith(
              color: ColorTokens.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // 부제
          Text(
            tabInfo.subtitle,
            style: AppTypography.titleMd.copyWith(
              color: ColorTokens.mainLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // 설명
          Text(
            tabInfo.description,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: ColorTokens.white.withValues(alpha: 0.75),
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // 기능 목록
          ...tabInfo.features.map((feature) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: AppLayout.iconMd,
                    height: AppLayout.iconMd,
                    decoration: BoxDecoration(
                      color: ColorTokens.mainLight.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: AppLayout.iconXxs,
                      color: ColorTokens.mainLight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      feature,
                      style: AppTypography.bodySm.copyWith(
                        color: ColorTokens.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
