// F2 위젯: DailyEventBlock - 타임라인에 배치되는 이벤트 블록
// AnimatedContainer로 완료 상태 변경 시 색상 부드럽게 전환
// AnimatedStrikethrough로 취소선 애니메이션 적용
import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/animated_checkbox.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../providers/event_models.dart';

/// 타임라인에 배치되는 이벤트 블록
/// 투두/타이머/일반 이벤트를 구분하여 표시한다
class DailyEventBlock extends StatelessWidget {
  /// 표시할 캘린더 이벤트
  final CalendarEvent event;

  /// 1시간당 픽셀 높이
  final double hourHeight;

  /// 이벤트 탭 콜백
  final VoidCallback onTap;

  /// 투두 이벤트 전용 색상 (밝은 틸 계열)
  static const Color _todoCardColor = ColorTokens.todoCard;

  /// 타이머 세션 블록 전용 색상 (에메랄드 그린)
  static const Color _timerSessionColor = ColorTokens.timerSession;

  const DailyEventBlock({
    super.key,
    required this.event,
    required this.hourHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final startMin = (event.startHour ?? 0) * 60 + (event.startMinute ?? 0);
    final endMin = event.endHour != null
        ? event.endHour! * 60 + (event.endMinute ?? 0)
        : startMin + 60;
    final duration = endMin - startMin;

    final top = startMin * (hourHeight / 60);
    final height = (duration * hourHeight / 60)
        .clamp(TimelineLayout.dailyEventMinHeight, double.infinity);
    // 타이머 세션은 에메랄드 그린, 투두는 스카이블루, 일반은 기존 색상
    final isTimerEvent = event.source == 'timer';
    final blockColor = isTimerEvent
        ? _timerSessionColor
        : event.isTodoEvent
            ? _todoCardColor
            : ColorTokens.eventColor(event.colorIndex);
    final isCompleted = event.isTodoCompleted;

    return Positioned(
      top: top,
      left: AppSpacing.xs,
      right: AppSpacing.xs,
      child: GestureDetector(
        onTap: onTap,
        // AnimatedContainer: 완료 토글 시 배경/테두리 색상 부드럽게 전환
        child: AnimatedContainer(
          duration: AppAnimation.slower,
          curve: Curves.easeInOut,
          height: height,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: blockColor.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: blockColor.withValues(alpha: 0.65),
              width: AppLayout.borderThin,
            ),
          ),
          // 투두 이벤트: 체크박스 + 취소선 표시
          child: Row(
            children: [
              if (event.isTodoEvent)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: AnimatedCheckbox(
                    isCompleted: isCompleted,
                    size: AppLayout.iconMd,
                  ),
                ),
              Expanded(
                // 공용 AnimatedStrikethrough로 취소선 애니메이션 적용
                child: AnimatedStrikethrough(
                  text: event.title,
                  style: AppTypography.bodyMd.copyWith(
                    color: context.themeColors.textPrimary,
                  ),
                  isActive: isCompleted,
                  maxLines: height > TimelineLayout.dailyEventMultiLineThreshold
                      ? 2
                      : 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
