// F8: 업적 카드 위젯
// 잠금(grey, opacity 0.4) / 달성(colorful, glow) 두 가지 상태를 지원한다.
// 달성 카드는 MAIN 컬러 글로우 효과를 적용한다.
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../models/achievement_definition.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 업적 배지 카드 위젯
/// 달성 여부에 따라 시각적으로 달라지는 카드를 표시한다
class AchievementCard extends StatelessWidget {
  /// 업적 정의 (표시할 내용)
  final AchievementDef def;

  /// 달성 여부 (false면 잠금 상태)
  final bool isUnlocked;

  const AchievementCard({
    super.key,
    required this.def,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return isUnlocked ? _buildUnlockedCard(context) : _buildLockedCard(context);
  }

  /// 달성된 업적 카드 (컬러풀, 글로우 효과)
  Widget _buildUnlockedCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: GlassDecoration.subtleBlurSigma, sigmaY: GlassDecoration.subtleBlurSigma),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lgXl),
          decoration: BoxDecoration(
            // 달성 카드: 배경 테마에 맞는 악센트 컬러 배경 + 보더
            color: context.themeColors.accentWithAlpha(0.20),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: context.themeColors.accentWithAlpha(0.50),
              width: AppLayout.borderMedium,
            ),
            boxShadow: [
              // 악센트 컬러 글로우 효과
              BoxShadow(
                color: context.themeColors.accentWithAlpha(0.25),
                blurRadius: EffectLayout.ctaShadowBlur,
                offset: const Offset(0, EffectLayout.ctaShadowOffsetY),
              ),
            ],
          ),
          child: _buildCardContent(context, isUnlocked: true),
        ),
      ),
    );
  }

  /// 잠금된 업적 카드 (회색, 반투명)
  Widget _buildLockedCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: GlassDecoration.subtleBlurSigma, sigmaY: GlassDecoration.subtleBlurSigma),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lgXl),
          decoration: BoxDecoration(
            // 잠금 카드: gray600 배경, opacity 0.4
            color: ColorTokens.gray600.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: context.themeColors.textPrimaryWithAlpha(0.10),
              width: AppLayout.borderThin,
            ),
          ),
          child: _buildCardContent(context, isUnlocked: false),
        ),
      ),
    );
  }

  /// 카드 내부 콘텐츠 (이모지 + 제목 + 설명 + XP)
  Widget _buildCardContent(BuildContext context, {required bool isUnlocked}) {
    // 잠금 상태면 이모지를 흑백 처리하기 위해 opacity를 낮춘다
    final iconOpacity = isUnlocked ? 1.0 : 0.35;
    final titleColor = isUnlocked ? context.themeColors.textPrimary : context.themeColors.textPrimaryWithAlpha(0.45);
    // 잠금 상태 설명 텍스트: WCAG 최소 대비 0.45 보장 (비활성 텍스트)
    final descColor = isUnlocked
        ? context.themeColors.textPrimaryWithAlpha(0.70)
        : context.themeColors.textPrimaryWithAlpha(0.45);
    // 잠금 상태 XP 텍스트/아이콘: WCAG 최소 대비 0.45 보장 (비활성 텍스트)
    final xpColor = isUnlocked ? context.themeColors.accent : context.themeColors.textPrimaryWithAlpha(0.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 이모지 아이콘
        Opacity(
          opacity: iconOpacity,
          child: Text(
            def.iconName,
            style: AppTypography.emojiLg.copyWith(fontSize: MiscLayout.emojiBadgeLg),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 업적 제목
        Text(
          def.title,
          style: AppTypography.titleMd.copyWith(
            color: titleColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),

        // 업적 설명
        Text(
          def.description,
          style: AppTypography.captionMd.copyWith(
            color: descColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.md),

        // XP 보상 표시
        Row(
          children: [
            Icon(
              Icons.bolt_rounded,
              size: AppLayout.iconXxxs,
              color: xpColor,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              '+${def.xpReward} XP',
              style: AppTypography.captionLg.copyWith(
                color: xpColor,
                fontWeight: AppTypography.weightBold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
