// 인증 Feature: 로그인 화면
// Google Sign-In 버튼 하나로 구성된 심플한 로그인 화면이다.
// 로그인 성공 시 GoRouter authStateStreamProvider 리다이렉트가 /home으로 이동한다.
// SRP 분리: 하위 위젯 → login_widgets.dart
// IN: authServiceProvider (C0.3의 OUT)
// OUT: GoRouter redirect → /home
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/error/app_exception.dart';
import 'login_widgets.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';

/// 로그인 화면
/// Google OAuth 버튼 하나로 구성된 미니멀 Glassmorphism 디자인
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  /// 화면 진입 페이드인 컨트롤러 (AN-01: 600ms, easeOutCubic)
  late final AnimationController _enterController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  /// 로딩 상태 (로그인 진행 중)
  bool _isLoading = false;

  /// 에러 메시지 (로그인 실패 시)
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      vsync: this,
      duration: AppAnimation.dramatic,
    );
    _fadeAnim = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
    );
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  /// Google 로그인 실행
  /// AuthStateNotifier.signInWithGoogle() 호출 → 성공 시 GoRouter가 자동 리다이렉트
  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // authStateProvider.notifier를 통해 호출해야 상태가 갱신되고
      // GoRouter refreshListenable이 감지하여 리다이렉트한다
      await ref.read(authStateProvider.notifier).signInWithGoogle();
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '로그인에 실패했어요. 다시 시도해주세요.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: SlideTransition(
              position: _slideAnim,
              child: Center(
                child: ConstrainedBox(
                  // 최대 너비 400px (반응형 대응)
                  constraints: const BoxConstraints(maxWidth: AppLayout.dialogMaxWidthSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 앱 아이콘 (login_widgets.dart)
                        const AppIcon(),
                        const SizedBox(height: AppSpacing.huge),

                        // 앱 이름
                        Text(
                          'Design Your Life',
                          style: AppTypography.displayMd.copyWith(
                    color: context.themeColors.textPrimary,
                            letterSpacing: AppLayout.letterSpacingTight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 태그라인
                        Text(
                          '목표, 습관, 할 일을 한 곳에서 관리하세요',
                          style: AppTypography.bodyMd.copyWith(
                            color: context.themeColors.textPrimaryWithAlpha(0.68),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.enormous),

                        // 로그인 카드 (login_widgets.dart)
                        LoginCard(
                          isLoading: _isLoading,
                          errorMessage: _errorMessage,
                          onGoogleSignIn: _signInWithGoogle,
                          onTestSignIn: null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
