// 공용 위젯: TutorialOverlay - 5탭 온보딩 가이드 오버레이
// 앱 첫 실행 시 자동으로 표시되어 각 탭의 기능을 소개한다.
// 단계별 페이드+슬라이드 전환 애니메이션으로 자연스러운 UX를 제공한다.
// SRP 분리: 온보딩 오버레이 표시 + 단계 전환 로직만 담당한다.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/global_providers.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../providers/tutorial_provider.dart';
import 'tutorial_bottom_controls.dart';
import 'tutorial_card.dart';
import 'tutorial_skip_button.dart';
import 'tutorial_tab_info.dart';

/// 5탭 온보딩 가이드 오버레이
/// 앱 첫 실행 시 표시되어 각 탭의 기능을 순서대로 소개한다
class TutorialOverlay extends ConsumerStatefulWidget {
  /// 튜토리얼 완료 시 호출되는 콜백
  final VoidCallback onComplete;

  const TutorialOverlay({required this.onComplete, super.key});

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  /// 현재 표시 중인 단계 (로컬 상태)
  int _currentStep = 0;

  /// 전환 방향 (1: 앞으로, -1: 뒤로)
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimation.slow,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    // 초기 진입 애니메이션
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 다음 단계로 전환한다
  Future<void> _goNext() async {
    if (_currentStep >= tutorialTabInfoList.length - 1) {
      await _completeTutorial();
      return;
    }
    _direction = 1;
    await _controller.reverse();
    setState(() => _currentStep++);
    _updateSlideAnimation();
    _controller.forward();
  }

  /// 이전 단계로 돌아간다
  Future<void> _goBack() async {
    if (_currentStep <= 0) return;
    _direction = -1;
    await _controller.reverse();
    setState(() => _currentStep--);
    _updateSlideAnimation();
    _controller.forward();
  }

  /// 현재 방향에 맞게 슬라이드 애니메이션을 재설정한다
  void _updateSlideAnimation() {
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.08 * _direction, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  /// 튜토리얼 완료 처리 (Hive에 플래그 저장 + 오버레이 닫기)
  Future<void> _completeTutorial() async {
    await ref.read(hiveCacheServiceProvider).saveSetting(
          AppConstants.settingsKeyHasSeenTutorial,
          true,
        );
    ref.read(hasSeenTutorialProvider.notifier).state = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final tabInfo = tutorialTabInfoList[_currentStep];
    final isLastStep = _currentStep == tutorialTabInfoList.length - 1;
    final isFirstStep = _currentStep == 0;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 반투명 배경 + 블러
          Positioned.fill(
            child: GestureDetector(
              onTap: () {}, // 배경 탭 차단
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: EffectLayout.blurSigmaMd,
                  sigmaY: EffectLayout.blurSigmaMd,
                ),
                child: Container(
                  color: ColorTokens.barrierBase
                      .withValues(alpha: AppAnimation.barrierAlphaStrong),
                ),
              ),
            ),
          ),
          // 콘텐츠 영역
          SafeArea(
            child: Column(
              children: [
                // 상단: 건너뛰기 버튼
                TutorialSkipButton(onSkip: _completeTutorial),
                // 중앙: 탭 정보 카드
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxxl,
                          ),
                          child: TutorialCard(
                            tabInfo: tabInfo,
                            stepIndex: _currentStep,
                            totalSteps: tutorialTabInfoList.length,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 하단: 단계 인디케이터 + 이전/다음 버튼
                TutorialBottomControls(
                  currentStep: _currentStep,
                  totalSteps: tutorialTabInfoList.length,
                  isFirstStep: isFirstStep,
                  isLastStep: isLastStep,
                  onBack: _goBack,
                  onNext: _goNext,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
