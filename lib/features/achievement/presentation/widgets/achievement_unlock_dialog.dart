// F8: 업적 달성 축하 다이얼로그 위젯
// 업적을 새로 달성했을 때 ScaleTransition 애니메이션으로 표시한다.
// GlassCard 스타일에 이모지, 제목, 설명, XP 보상을 보여준다.
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../models/achievement.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 업적 달성 축하 다이얼로그
/// [achievement]를 달성했을 때 ScaleTransition 애니메이션과 함께 표시한다
class AchievementUnlockDialog extends StatefulWidget {
  final Achievement achievement;

  const AchievementUnlockDialog({
    super.key,
    required this.achievement,
  });

  /// [achievement] 달성 축하 다이얼로그를 표시하는 정적 헬퍼
  static Future<void> show(BuildContext context, Achievement achievement) {
    return showDialog<void>(
      context: context,
      barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.60),
      builder: (_) => AchievementUnlockDialog(achievement: achievement),
    );
  }

  @override
  State<AchievementUnlockDialog> createState() =>
      _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<AchievementUnlockDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ScaleTransition: 0.6 → 1.0, 350ms EaseOutBack
    _controller = AnimationController(
      duration: AppAnimation.slow,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // 다이얼로그 진입 시 애니메이션 실행
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorTokens.transparent,
      // 기본 Dialog 패딩 제거
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.huge, vertical: AppSpacing.xxxl),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: _buildContent(),
        ),
      ),
    );
  }

  /// 다이얼로그 내부 콘텐츠
  Widget _buildContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassDecoration.elevatedBlurSigma,
          sigmaY: GlassDecoration.elevatedBlurSigma,
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
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
              Container(
                width: 80,
                height: 80,
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
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.achievement.iconName,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 업적 제목
              Text(
                widget.achievement.title,
                style: AppTypography.titleLg.copyWith(
                    color: context.themeColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // 업적 설명
              Text(
                widget.achievement.description,
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.70),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // XP 보상 표시: 배경 테마에 맞는 악센트 색상으로 표시한다
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
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
                      '+${widget.achievement.xpReward} XP 획득!',
                      style: AppTypography.titleMd.copyWith(
                        color: context.themeColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // 확인 버튼
              GestureDetector(
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
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '확인',
                    style: AppTypography.titleMd.copyWith(
                      // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
