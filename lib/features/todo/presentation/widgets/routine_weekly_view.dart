// 투두 탭 서브탭 2: 주간 루틴 뷰
// 오늘 활성 루틴 목록을 체크리스트 형태로 표시한다
// routinesForTimelineProvider (todo_provider.dart)를 데이터 소스로 사용한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/models/todo.dart';
import '../../providers/todo_provider.dart';
import '../../../habit/providers/routine_log_provider.dart';

/// 주간 루틴 뷰 (투두 탭 서브탭)
class RoutineWeeklyView extends ConsumerWidget {
  const RoutineWeeklyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final routineEntries = ref.watch(routinesForTimelineProvider);

    if (routineEntries.isEmpty) {
      return Center(
        child: Text(
          '오늘의 루틴이 없습니다',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.5),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: AppSpacing.md,
      ),
      itemCount: routineEntries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final todo = routineEntries[index];
        return _RoutineItem(routineTodo: todo, date: selectedDate);
      },
    );
  }
}

/// 루틴 아이템 (체크박스 + 색상 바 + 이름 + 시간)
class _RoutineItem extends ConsumerWidget {
  final Todo routineTodo;
  final DateTime date;

  const _RoutineItem({required this.routineTodo, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 원본 루틴 ID 추출 (todo.id에서 'routine_' 접두사 제거)
    final routineId = routineTodo.id.startsWith('routine_')
        ? routineTodo.id.substring(8)
        : routineTodo.id;

    final isCompleted = ref.watch(
      routineCompletionProvider((routineId: routineId, date: date)),
    );

    return GestureDetector(
      onTap: () => ref.read(toggleRoutineLogProvider)(
        routineId, date, !isCompleted,
      ),
      child: AnimatedContainer(
        duration: AppAnimation.normal,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(
            isCompleted ? 0.06 : 0.10,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            // 완료 체크박스
            AnimatedContainer(
              duration: AppAnimation.normal,
              width: AppLayout.iconMd,
              height: AppLayout.iconMd,
              decoration: BoxDecoration(
                color: isCompleted
                    ? context.themeColors.accent
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(
                  color: isCompleted
                      ? context.themeColors.accent
                      : context.themeColors.textPrimaryWithAlpha(0.3),
                  width: AppLayout.borderMedium,
                ),
              ),
              child: isCompleted
                  ? Icon(Icons.check,
                      size: AppLayout.iconSm,
                      color: context.themeColors.dialogSurface)
                  : null,
            ),
            const SizedBox(width: AppSpacing.lg),
            // 색상 인디케이터
            Container(
              width: 4,
              height: AppLayout.iconXl,
              decoration: BoxDecoration(
                color: ColorTokens.main,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // 루틴 이름 + 시간
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routineTodo.title,
                    style: AppTypography.bodyMd.copyWith(
                      color: context.themeColors.textPrimary,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (routineTodo.startTime != null)
                    Text(
                      '${routineTodo.startTime!.hour.toString().padLeft(2, '0')}:${routineTodo.startTime!.minute.toString().padLeft(2, '0')}'
                      '${routineTodo.endTime != null ? ' ~ ${routineTodo.endTime!.hour.toString().padLeft(2, '0')}:${routineTodo.endTime!.minute.toString().padLeft(2, '0')}' : ''}',
                      style: AppTypography.bodySm.copyWith(
                        color: context.themeColors
                            .textPrimaryWithAlpha(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
