// 데일리 리추얼: 10페이지 책 넘김 PageView 메인 화면
// 건너뛰기/인디케이터 표시, Provider로 데이터 로드/저장/완료를 처리한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ads/ad_constants.dart';
import '../../../core/ads/ad_provider.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../providers/ritual_provider.dart';
import 'pages/ritual_complete_page.dart';
import 'pages/ritual_daily_three_page.dart';
import 'pages/ritual_goals_page.dart';
import 'pages/ritual_intro_page.dart';
import 'pages/ritual_rule3_intro_page.dart';
import 'pages/ritual_top5_page.dart';
import 'ritual_save_helper.dart';
import 'ritual_state_holder.dart';
import 'widgets/page_turn_effect.dart';
import 'widgets/ritual_page_indicator.dart';
import 'widgets/ritual_skip_button.dart';

/// 데일리 리추얼 메인 화면 — 풀스크린 오버레이로 표시된다
class DailyRitualScreen extends ConsumerStatefulWidget {
  const DailyRitualScreen({super.key});
  @override
  ConsumerState<DailyRitualScreen> createState() =>
      _DailyRitualScreenState();
}

class _DailyRitualScreenState extends ConsumerState<DailyRitualScreen> {
  static const double _kSkipButtonHeight = 48; // 스킵 버튼 영역 높이
  static const double _kIndicatorHeight = 40; // 인디케이터 영역 높이

  late final PageController _pageCtrl;
  late final RitualStateHolder _state;
  int _currentPage = 0;

  /// 현재 기간 키 (월간 기준: 'yyyy-MM')
  String get _periodKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  RitualSaveHelper get _saver => RitualSaveHelper(
        ref: ref, state: _state, periodKey: _periodKey,
      );

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _state = RitualStateHolder();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _state.dispose();
    super.dispose();
  }

  /// 기존 저장된 리추얼 데이터를 로드한다 (DailyThree는 매일 새로 작성)
  void _loadExisting() {
    final ritual = ref.read(currentRitualProvider(
      (periodType: 'monthly', periodKey: _periodKey),
    ));
    if (ritual != null) {
      setState(() {
        _state.prefillGoals(ritual.goals);
        _state.prefillTop5(ritual.top5Indices);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tc.textPrimaryWithAlpha(0.03),
              tc.textPrimaryWithAlpha(0.08),
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildPageView(),
            _buildSkipButton(),
            _buildPageIndicator(),
          ],
        ),
      ),
    );
  }

  /// 10페이지 책 넘김 PageView
  /// SafeArea 적용하여 스킵 버튼/인디케이터 영역과 겹치지 않도록 한다
  Widget _buildPageView() {
    final isReturning = _state.hasExistingGoals;
    return SafeArea(
      child: Padding(
        // 상단: 스킵 버튼 영역 확보, 하단: 인디케이터 영역 확보
        padding: const EdgeInsets.only(
          top: _kSkipButtonHeight,
          bottom: _kIndicatorHeight,
        ),
        child: BookPageView(
          controller: _pageCtrl,
          onPageChanged: (p) => setState(() => _currentPage = p),
          children: [
            RitualIntroPage(isReturningUser: isReturning),
            for (var i = 0; i < 5; i++)
              RitualGoalsPage(
                pageIndex: i,
                controllers: _state.controllersForPage(i),
                onGoalChanged: (idx, t) => setState(() {}),
                isPreFilled: isReturning,
              ),
            RitualTop5Page(
              goals: _state.goals,
              selectedIndices: _state.selectedTop5,
              onToggle: (i) => setState(() => _state.toggleTop5(i)),
              onResetSelection: () =>
                  setState(() => _state.resetTop5()),
              isPreSelected: isReturning,
            ),
            const RitualRule3IntroPage(),
            RitualDailyThreePage(
              controllers: _state.dailyThreeControllers,
              onChanged: (_, __) => setState(() {}),
            ),
            RitualCompletePage(
              topGoalCount: _state.selectedCount,
              dailyThreeCount: _state.dailyThreeCount,
              onComplete: _onComplete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Positioned(
      top: 0,
      right: AppSpacing.pageHorizontal,
      child: SafeArea(
        child: RitualSkipButton(onSkip: _onSkip),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Positioned(
      bottom: AppSpacing.xxl,
      left: 0,
      right: 0,
      child: SafeArea(
        child: RitualPageIndicator(
          pageCount: RitualStateHolder.totalPages,
          currentPage: _currentPage,
        ),
      ),
    );
  }

  /// 건너뛰기: 저장 + 완료 마커 + 광고 → 닫기
  Future<void> _onSkip() async {
    await _saver.saveRitual();
    await _saver.markTodayAsCompleted();
    if (mounted) _showAdThenPop();
  }

  /// 완료: 리추얼 + Todo 저장 + 광고 → 닫기
  Future<void> _onComplete() async {
    await _saver.saveRitual();
    await _saver.saveDailyThreeWithTodos();
    if (mounted) _showAdThenPop();
  }

  /// 모바일 보상형 광고 표시 후 화면 닫기 (공통)
  void _showAdThenPop() {
    if (!AdConstants.isAdSupported) { Navigator.of(context).pop(); return; }
    final ad = ref.read(adServiceProvider);
    if (!ad.isRewardedReady) { Navigator.of(context).pop(); return; }
    void pop() { if (mounted) Navigator.of(context).pop(); }
    ad.showRewardedAd(onRewarded: pop, onDismissed: pop);
  }
}
