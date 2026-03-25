// F2 위젯: DailyRoutineBlock - 타임라인에 배치되는 루틴 블록
// 루틴 완료 상태에 따라 체크박스 + 취소선 + 반투명 효과를 적용한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/animated_checkbox.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/event_models.dart';
import '../../../habit/providers/routine_log_provider.dart';

/// 타임라인에 배치되는 루틴 블록
/// 완료 토글 시 배경/테두리 색상과 취소선이 부드럽게 전환된다
class DailyRoutineBlock extends ConsumerWidget {
  /// 표시할 루틴 엔트리
  final RoutineEntry routine;

  /// 1시간당 픽셀 높이
  final double hourHeight;

  const DailyRoutineBlock({
    super.key,
    required this.routine,
    required this.hourHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    // 루틴 완료 상태를 Provider에서 감시한다
    final isCompleted = ref.watch(routineCompletionProvider(
      (routineId: routine.id, date: selectedDate),
    ));

    final startMin = routine.startHour * 60 + routine.startMinute;
    final endMin = routine.endHour * 60 + routine.endMinute;
    // 자정을 넘는 루틴(예: 22:00~01:00)은 자정까지만 표시한다
    final effectiveEndMin = endMin <= startMin ? 24 * 60 : endMin;
    final duration = effectiveEndMin - startMin;

    final top = startMin * (hourHeight / 60);
    final height = (duration * hourHeight / 60)
        .clamp(TimelineLayout.dailyEventMinHeight, double.infinity);
    final routineColor = ColorTokens.eventColor(routine.colorIndex);

    return Positioned(
      top: top,
      right: AppSpacing.xs,
      width: TimelineLayout.dailyRoutineColumnWidth,
      child: GestureDetector(
        onTap: () {
          // 루틴 완료 토글
          ref.read(toggleRoutineLogProvider)(
            routine.id,
            selectedDate,
            !isCompleted,
          );
        },
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
            color: routineColor.withValues(
              alpha: isCompleted ? 0.12 : 0.25,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: routineColor.withValues(
                alpha: isCompleted ? 0.25 : 0.45,
              ),
              width: AppLayout.borderThin,
            ),
          ),
          child: Row(
            children: [
              // 루틴 미니 체크박스
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xxs),
                child: AnimatedCheckbox(
                  isCompleted: isCompleted,
                  size: AppLayout.iconMd,
                ),
              ),
              Expanded(
                child: AnimatedOpacity(
                  opacity: isCompleted ? 0.50 : 1.0,
                  duration: AppAnimation.textFade,
                  curve: Curves.easeInOut,
                  child: AnimatedStrikethrough(
                    text: routine.name,
                    style: AppTypography.captionMd.copyWith(
                      color: routineColor.withValues(alpha: 0.80),
                    ),
                    isActive: isCompleted,
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
