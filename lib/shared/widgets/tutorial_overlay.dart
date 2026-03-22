// 공용 위젯: TutorialOverlay - 5탭 온보딩 가이드 오버레이
// 앱 첫 실행 시 자동으로 표시되어 각 탭의 기능을 소개한다.
// 단계별 페이드+슬라이드 전환 애니메이션으로 자연스러운 UX를 제공한다.
// SRP: 온보딩 오버레이 표시 + 단계 전환 UI만 담당한다.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/global_providers.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/typography_tokens.dart';
import '../providers/tutorial_provider.dart';

/// 튜토리얼 탭 정보 데이터 클래스
class _TutorialTabInfo {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;

  const _TutorialTabInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
  });
}

/// 5개 탭별 튜토리얼 데이터
const _tabInfoList = [
  _TutorialTabInfo(
    icon: Icons.home_rounded,
    title: '홈',
    subtitle: '오늘 하루를 한눈에',
    description: '투두 요약, 습관 진행률, D-day, 타이머 등\n하루의 모든 정보를 대시보드에서 확인하세요.',
    features: [
      '오늘의 투두 완료율 요약',
      '습관 트래커 진행 현황',
      'D-day 카운트다운',
      '포모도로 타이머 바로가기',
    ],
  ),
  _TutorialTabInfo(
    icon: Icons.calendar_today_rounded,
    title: '캘린더',
    subtitle: '일정을 시각적으로 관리',
    description: '월간/주간/일간 뷰로 전환하며\n시간대별 일정을 직관적으로 파악하세요.',
    features: [
      '월간 · 주간 · 일간 뷰 전환',
      '드래그로 일정 시간 조정',
      '범위 일정 (여행, 시험 등)',
      '색상별 카테고리 분류',
    ],
  ),
  _TutorialTabInfo(
    icon: Icons.check_circle_rounded,
    title: '투두',
    subtitle: '할 일을 빠르게 정리',
    description: '자연어 빠른 입력과 하루 일정표로\n오늘의 할 일을 효율적으로 관리하세요.',
    features: [
      '자연어로 빠르게 투두 추가',
      '하루 일정표 타임라인 뷰',
      '태그 기반 분류 · 필터링',
      '체크 완료 시 연필 취소선',
    ],
  ),
  _TutorialTabInfo(
    icon: Icons.loop_rounded,
    title: '습관',
    subtitle: '꾸준함이 변화를 만든다',
    description: '매일 반복하는 습관을 트래킹하고\n루틴 시간표로 하루 흐름을 설계하세요.',
    features: [
      '습관 트래커 + 스트릭 기록',
      '주간 시간표로 루틴 시각화',
      '인기 습관 프리셋 제공',
      '완료율 도넛 차트',
    ],
  ),
  _TutorialTabInfo(
    icon: Icons.flag_rounded,
    title: '목표',
    subtitle: '큰 그림을 그려보세요',
    description: '연간/월간 목표와 만다라트 기법으로\n체계적인 목표 달성 계획을 세우세요.',
    features: [
      '연간 · 월간 목표 관리',
      '만다라트 81칸 목표 설계',
      '체크포인트 진행률 추적',
      '목표별 세부 과제 관리',
    ],
  ),
];

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
    if (_currentStep >= _tabInfoList.length - 1) {
      // 마지막 단계 → 튜토리얼 완료
      await _completeTutorial();
      return;
    }
    _direction = 1;
    await _controller.reverse();
    setState(() => _currentStep++);
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.08 * _direction, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  /// 이전 단계로 돌아간다
  Future<void> _goBack() async {
    if (_currentStep <= 0) return;
    _direction = -1;
    await _controller.reverse();
    setState(() => _currentStep--);
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.08 * _direction, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
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

  /// 건너뛰기: 바로 튜토리얼을 종료한다
  Future<void> _skip() async {
    await _completeTutorial();
  }

  @override
  Widget build(BuildContext context) {
    final tabInfo = _tabInfoList[_currentStep];
    final isLastStep = _currentStep == _tabInfoList.length - 1;
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
                  sigmaX: AppLayout.blurSigmaMd,
                  sigmaY: AppLayout.blurSigmaMd,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _skip,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: ColorTokens.white.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppRadius.huge),
                          ),
                          child: Text(
                            '건너뛰기',
                            style: AppTypography.bodyMd.copyWith(
                              color:
                                  ColorTokens.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
                          child: _TutorialCard(
                            tabInfo: tabInfo,
                            stepIndex: _currentStep,
                            totalSteps: _tabInfoList.length,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 하단: 단계 인디케이터 + 이전/다음 버튼
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxxl,
                    0,
                    AppSpacing.xxxl,
                    AppSpacing.huge,
                  ),
                  child: Column(
                    children: [
                      // 단계 인디케이터 (도트)
                      _StepDots(
                        currentStep: _currentStep,
                        totalSteps: _tabInfoList.length,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      // 버튼 행
                      Row(
                        children: [
                          // 이전 버튼
                          if (!isFirstStep)
                            Expanded(
                              child: _TutorialButton(
                                label: '이전',
                                icon: Icons.arrow_back_rounded,
                                iconLeft: true,
                                isOutlined: true,
                                onTap: _goBack,
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: AppSpacing.lg),
                          // 다음 / 시작하기 버튼
                          Expanded(
                            child: _TutorialButton(
                              label: isLastStep ? '시작하기' : '다음',
                              icon: isLastStep
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              iconLeft: false,
                              isOutlined: false,
                              onTap: _goNext,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 튜토리얼 탭 정보 카드
/// 아이콘 + 탭명 + 설명 + 기능 목록을 표시한다
class _TutorialCard extends StatelessWidget {
  final _TutorialTabInfo tabInfo;
  final int stepIndex;
  final int totalSteps;

  const _TutorialCard({
    required this.tabInfo,
    required this.stepIndex,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: AppLayout.dialogMaxWidthLg),
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      decoration: BoxDecoration(
        color: ColorTokens.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: ColorTokens.white.withValues(alpha: 0.2),
          width: AppLayout.borderThin,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 탭 아이콘 (원형 배경)
          _AnimatedTabIcon(icon: tabInfo.icon, stepIndex: stepIndex),
          const SizedBox(height: AppSpacing.xl),
          // 단계 표시 텍스트
          Text(
            '${stepIndex + 1} / $totalSteps',
            style: AppTypography.captionLg.copyWith(
              color: ColorTokens.mainLight.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // 탭 이름
          Text(
            tabInfo.title,
            style: AppTypography.headingLg.copyWith(
              color: ColorTokens.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // 부제
          Text(
            tabInfo.subtitle,
            style: AppTypography.titleMd.copyWith(
              color: ColorTokens.mainLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // 설명
          Text(
            tabInfo.description,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: ColorTokens.white.withValues(alpha: 0.75),
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // 기능 목록
          ...tabInfo.features.map((feature) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: AppLayout.iconMd,
                    height: AppLayout.iconMd,
                    decoration: BoxDecoration(
                      color: ColorTokens.mainLight.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: AppLayout.iconXxs,
                      color: ColorTokens.mainLight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      feature,
                      style: AppTypography.bodySm.copyWith(
                        color: ColorTokens.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 탭 아이콘 애니메이션 위젯
/// 등장 시 스케일 + 글로우 효과를 적용한다
class _AnimatedTabIcon extends StatefulWidget {
  final IconData icon;
  final int stepIndex;

  const _AnimatedTabIcon({required this.icon, required this.stepIndex});

  @override
  State<_AnimatedTabIcon> createState() => _AnimatedTabIconState();
}

class _AnimatedTabIconState extends State<_AnimatedTabIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: AppAnimation.snackBar,
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // 부드러운 글로우 펄스: 0.3 ~ 0.6 불투명도 변화
        final glowAlpha =
            0.3 + (_pulseController.value * 0.3);
        return Container(
          width: AppLayout.containerXl,
          height: AppLayout.containerXl,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorTokens.main.withValues(alpha: 0.3),
            boxShadow: [
              BoxShadow(
                color: ColorTokens.mainLight
                    .withValues(alpha: glowAlpha),
                blurRadius: AppLayout.blurRadiusXl,
                spreadRadius: AppSpacing.xs,
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            size: AppLayout.iconHuge + AppSpacing.md,
            color: ColorTokens.white,
          ),
        );
      },
    );
  }
}

/// 단계 인디케이터 도트
class _StepDots extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepDots({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final isActive = i == currentStep;
        final isPast = i < currentStep;
        return AnimatedContainer(
          duration: AppAnimation.standard,
          curve: Curves.easeInOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: isActive
              ? AppLayout.stepIndicatorActiveWidth
              : AppLayout.stepIndicatorInactiveWidth,
          height: AppLayout.stepIndicatorHeightLg,
          decoration: BoxDecoration(
            color: isActive
                ? ColorTokens.mainLight
                : isPast
                    ? ColorTokens.mainLight.withValues(alpha: 0.5)
                    : ColorTokens.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        );
      }),
    );
  }
}

/// 튜토리얼 버튼 (이전/다음/시작하기)
class _TutorialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool iconLeft;
  final bool isOutlined;
  final VoidCallback onTap;

  const _TutorialButton({
    required this.label,
    required this.icon,
    required this.iconLeft,
    required this.isOutlined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lgXl,
          horizontal: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: isOutlined
              ? ColorTokens.transparent
              : ColorTokens.main,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: isOutlined
              ? Border.all(
                  color: ColorTokens.white.withValues(alpha: 0.3),
                  width: AppLayout.borderThin,
                )
              : null,
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: ColorTokens.main.withValues(
                        alpha: AppAnimation.buttonShadowAlpha),
                    blurRadius: AppLayout.ctaShadowBlur,
                    offset:
                        const Offset(0, AppLayout.ctaShadowOffsetY),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconLeft) ...[
              Icon(
                icon,
                size: AppLayout.iconMd,
                color: isOutlined
                    ? ColorTokens.white.withValues(alpha: 0.7)
                    : ColorTokens.white,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              label,
              style: AppTypography.titleMd.copyWith(
                color: isOutlined
                    ? ColorTokens.white.withValues(alpha: 0.7)
                    : ColorTokens.white,
              ),
            ),
            if (!iconLeft) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                icon,
                size: AppLayout.iconMd,
                color: ColorTokens.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
