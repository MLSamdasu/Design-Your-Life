// F8: 업적 달성 축하 다이얼로그 — 내부 콘텐츠 위젯
// GlassCard 스타일에 이모지, 제목, 설명, XP 보상, 확인 버튼을 배치한다.
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../models/achievement.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 업적 달성 다이얼로그 내부 콘텐츠
/// 글래스모피즘 카드 안에 이모지, 제목, 설명, XP 보상, 확인 버튼을 배치한다
class AchievementUnlockDialogContent extends StatelessWidget {
  final Achievement achievement;

  const AchievementUnlockDialogContent({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassDecoration.elevatedBlurSigma,
          sigmaY: GlassDecoration.elevatedBlurSigma,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          decoration: GlassDecoration.modal(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 축하 헤더
              Text(
                '🎉 축하합니다!',
                style: AppTypography.headingSm.copyWith(
                  color: context.themeColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 업적 이모지 (크게 표시, 배경 테마에 맞는 악센트 색상 원형 배경)
              _buildEmojiBadge(context),
              const SizedBox(height: AppSpacing.xl),

              // 업적 제목
              Text(
                achievement.title,
                style: AppTypography.titleLg.copyWith(
                  color: context.themeColors.textPrimary,
                  fontWeight: AppTypography.weightBold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // 업적 설명
              Text(
                achievement.description,
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.70),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // XP 보상 표시
              _buildXpRewardBadge(context),
              const SizedBox(height: AppSpacing.xxxl),

              // 확인 버튼
              _buildConfirmButton(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 업적 이모지를 악센트 색상 원형 배경 위에 표시한다
  Widget _buildEmojiBadge(BuildContext context) {
    return Container(
      width: AppLayout.containerXl,
      height: AppLayout.containerXl,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.themeColors.accent,
            context.themeColors.accentWithAlpha(0.75),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: context.themeColors.accentWithAlpha(0.40),
            blurRadius: EffectLayout.shadowBlurLg,
            offset: const Offset(0, EffectLayout.shadowOffsetMd),
          ),
        ],
      ),
      child: Center(
        child: Text(
          achievement.iconName,
          style: TextStyle(fontSize: MiscLayout.emojiDialogXl),
        ),
      ),
    );
  }

  /// XP 보상을 배경 테마에 맞는 악센트 색상으로 표시한다
  Widget _buildXpRewardBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.themeColors.accentWithAlpha(0.25),
        borderRadius: BorderRadius.circular(AppRadius.circle),
        border: Border.all(
          color: context.themeColors.accentWithAlpha(0.50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: AppLayout.iconMd,
            color: context.themeColors.accent,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '+${achievement.xpReward} XP 획득!',
            style: AppTypography.titleMd.copyWith(
              color: context.themeColors.accent,
              fontWeight: AppTypography.weightBold,
            ),
          ),
        ],
      ),
    );
  }

  /// MAIN 컬러 배경(#7C3AED) 확인 버튼
  Widget _buildConfirmButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lgXl),
        decoration: BoxDecoration(
          color: ColorTokens.main,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.main.withValues(alpha: 0.30),
              blurRadius: EffectLayout.ctaShadowBlur,
              offset: const Offset(0, EffectLayout.ctaShadowOffsetY),
            ),
          ],
        ),
        child: Text(
          '확인',
          style: AppTypography.titleMd.copyWith(
            // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
            color: ColorTokens.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
