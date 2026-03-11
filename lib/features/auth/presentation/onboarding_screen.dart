// 인증 Feature: 온보딩 화면
// 2단계 온보딩: (1) 개인정보 처리 동의 → (2) 이름 입력 → 홈 이동
// AC-ON-02: 로그인 성공 후 이 화면으로 이동 (신규 사용자 판별)
// AC-ON-04: 이름은 1~20자 이내, 빈 값 불가
// AC-ON-05: "시작하기" 탭 시 UserProfile을 Hive에 저장 후 홈으로 이동
// SRP 분리: 하위 위젯 → onboarding_widgets.dart
// IN: currentAuthStateProvider (C0.3)
// OUT: Hive UserProfile 저장 → GoRouter /home 리다이렉트
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/router/route_paths.dart';
import 'onboarding_widgets.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';

/// 온보딩 단계 열거형
/// consent: 개인정보 동의, nameInput: 이름 입력
enum OnboardingStep { consent, nameInput }

/// 온보딩 화면
/// 신규 사용자 전용 (재방문 사용자는 GoRouter redirect가 /home으로 직행)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  /// 현재 온보딩 단계
  OnboardingStep _currentStep = OnboardingStep.consent;

  /// 개인정보 동의 체크 여부
  bool _isConsentChecked = false;

  /// 이름 입력 컨트롤러
  final _nameController = TextEditingController();

  /// 이름 입력 에러 메시지
  String? _nameError;

  /// 저장 진행 중 여부
  bool _isSaving = false;

  /// 단계 전환 페이드 애니메이션 컨트롤러
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // AN-09: 단계 전환 CrossFade 300ms
    _fadeController = AnimationController(
      vsync: this,
      duration: AppAnimation.medium,
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// 다음 단계로 전환 (페이드 아웃 → 전환 → 페이드 인)
  Future<void> _goToNameInput() async {
    if (!_isConsentChecked) return;
    await _fadeController.reverse();
    if (!mounted) return;
    setState(() => _currentStep = OnboardingStep.nameInput);
    await _fadeController.forward();
  }

  /// 이름 유효성 검사 (AC-ON-04: 1~20자 이내, 빈 값 불가)
  bool _validateName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = '이름을 입력해주세요');
      return false;
    }
    if (name.length > 20) {
      setState(() => _nameError = '20자 이내로 입력해주세요');
      return false;
    }
    setState(() => _nameError = null);
    return true;
  }

  /// 온보딩 완료: UserProfile을 Hive에 저장 후 홈으로 이동
  Future<void> _complete() async {
    if (!_validateName() || _isSaving) return;
    setState(() => _isSaving = true);

    final authState = ref.read(currentAuthStateProvider);
    final cache = ref.read(hiveCacheServiceProvider);
    final userId = authState.userId;

    // 인증 만료 시 로그인으로 돌아간다
    if (userId == null) {
      if (mounted) context.go(RoutePaths.login);
      return;
    }

    try {
      // Hive userProfileBox에 UserProfile 저장
      await cache.put(AppConstants.userProfileBox, userId, {
        'id': userId,
        'display_name': _nameController.text.trim(),
        'email': authState.email ?? '',
        'photo_url': authState.photoUrl,
        'is_dark_mode': false,
        'schema_version': 1,
      });
      // 저장 완료 → 홈으로 이동
      if (mounted) context.go(RoutePaths.home);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _nameError = '저장에 실패했어요. 다시 시도해주세요.';
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
          child: Center(
            child: ConstrainedBox(
              // 최대 너비 420px (반응형 대응)
              constraints: const BoxConstraints(maxWidth: AppLayout.dialogMaxWidthMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _currentStep == OnboardingStep.consent
                      ? ConsentStep(
                          isChecked: _isConsentChecked,
                          onChecked: (v) =>
                              setState(() => _isConsentChecked = v),
                          onNext: _goToNameInput,
                        )
                      : NameInputStep(
                          controller: _nameController,
                          errorText: _nameError,
                          isSaving: _isSaving,
                          onComplete: _complete,
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
