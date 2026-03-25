// 데일리 리추얼 Page 10: 완료 축하 페이지
// 설정 완료 축하 메시지 + 요약 + "시작하기" 버튼을 표시한다.
// 시작하기 버튼은 보상형 광고를 표시한 후 홈 화면으로 이동한다.

import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../widgets/ritual_glass_container.dart';

/// 리추얼 완료 페이지 (Page 10)
/// [topGoalCount]: 선택한 Top 5 목표 수
/// [dailyThreeCount]: 입력한 오늘의 할 일 수
/// [onComplete]: 완료 버튼 콜백 (광고 표시 + 홈 이동)
class RitualCompletePage extends StatefulWidget {
  final int topGoalCount;
  final int dailyThreeCount;
  final VoidCallback onComplete;

  const RitualCompletePage({
    super.key,
    required this.topGoalCount,
    required this.dailyThreeCount,
    required this.onComplete,
  });

  @override
  State<RitualCompletePage> createState() => _RitualCompletePageState();
}

class _RitualCompletePageState extends State<RitualCompletePage>
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
          // 축하 이모지
          _animated(
            delay: 0.0,
            child: Text(
              '\u{1F3AF}',
              style: const TextStyle(fontSize: 64),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // 축하 메시지
          _animated(
            delay: 0.15,
            child: Text(
              '준비 완료!',
              style: AppTypography.displayMd.copyWith(
                color: tc.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
          // 요약 카드
          _animated(
            delay: 0.3,
            child: RitualGlassContainer(
              child: _buildSummary(tc),
            ),
          ),
          const Spacer(flex: 2),
          // 시작하기 버튼
          _animated(
            delay: 0.5,
            child: GlassButton(
              label: '시작하기',
              leadingIcon: Icons.rocket_launch_rounded,
              fullWidth: true,
              onTap: widget.onComplete,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  /// 요약 콘텐츠
  Widget _buildSummary(ResolvedThemeColors tc) {
    return Column(
      children: [
        _summaryRow(
          tc,
          icon: Icons.flag_rounded,
          label: 'Top 5 목표',
          value: '${widget.topGoalCount}개 설정',
        ),
        const SizedBox(height: AppSpacing.xl),
        Divider(color: tc.dividerColor, height: 1),
        const SizedBox(height: AppSpacing.xl),
        _summaryRow(
          tc,
          icon: Icons.today_rounded,
          label: "오늘의 할 일",
          value: '${widget.dailyThreeCount}개 추가',
        ),
      ],
    );
  }

  /// 요약 행 (아이콘 + 라벨 + 값)
  Widget _summaryRow(
    ResolvedThemeColors tc, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          // 어두운 배경에서도 아이콘이 잘 보이도록 테마 인식 악센트 사용
          color: tc.accent,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.lg),
        Text(
          label,
          style: AppTypography.bodyMd.copyWith(
            color: tc.textPrimaryWithAlpha(0.70),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.titleMd.copyWith(
            color: tc.textPrimary,
          ),
        ),
      ],
    );
  }

  /// 지연된 페이드인 + 슬라이드업 래퍼
  Widget _animated({
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
