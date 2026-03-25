// 인증 Feature: 스플래시 화면
// 앱 아이콘과 로딩 애니메이션을 표시하며 JWT 세션 복원 완료를 기다린다.
// authStateStreamProvider가 첫 값을 방출하면 GoRouter redirect 로직이
// 자동으로 /login 또는 /home으로 전환한다.
// 입력: authStateStreamProvider (C0.3의 출력)
// 출력: 없음 (GoRouter redirect가 전환 처리)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';
import 'splash_logo_icon.dart';

/// 스플래시 화면
/// JWT 세션 복원 상태를 감시하며 로딩 인디케이터를 표시한다.
/// authStateStreamProvider가 초기 값을 방출하면 GoRouter가 자동으로 리다이렉트한다.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  /// 로고 페이드인 애니메이션 컨트롤러
  late final AnimationController _fadeController;

  /// 로고 페이드인 애니메이션
  late final Animation<double> _fadeAnim;

  /// 부유 애니메이션 컨트롤러 (위아래 반복)
  late final AnimationController _floatController;

  /// 부유 오프셋 애니메이션
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    // AN-01: 스플래시 페이드인 (500ms, easeOutCubic)
    _fadeController = AnimationController(
      vsync: this,
      duration: AppAnimation.dramatic,
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    // 부유 애니메이션 (2000ms, 반복)
    _floatController = AnimationController(
      vsync: this,
      duration: AppAnimation.snackBar,
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 화면 마운트 후 페이드인 시작
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Auth 상태를 watch하여 GoRouter redirect가 자동 트리거되도록 한다
    ref.watch(authStateStreamProvider);

    return Scaffold(
      backgroundColor: ColorTokens.transparent,
      body: Container(
        // 그라디언트 배경 (Glassmorphism)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorTokens.gradientStart,
              ColorTokens.gradientMid,
              ColorTokens.gradientEnd,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 부유 로고 아이콘
                  AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: child,
                      );
                    },
                    child: const SplashLogoIcon(),
                  ),
                  const SizedBox(height: AppSpacing.huge),

                  // 앱 이름
                  Text(
                    'Design Your Life',
                    // displayLg 토큰 사용 (34px, ExtraBold)
                    style: AppTypography.displayLg.copyWith(
                      color: context.themeColors.textPrimary,
                      letterSpacing: MiscLayout.letterSpacingTighter,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 태그라인
                  Text(
                    '당신의 하루를 설계하세요',
                    // bodyMd 토큰 사용 (13px)
                    style: AppTypography.bodyMd.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.70),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.enormous),

                  // 로딩 인디케이터 (Auth 초기화 대기 중)
                  SizedBox(
                    width: AppLayout.iconXxl,
                    height: AppLayout.iconXxl,
                    child: CircularProgressIndicator(
                      strokeWidth: AppLayout.borderAccent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.themeColors.textPrimaryWithAlpha(0.70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
