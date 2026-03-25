// F8: 업적 달성 축하 다이얼로그 위젯 — 배럴 + 애니메이션 오케스트레이터
// ScaleTransition/FadeTransition 애니메이션을 제어하고 콘텐츠는 별도 위젯에 위임한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../models/achievement.dart';
import 'achievement_unlock_dialog_content.dart';

// 배럴 재export: 이 파일을 import하면 콘텐츠 위젯도 함께 사용 가능하다
export 'achievement_unlock_dialog_content.dart';

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
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.huge,
        vertical: AppSpacing.xxxl,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AchievementUnlockDialogContent(
            achievement: widget.achievement,
          ),
        ),
      ),
    );
  }
}
