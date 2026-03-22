// F2 위젯: WeeklyViewWidgets - 주간 뷰 공용 하위 위젯 (SRP 분리)
// weekly_view.dart에서 추출한다.
// 포함: WeeklyEventBlock, WeeklyCurrentTimeLine, WeeklyTimeColumn
import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../providers/event_provider.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/animated_checkbox.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';

// 1시간당 픽셀 높이 (AppLayout.weeklyHourHeight 토큰을 참조한다)
const double kWeeklyHourHeight = AppLayout.weeklyHourHeight;

/// 이벤트 블록 위젯
/// 시작 시간과 지속 시간에 따라 Positioned로 배치된다
/// AnimatedContainer로 완료 상태 변경 시 색상을 부드럽게 전환한다
/// _WeeklyAnimatedStrikethrough로 취소선 애니메이션을 적용한다
class WeeklyEventBlock extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onTap;

  /// 투두 이벤트 완료 토글 콜백
  final VoidCallback? onToggleTodo;

  const WeeklyEventBlock({
    super.key,
    required this.event,
    this.onTap,
    this.onToggleTodo,
  });

  /// 투두 이벤트 전용 색상 (보라 배경에서 잘 보이는 밝은 틸 계열)
  static const Color _todoCardColor = ColorTokens.todoCard;

  @override
  Widget build(BuildContext context) {
    final startMin = (event.startHour ?? 0) * 60 + (event.startMinute ?? 0);
    final endMin = event.endHour != null
        ? event.endHour! * 60 + (event.endMinute ?? 0)
        : startMin + 60;
    final duration = endMin - startMin;

    final top = startMin * (kWeeklyHourHeight / 60);
    final height =
        (duration * kWeeklyHourHeight / 60).clamp(AppLayout.weeklyEventMinHeight, double.infinity);
    // 투두 이벤트는 스카이블루, 일반 이벤트는 기존 색상
    final blockColor = event.isTodoEvent
        ? _todoCardColor
        : ColorTokens.eventColor(event.colorIndex);
    final isCompleted = event.isTodoCompleted;

    return Positioned(
      top: top,
      left: AppSpacing.xxs,
      right: AppSpacing.xxs,
      child: GestureDetector(
        onTap: () {
          // 투두 이벤트: 블록 탭으로 완료 토글
          if (event.isTodoEvent && onToggleTodo != null) {
            onToggleTodo!();
            return;
          }
          onTap?.call();
        },
        // AnimatedContainer: 완료 토글 시 배경/테두리 색상 부드럽게 전환 (400ms)
        child: AnimatedContainer(
          duration: AppAnimation.slower,
          curve: Curves.easeInOut,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: blockColor.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border(
              left: BorderSide(color: blockColor, width: AppLayout.borderThick),
            ),
          ),
          // 투두 이벤트: 체크박스 + 취소선 표시
          child: Row(
            children: [
              if (event.isTodoEvent)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xxs),
                  child: _buildWeeklyMiniCheckbox(context, isCompleted),
                ),
              Expanded(
                // 공용 AnimatedStrikethrough로 취소선 애니메이션 적용
                child: AnimatedStrikethrough(
                  isActive: isCompleted,
                  text: event.title,
                  style: AppTypography.captionLg.copyWith(
                    color: context.themeColors.textPrimary,
                  ),
                  maxLines: height > AppLayout.weeklyEventMultiLineThreshold ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 주간 뷰 타임라인 블록용 미니 체크박스 (CheckItem 스타일)
/// AnimatedCheckbox를 사용하여 스케일 바운스를 적용한다
/// 탭 이벤트는 부모 GestureDetector에서 처리하므로 onTap은 null이다
Widget _buildWeeklyMiniCheckbox(BuildContext context, bool isCompleted) {
  return AnimatedCheckbox(
    isCompleted: isCompleted,
    size: AppLayout.iconSm,
  );
}

/// 현재 시간 빨간 가로선 위젯 (AC-CL-03)
/// 오늘 열에만 표시되며 현재 분까지 정밀하게 위치를 계산한다
class WeeklyCurrentTimeLine extends StatelessWidget {
  final DateTime now;

  const WeeklyCurrentTimeLine({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    final topOffset =
        now.hour * kWeeklyHourHeight + now.minute * (kWeeklyHourHeight / 60);
    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      child: Container(
        height: AppLayout.lineHeightMedium,
        color: ColorTokens.error,
      ),
    );
  }
}

/// 시간 레이블 열 (00:00 ~ 23:00)
/// 왼쪽 고정 열로 24시간 눈금 텍스트를 표시한다
class WeeklyTimeColumn extends StatelessWidget {
  final double width;

  const WeeklyTimeColumn({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        children: List.generate(AppLayout.hoursInDay, (hour) {
          return Positioned(
            top: hour * kWeeklyHourHeight - AppLayout.weeklyTimeLabelOffset,
            left: 0,
            right: AppSpacing.xs,
            child: Text(
              hour.toString().padLeft(2, '0'),
              // captionSm 토큰(10px)으로 fontSize 하드코딩 제거
              style: AppTypography.captionSm.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.55),
              ),
              textAlign: TextAlign.right,
            ),
          );
        }),
      ),
    );
  }
}

// ─── 루틴 블록 위젯 (주간 뷰 전용) ───────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    final startMin = routine.startHour * 60 + routine.startMinute;
    final endMin = routine.endHour * 60 + routine.endMinute;
    final duration = endMin - startMin;

    final top = startMin * (kWeeklyHourHeight / 60);
    final height = (duration * kWeeklyHourHeight / 60)
        .clamp(AppLayout.weeklyEventMinHeight, double.infinity);
    final routineColor = ColorTokens.eventColor(routine.colorIndex);

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
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            // 루틴은 이벤트보다 연한 배경으로 구분, 완료 시 더 연하게
            color: routineColor.withValues(alpha: isCompleted ? 0.08 : 0.18),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border(
              left: BorderSide(
                color: routineColor.withValues(alpha: isCompleted ? 0.3 : 0.6),
                width: AppLayout.borderThick,
              ),
            ),
          ),
          child: Row(
            children: [
              // 루틴 미니 체크박스
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xxs),
                child: _buildWeeklyMiniCheckbox(context, isCompleted),
              ),
              Expanded(
                child: AnimatedOpacity(
                  opacity: isCompleted ? 0.50 : 1.0,
                  duration: AppAnimation.textFade,
                  curve: Curves.easeInOut,
                  // 공용 AnimatedStrikethrough로 취소선 애니메이션 적용
                  child: AnimatedStrikethrough(
                    isActive: isCompleted,
                    text: routine.name,
                    style: AppTypography.captionLg.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.7),
                    ),
                    maxLines: height > AppLayout.weeklyEventMultiLineThreshold ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
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
