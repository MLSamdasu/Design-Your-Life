// F1: 리추얼 요약 카드 — 오늘의 3가지 컬럼
// DailyThree 할일 목록과 실제 Todo 완료 상태를 반영하여 표시한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../../ritual/models/daily_three.dart';

/// 리추얼 요약 카드 우측 컬럼: 오늘의 3가지 + Todo 완료 상태
class RitualDailyThreeColumn extends StatelessWidget {
  /// 오늘의 DailyThree (null이면 미등록 상태)
  final DailyThree? dailyThree;

  /// todoId → isCompleted 매핑
  final Map<String, bool> todoStatusMap;

  const RitualDailyThreeColumn({
    super.key,
    required this.dailyThree,
    required this.todoStatusMap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    // 유효한 할일 목록 (빈 문자열 제외)
    // todoIds는 비어있지 않은 task 순서대로만 저장되므로
    // 별도 카운터로 매칭한다 (task 인덱스와 todoIds 인덱스가 다를 수 있다)
    final validTasks = <_TaskWithStatus>[];
    if (dailyThree != null) {
      var todoIdIdx = 0;
      for (var i = 0; i < dailyThree!.tasks.length; i++) {
        final task = dailyThree!.tasks[i];
        if (task.trim().isEmpty) continue;
        // todoIds에서 순차적으로 가져온다
        final todoId = todoIdIdx < dailyThree!.todoIds.length
            ? dailyThree!.todoIds[todoIdIdx]
            : null;
        todoIdIdx++;
        final isCompleted = todoId != null
            ? (todoStatusMap[todoId] ?? false)
            : false;
        validTasks.add(_TaskWithStatus(task: task, isCompleted: isCompleted));
      }
    }

    final completedCount =
        validTasks.where((t) => t.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Text(
          '오늘의 3가지',
          style: AppTypography.captionLg.copyWith(
            color: tc.textPrimaryWithAlpha(0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // 할일 목록
        if (validTasks.isEmpty)
          _buildEmptyState(tc)
        else ...[
          ...validTasks.map((t) => _buildTaskRow(tc, t)),
          const SizedBox(height: AppSpacing.md),
          // 완료 카운트 표시
          _buildCompletionCount(tc, completedCount, validTasks.length),
        ],
      ],
    );
  }

  /// 빈 상태 (DailyThree 미등록)
  Widget _buildEmptyState(ResolvedThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        '오늘의 할일을 등록해주세요',
        style: AppTypography.bodySm.copyWith(
          color: tc.textPrimaryWithAlpha(0.40),
        ),
      ),
    );
  }

  /// 개별 할일 행 (체크박스 + 제목)
  Widget _buildTaskRow(ResolvedThemeColors tc, _TaskWithStatus task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          // 체크 아이콘
          Icon(
            task.isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: task.isCompleted
                ? (tc.isOnDarkBackground
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFF22C55E))
                : tc.textPrimaryWithAlpha(0.35),
          ),
          const SizedBox(width: AppSpacing.md),
          // 할일 텍스트 (완료 시 빨간펜 취소선 — 투두와 동일)
          Expanded(
            child: AnimatedStrikethrough(
              text: task.task,
              style: AppTypography.bodySm.copyWith(
                color: task.isCompleted
                    ? tc.textPrimaryWithAlpha(0.40)
                    : tc.textPrimaryWithAlpha(0.80),
              ),
              isActive: task.isCompleted,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// 완료 카운트 표시 (예: "1/3 완료")
  Widget _buildCompletionCount(
    ResolvedThemeColors tc,
    int completed,
    int total,
  ) {
    final allDone = completed == total && total > 0;
    return Text(
      '$completed/$total 완료',
      style: AppTypography.captionLg.copyWith(
        color: allDone
            ? (tc.isOnDarkBackground
                ? const Color(0xFF4ADE80)
                : const Color(0xFF22C55E))
            : tc.textPrimaryWithAlpha(0.55),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// 할일 텍스트와 완료 상태를 묶는 내부 데이터 클래스
class _TaskWithStatus {
  final String task;
  final bool isCompleted;

  const _TaskWithStatus({
    required this.task,
    required this.isCompleted,
  });
}
