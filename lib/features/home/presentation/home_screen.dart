// F1: 홈 대시보드 메인 화면
// 인사 헤더 + 투두 요약 카드 + 습관 요약 카드 + D-day 섹션 + 주간 요약으로 구성
// AN-02: 화면 진입 시 카드 staggered fade-in + slide-up 애니메이션 (첫 진입만)
// Pull-to-refresh: RefreshIndicator로 전체 데이터 갱신 (AN-15)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_colors.dart';

import 'widgets/greeting_header.dart';
import 'widgets/todo_summary_card.dart';
import 'widgets/habit_summary_card.dart';
import 'widgets/dday_section.dart';
import 'widgets/week_summary_section.dart';
import 'widgets/timer_summary_card.dart';
import 'widgets/achievement_summary_card.dart';
import '../providers/home_provider.dart';
import '../providers/home_dday_provider.dart';
import '../../../core/theme/spacing_tokens.dart';

/// 홈 대시보드 메인 화면
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  // AN-02: Staggered 카드 등장 애니메이션 컨트롤러
  late AnimationController _staggerController;
  // 최초 진입 여부 (재방문 시 staggered 생략)
  bool _isFirstVisit = true;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      // Staggered 총 duration: 350ms + (카드수-1)*50ms 딜레이 합산
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );

    // 최초 진입 시 staggered 애니메이션 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isFirstVisit) {
        _isFirstVisit = false;
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        if (!reduceMotion) {
          _staggerController.forward();
        } else {
          _staggerController.value = 1.0;
        }
      }
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  /// 인덱스별 staggered 페이드인 + slide-up 애니메이션 위젯 래퍼
  Widget _staggeredCard(Widget child, int index) {
    // 각 카드의 시작/종료 Interval 계산
    final startInterval = (index * 0.12).clamp(0.0, 0.7);
    final endInterval = (startInterval + 0.4).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        final curved = CurvedAnimation(
          parent: _staggerController,
          curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05), // 20px / 400px 근사
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Pull-to-refresh 핸들러 (AN-15)
  /// 갱신 실패 시 에러를 삼키지 않고 SnackBar로 사용자에게 피드백을 제공한다
  Future<void> _handleRefresh() async {
    // Riverpod provider 강제 갱신
    ref.invalidate(todayTodosProvider);
    ref.invalidate(todayHabitsProvider);
    ref.invalidate(upcomingDdaysProvider);

    try {
      // 모든 Provider 데이터 로드 완료까지 대기한다
      await Future.wait([
        ref.read(todayTodosProvider.future),
        ref.read(todayHabitsProvider.future),
        ref.read(upcomingDdaysProvider.future),
      ]);
    } catch (e) {
      // 갱신 실패 시 오류를 사용자에게 SnackBar로 알린다 (에러 삼킴 금지)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('데이터를 불러오지 못했어요. 다시 시도해주세요.'),
            backgroundColor: context.themeColors.textPrimaryWithAlpha(0.20),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      // Pull-to-refresh 스타일 (AN-15)
      onRefresh: _handleRefresh,
      color: context.themeColors.textPrimary,
      backgroundColor: context.themeColors.overlayStrong,
      displacement: 40,
      strokeWidth: 2.5,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 인사 헤더 (AN-02 index 0)
                _staggeredCard(const GreetingHeader(), 0),

                // 콘텐츠 영역 패딩 시작
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xl),

                      // 오늘의 투두 카드 (AN-02 index 1)
                      _staggeredCard(const TodoSummaryCard(), 1),

                      const SizedBox(height: AppSpacing.xl),

                      // 업적/레벨 요약 카드 (AN-02 index 2) — 투두 바로 아래로 이동
                      _staggeredCard(const AchievementSummaryCard(), 2),

                      const SizedBox(height: AppSpacing.xl),

                      // 오늘의 습관 카드 (AN-02 index 3)
                      _staggeredCard(const HabitSummaryCard(), 3),

                      const SizedBox(height: AppSpacing.xl),

                      // 오늘의 집중 시간 카드 (AN-02 index 4)
                      _staggeredCard(const TimerSummaryCard(), 4),

                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),

                // D-Day 섹션 (수평 스크롤, 패딩은 내부에서 처리)
                _staggeredCard(const DdaySection(), 5),

                const SizedBox(height: AppSpacing.xxxl),

                // 주간 요약 섹션
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: _staggeredCard(const WeekSummarySection(), 6),
                ),

                // 하단 여백 (하단 nav bar 공간)
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
