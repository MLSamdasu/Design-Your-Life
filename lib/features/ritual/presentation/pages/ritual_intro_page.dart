// 데일리 리추얼 Page 1: 인트로 페이지
// Warren Buffett 25/5 Rule을 소개하고 동기 부여 문구를 표시한다.
// 텍스트가 순차적으로 페이드인되는 부드러운 등장 애니메이션을 적용한다.

import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../widgets/ritual_glass_container.dart';
import '../widgets/ritual_intro_content.dart';

/// 리추얼 인트로 페이지 (Page 1)
/// 25/5 Rule 소개 + 동기 부여 문구 + 시작하기 안내
/// [isReturningUser]가 true이면 재방문 사용자용 안내 문구를 표시한다
class RitualIntroPage extends StatefulWidget {
  final bool isReturningUser;

  const RitualIntroPage({
    super.key,
    this.isReturningUser = false,
  });

  @override
  State<RitualIntroPage> createState() => _RitualIntroPageState();
}

class _RitualIntroPageState extends State<RitualIntroPage>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;

  @override
  void initState() {
    super.initState();
    // 페이드인 애니메이션 (텍스트 등장용)
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: AppAnimation.dramatic,
    );
    // 슬라이드 애니메이션 (하단에서 위로 올라오는 효과)
    _slideCtrl = AnimationController(
      vsync: this,
      duration: AppAnimation.effect,
    );
    // 약간의 딜레이 후 애니메이션 시작
    Future.delayed(AppAnimation.normal, () {
      if (mounted) {
        _fadeCtrl.forward();
        _slideCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;
    final returning = widget.isReturningUser;

    // 부모(DailyRitualScreen)에서 SafeArea + 상하 패딩을 이미 적용한다
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // 동기 부여 메인 메시지 (항상 표시)
          _buildAnimatedText(
            delay: 0.0,
            child: Text(
              '매일매일 목표를 읽으면서\n하루를 Design 하세요',
              style: AppTypography.headingLg.copyWith(
                color: tc.textPrimaryWithAlpha(0.90),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // 제목 섹션
          _buildAnimatedText(
            delay: 0.1,
            child: Text(
              '25/5 Rule',
              style: AppTypography.displayLg.copyWith(
                // 어두운 배경에서도 선명하게 보이도록 테마 인식 악센트 사용
                color: tc.accent,
                letterSpacing: -1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // 부제목
          _buildAnimatedText(
            delay: 0.2,
            child: Text(
              returning
                  ? '오늘도 목표를 확인하세요!'
                  : '워런 버핏의 목표 달성 전략',
              style: AppTypography.headingSm.copyWith(
                color: tc.textPrimaryWithAlpha(0.85),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
          // 설명 카드
          _buildAnimatedText(
            delay: 0.35,
            child: RitualGlassContainer(
              child: RitualIntroContent(
                isReturning: returning,
              ),
            ),
          ),
          const Spacer(flex: 2),
          // 시작 안내
          _buildAnimatedText(
            delay: 0.55,
            child: _buildSwipeHint(tc),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  /// 스와이프 힌트 위젯
  Widget _buildSwipeHint(ResolvedThemeColors tc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.swipe_rounded,
          color: tc.textPrimaryWithAlpha(0.45),
          size: 20,
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          '옆으로 넘겨서 시작하기',
          style: AppTypography.bodySm.copyWith(
            color: tc.textPrimaryWithAlpha(0.45),
          ),
        ),
      ],
    );
  }

  /// 지연된 페이드인 + 슬라이드업 애니메이션을 적용한다
  /// [delay]: 0.0 ~ 1.0 사이의 애니메이션 시작 지연 비율
  Widget _buildAnimatedText({
    required double delay,
    required Widget child,
  }) {
    // Interval로 순차적 등장 효과를 만든다
    final fadeAnim = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOut),
    );
    final slideAnim = CurvedAnimation(
      parent: _slideCtrl,
      curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(slideAnim),
        child: child,
      ),
    );
  }
}
