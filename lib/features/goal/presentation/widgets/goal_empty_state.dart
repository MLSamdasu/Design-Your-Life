// F5 위젯: GoalEmptyState - 목표 빈 상태 위젯 (SRP 분리)
// goal_list_helpers.dart에서 추출한다.
// 포함: EmptyGoalState, FloatingIcon
// SRP 분리: TemplateSection → goal_template_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/enums/goal_period.dart';
import 'goal_template_section.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 목표 빈 상태 위젯
/// 등록된 목표가 없을 때 부유 아이콘 + 안내 텍스트 + 템플릿 제안을 표시한다
class EmptyGoalState extends ConsumerWidget {
  final GoalPeriod period;
  final int year;

  const EmptyGoalState({
    super.key,
    required this.period,
    required this.year,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = period == GoalPeriod.yearly ? '년간 목표' : '월간 목표';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 아이콘 (부유 애니메이션 4px, 2000ms)
          const FloatingIcon(icon: Icons.flag_rounded),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '아직 등록된 목표가 없어요',
            style: AppTypography.bodyLg.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$year년 $label를 추가하고 목표를 달성해보세요!',
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.45),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          // 인기 목표 템플릿 제안 (빠른 시작 유도)
          TemplateSection(period: period, year: year),
        ],
      ),
    );
  }
}

/// 부유 아이콘 애니메이션 위젯 (디자인 시스템 12.4)
/// 위아래 4px 반복 부유 효과를 구현한다
class FloatingIcon extends StatefulWidget {
  final IconData icon;

  const FloatingIcon({super.key, required this.icon});

  @override
  State<FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<FloatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimation.snackBar,
    )..repeat(reverse: true);

    _offsetAnim = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _offsetAnim.value),
          child: child,
        );
      },
      child: Icon(
        widget.icon,
        size: 48,
        color: context.themeColors.textPrimaryWithAlpha(0.3),
      ),
    );
  }
}
