// F6: 타이머 디스플레이 위젯
// 원형 프로그레스 바 + 중앙 남은 시간 텍스트 + 연결된 투두 이름으로 구성된다.
// CustomPaint로 원형 진행률을 그리고, ColorTokens.main을 진행 색상으로 사용한다.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../services/timer_engine.dart';
import '../../models/timer_log.dart';
import '../../models/timer_state.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 원형 프로그레스 + 남은 시간 표시 위젯
class TimerDisplay extends StatelessWidget {
  /// 현재 타이머 상태
  final TimerState timerState;

  /// 타이머 원형 표시 크기 (기본값: 240)
  final double size;

  const TimerDisplay({
    required this.timerState,
    this.size = 240,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 타이머 진행률 계산 (0.0~1.0)
    final progressValue = TimerEngine.progress(
      timerState.totalSeconds,
      timerState.remainingSeconds,
    );
    // 남은 시간 포맷 문자열 (MM:SS)
    final timeText = TimerEngine.formatTime(timerState.remainingSeconds);
    // 세션 유형별 진행 색상: 집중=배경 테마에 맞는 악센트, 휴식=success
    // 어두운 배경(Glassmorphism/Neon)에서 진한 보라 원형 바가 보이지 않으므로 밝은 버전을 사용한다
    final progressColor = timerState.sessionType == TimerSessionType.focus
        ? context.themeColors.accent
        : ColorTokens.success;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 원형 프로그레스 배경 + 진행 레이어
          CustomPaint(
            size: Size(size, size),
            painter: _CircularProgressPainter(
              progress: progressValue,
              progressColor: progressColor,
              // 배경 트랙: 흰색 15% 투명도
              trackColor: context.themeColors.textPrimaryWithAlpha(0.15),
              strokeWidth: 10,
            ),
          ),

          // 중앙 콘텐츠: 시간 텍스트 + 투두 이름
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 남은 시간 텍스트 (큰 폰트)
              Text(
                timeText,
                style: AppTypography.displayLg.copyWith(
                    color: context.themeColors.textPrimary,
                  // 고정폭 폰트 특성 시뮬레이션: 자간 없애기
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // 연결된 투두 이름 (있을 경우에만 표시)
              if (timerState.linkedTodoTitle != null) ...[
                SizedBox(
                  width: size * 0.65,
                  child: Text(
                    timerState.linkedTodoTitle!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.70),
                    ),
                  ),
                ),
              ] else ...[
                // 투두 미연결 상태 안내
                Text(
                  '투두 없이 실행 중',
                  style: AppTypography.captionMd.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.45),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 원형 프로그레스 바 CustomPainter
/// 배경 트랙 위에 진행률 만큼 호를 그린다
class _CircularProgressPainter extends CustomPainter {
  /// 진행률 (0.0~1.0)
  final double progress;

  /// 진행 호 색상
  final Color progressColor;

  /// 배경 트랙 색상
  final Color trackColor;

  /// 호 두께 (px)
  final double strokeWidth;

  const _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 배경 트랙 (전체 원)
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 진행 호 (12시 방향 = -90도부터 시계 방향으로)
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: radius);
      // 시작각: -90도(12시), sweep: progress * 360도
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    // progress 또는 색상이 변경된 경우에만 리페인트한다
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
