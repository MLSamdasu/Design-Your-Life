// 도넛 차트 위젯: 완료율을 도넛 형태로 시각화
// fl_chart 패키지를 사용하며, 홈 대시보드·투두·습관 화면에서 공통 사용한다.
// AN-03: 0% → 목표% sweep 애니메이션 800ms easeInOutCubic 적용
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';
import 'donut_chart_config.dart';

/// 글래스모피즘 스타일 도넛 차트 위젯
/// AN-03: 0% -> 목표% sweep 애니메이션 800ms easeInOutCubic 적용
class DonutChart extends StatefulWidget {
  final double percentage;
  final DonutChartSize size;
  final DonutChartType type;

  /// 중앙 레이블 텍스트 (null이면 % 숫자만 표시)
  final String? centerLabel;

  const DonutChart({
    required this.percentage,
    this.size = DonutChartSize.medium,
    this.type = DonutChartType.todo,
    this.centerLabel,
    super.key,
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // AN-03: 차트 sweep 애니메이션 800ms
    final reducedMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    _controller = AnimationController(
      duration: reducedMotion ? Duration.zero : AppAnimation.effect,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.percentage.clamp(0, 100),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 값이 변경될 때 애니메이션 재실행
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.percentage.clamp(0, 100),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    // AnimationController 반드시 해제
    _controller.dispose();
    super.dispose();
  }

  /// 차트 완성 색상 반환
  Color _progressColor(BuildContext context) {
    if (widget.type == DonutChartType.habit) {
      // 습관 달성률: habitProgress 토큰 (민트 그린)
      return ColorTokens.habitProgress;
    }
    return context.themeColors.textPrimaryWithAlpha(0.85);
  }

  /// 차트 트랙(미완료) 색상 반환
  Color _trackColor(BuildContext context) =>
      context.themeColors.textPrimaryWithAlpha(0.15);

  @override
  Widget build(BuildContext context) {
    final chartSize = DonutChartDimensions.chartSize(widget.size);
    final strokeWidth = DonutChartDimensions.strokeWidth(widget.size);
    final centerSpace = DonutChartDimensions.centerSpaceRadius(widget.size);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final current = _animation.value;
        return SizedBox(
          width: chartSize,
          height: chartSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 도넛 차트
              PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: centerSpace,
                  startDegreeOffset: -90, // 12시 방향 시작
                  sections: [
                    PieChartSectionData(
                      value: current,
                      color: _progressColor(context),
                      radius: strokeWidth,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: (100 - current).clamp(0, 100),
                      color: _trackColor(context),
                      radius: strokeWidth,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              // 중앙 텍스트 (mini 크기는 텍스트 생략)
              if (widget.size != DonutChartSize.mini)
                _buildCenterText(current),
            ],
          ),
        );
      },
    );
  }

  /// 중앙 텍스트 위젯 (퍼센트 + 레이블)
  Widget _buildCenterText(double current) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${current.round()}%',
          // large: headingMd(22px), medium/mini: titleLg(16px) 토큰으로 분기
          style: (widget.size == DonutChartSize.large
                  ? AppTypography.headingMd
                  : AppTypography.titleLg)
              .copyWith(color: context.themeColors.textPrimary),
        ),
        if (widget.centerLabel != null)
          Text(
            widget.centerLabel!,
            style: AppTypography.captionSm.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.6),
            ),
          ),
      ],
    );
  }
}
