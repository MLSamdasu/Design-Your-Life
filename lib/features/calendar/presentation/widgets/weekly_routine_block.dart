// F2 위젯: WeeklyRoutineBlock - 주간 뷰 루틴 블록 (SRP 분리)
// 루틴의 시간 범위에 따라 Positioned로 배치된다.
import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../providers/event_provider.dart';
import 'weekly_view_constants.dart';

/// 주간 뷰 루틴 블록 위젯
/// 루틴의 시간 범위에 따라 Positioned로 배치된다
/// 이벤트 블록보다 연한 배경으로 시각적으로 구분한다
/// 완료 토글 콜백과 완료 상태를 받아 체크박스 + 취소선을 표시한다
class WeeklyRoutineBlock extends StatelessWidget {
  final RoutineEntry routine;

  /// 루틴 완료 여부
  final bool isCompleted;

  /// 루틴 완료 토글 콜백
  final VoidCallback? onToggle;

  const WeeklyRoutineBlock({
    super.key,
    required this.routine,
    this.isCompleted = false,
    this.onToggle,
  });

  /// 배경색 밝기에 따라 대비가 높은 텍스트 색상을 반환한다
  /// WCAG 기준: 밝은 배경 → 어두운 텍스트, 어두운 배경 → 흰색 텍스트
  static Color _contrastTextColor(Color bgColor) {
    final luminance = bgColor.computeLuminance();
    return luminance > 0.4
        ? ColorTokens.gray900
        : ColorTokens.white;
  }

  @override
  Widget build(BuildContext context) {
    final startMin = routine.startHour * 60 + routine.startMinute;
    final endMin = routine.endHour * 60 + routine.endMinute;
    final duration = endMin - startMin;

    final top = startMin * (kWeeklyHourHeight / 60);
    final height = (duration * kWeeklyHourHeight / 60)
        .clamp(TimelineLayout.weeklyEventMinHeight, double.infinity);
    final routineColor = ColorTokens.eventColor(routine.colorIndex);
    // 배경색 밝기 기반 대비 텍스트 색상 (6개 테마 전부 대응)
    final textColor = _contrastTextColor(routineColor);

    return Positioned(
      top: top,
      left: AppSpacing.xxs,
      right: AppSpacing.xxs,
      child: GestureDetector(
        onTap: onToggle,
        // 완료 시 배경/테두리 색상 부드럽게 전환
        child: AnimatedContainer(
          duration: AppAnimation.slower,
          curve: Curves.easeInOut,
          height: height,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            // 루틴은 이벤트보다 연한 배경으로 구분, 완료 시 더 연하게
            color: routineColor.withValues(
              alpha: isCompleted ? 0.25 : 0.55,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border(
              left: BorderSide(
                color: routineColor.withValues(
                  alpha: isCompleted ? 0.3 : 0.6,
                ),
                width: AppLayout.borderThick,
              ),
            ),
          ),
          child: Row(
            children: [
              // 루틴 미니 체크박스
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xxs),
                child: buildWeeklyMiniCheckbox(context, isCompleted),
              ),
              Expanded(
                child: AnimatedOpacity(
                  opacity: isCompleted ? 0.50 : 1.0,
                  duration: AppAnimation.textFade,
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 루틴 이름 — 대비 텍스트 색상 적용
                      AnimatedStrikethrough(
                        isActive: isCompleted,
                        text: routine.name,
                        style: AppTypography.captionLg.copyWith(
                          color: textColor,
                        ),
                        maxLines: height > TimelineLayout.weeklyEventMultiLineThreshold ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // 시간 표시 — 블록 높이가 30px 이상일 때만
                      if (height >= TimelineLayout.weeklyEventMultiLineThreshold)
                        Text(
                          '${routine.startHour}:${routine.startMinute.toString().padLeft(2, '0')}'
                          '-'
                          '${routine.endHour}:${routine.endMinute.toString().padLeft(2, '0')}',
                          style: AppTypography.captionSm.copyWith(
                            color: textColor.withValues(alpha: 0.70),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 취소선 위젯은 공용 AnimatedStrikethrough (shared/widgets/animated_strikethrough.dart)를 사용한다
