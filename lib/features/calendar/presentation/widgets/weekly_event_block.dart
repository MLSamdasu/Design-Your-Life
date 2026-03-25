// F2 위젯: WeeklyEventBlock - 주간 뷰 이벤트 블록 (SRP 분리)
// 시작 시간과 지속 시간에 따라 Positioned로 배치된다.
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

/// 이벤트 블록 위젯
/// 시작 시간과 지속 시간에 따라 Positioned로 배치된다
/// AnimatedContainer로 완료 상태 변경 시 색상을 부드럽게 전환한다
/// AnimatedStrikethrough로 취소선 애니메이션을 적용한다
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
    final startMin = (event.startHour ?? 0) * 60 + (event.startMinute ?? 0);
    final endMin = event.endHour != null
        ? event.endHour! * 60 + (event.endMinute ?? 0)
        : startMin + 60;
    final duration = endMin - startMin;

    final top = startMin * (kWeeklyHourHeight / 60);
    final height =
        (duration * kWeeklyHourHeight / 60).clamp(TimelineLayout.weeklyEventMinHeight, double.infinity);
    // 투두 이벤트는 스카이블루, 일반 이벤트는 기존 색상
    final blockColor = event.isTodoEvent
        ? _todoCardColor
        : ColorTokens.eventColor(event.colorIndex);
    final isCompleted = event.isTodoCompleted;
    // 배경색 밝기 기반 대비 텍스트 색상 (6개 테마 전부 대응)
    final textColor = _contrastTextColor(blockColor);

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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: blockColor.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border(
              left: BorderSide(
                color: blockColor,
                width: AppLayout.colorBarWidth,
              ),
            ),
          ),
          // 투두 이벤트: 체크박스 + 취소선 표시
          child: Row(
            children: [
              if (event.isTodoEvent)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xxs),
                  child: buildWeeklyMiniCheckbox(context, isCompleted),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 이벤트 제목 — 대비 텍스트 색상 적용
                    AnimatedStrikethrough(
                      isActive: isCompleted,
                      text: event.title,
                      style: AppTypography.captionLg.copyWith(
                        color: textColor,
                      ),
                      maxLines: height > TimelineLayout.weeklyEventMultiLineThreshold ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // 시간 표시 — 블록 높이가 30px 이상일 때만
                    if (height >= TimelineLayout.weeklyEventMultiLineThreshold)
                      Text(
                        '${event.startHour ?? 0}:${(event.startMinute ?? 0).toString().padLeft(2, '0')}'
                        '-'
                        '${event.endHour ?? (event.startHour ?? 0) + 1}:${(event.endMinute ?? 0).toString().padLeft(2, '0')}',
                        style: AppTypography.captionSm.copyWith(
                          color: textColor.withValues(alpha: 0.70),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
