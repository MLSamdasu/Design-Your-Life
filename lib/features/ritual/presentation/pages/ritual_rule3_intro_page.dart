// 데일리 리추얼 Page 8: 3의 법칙 인트로 페이지
// "3의 법칙"을 소개하고 오늘 반드시 완수할 3가지를 작성하도록 동기 부여한다.
// 인트로 페이지와 동일한 페이드인 + 슬라이드업 애니메이션을 적용한다.

import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../widgets/ritual_glass_container.dart';

/// 3의 법칙 인트로 페이지 (Page 8)
/// 핵심 메시지: "오늘 반드시 완수할 3가지는?"
class RitualRule3IntroPage extends StatefulWidget {
  const RitualRule3IntroPage({super.key});

  @override
  State<RitualRule3IntroPage> createState() => _RitualRule3IntroPageState();
}

class _RitualRule3IntroPageState extends State<RitualRule3IntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: AppAnimation.effect,
    );
    Future.delayed(AppAnimation.fast, () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    // 부모(DailyRitualScreen)에서 SafeArea + 상하 패딩을 이미 적용한다
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // 숫자 3 강조
          _animatedChild(
            delay: 0.0,
            child: Text(
              '3',
              style: AppTypography.displayLg.copyWith(
                fontSize: 72,
                // 어두운 배경에서도 선명하게 보이도록 테마 인식 악센트 사용
                color: tc.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // 제목
          _animatedChild(
            delay: 0.15,
            child: Text(
              '의 법칙',
              style: AppTypography.headingLg.copyWith(
                color: tc.textPrimaryWithAlpha(0.85),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
          // 설명 카드
          _animatedChild(
            delay: 0.3,
            child: RitualGlassContainer(
              child: _buildDescription(tc),
            ),
          ),
          const Spacer(flex: 2),
          // 하단 안내
          _animatedChild(
            delay: 0.5,
            child: Text(
              '다음 페이지에서 오늘의 3가지를 정하세요',
              style: AppTypography.bodySm.copyWith(
                color: tc.textPrimaryWithAlpha(0.45),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  /// 설명 콘텐츠
  Widget _buildDescription(ResolvedThemeColors tc) {
    return Column(
      children: [
        Text(
          '오늘 반드시 완수할 3가지는?',
          style: AppTypography.headingSm.copyWith(
            color: tc.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          '매일 아침, 가장 중요한 3가지만 정하면\n'
          '하루가 명확해집니다.\n\n'
          '많이 할 필요 없습니다.\n'
          '딱 3가지만 끝내세요.',
          style: AppTypography.bodyLg.copyWith(
            color: tc.textPrimaryWithAlpha(0.70),
            height: 1.8,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 지연된 페이드인 + 슬라이드업 래퍼
  Widget _animatedChild({
    required double delay,
    required Widget child,
  }) {
    final curve = Interval(
      delay,
      (delay + 0.5).clamp(0.0, 1.0),
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: CurvedAnimation(parent: _animCtrl, curve: curve),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _animCtrl, curve: curve)),
        child: child,
      ),
    );
  }
}
