// 겹침 인식 이벤트 블록 위젯
// 타임라인에서 개별 이벤트를 렌더링하며, 높이에 따라 적응적 콘텐츠를 표시한다
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/models/todo.dart';
import 'timeline_constants.dart';
import 'timeline_event_content.dart';
import 'timeline_event_details.dart';

/// 겹침 인식 이벤트 블록 위젯 (읽기 전용)
/// 블록 높이와 겹침 상태에 따라 텍스트/스타일을 적응적으로 변경한다
class OverlapAwareBlock extends ConsumerWidget {
  final Todo todo;

  /// 겹침 그룹 내 순서 (0부터)
  final int overlapIndex;

  /// 해당 그룹의 총 겹침 수
  final int totalOverlaps;

  /// 블록의 실제 높이 (px)
  final double blockHeight;

  const OverlapAwareBlock({
    super.key,
    required this.todo,
    required this.overlapIndex,
    required this.totalOverlaps,
    required this.blockHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = todo.isCompleted;
    final color = ColorTokens.eventColor(todo.colorIndex);
    final effectiveHeight = max(blockHeight, timelineMinBlockHeight);
    final isOverlapping = totalOverlaps > 1;

    // 겹침 위치에 따른 배경 불투명도 (뒤쪽이 낮고 앞쪽이 높다)
    final double bgAlpha;
    if (!isOverlapping) {
      bgAlpha = 0.15;
    } else {
      bgAlpha = 0.12 + (overlapIndex * 0.04);
    }

    // 2번째 이상 겹침 카드에 깊이감 그림자 추가
    final shadows = overlapIndex > 0
        ? [
            BoxShadow(
              color: ColorTokens.shadowBase.withValues(
                alpha: EffectLayout.overlapShadowAlpha,
              ),
              blurRadius: EffectLayout.overlapShadowBlur,
              offset: const Offset(-AppSpacing.xxs, AppLayout.borderThin),
            ),
          ]
        : <BoxShadow>[];

    // 완료 상태에 따른 불투명도
    final blockOpacity = isCompleted ? 0.5 : 1.0;

    return GestureDetector(
      onTap: () => showTimelineEventDetails(
        context: context,
        ref: ref,
        todo: todo,
      ),
      child: AnimatedOpacity(
        opacity: blockOpacity,
        duration: AppAnimation.slow,
        curve: Curves.easeInOut,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: color.withValues(alpha: bgAlpha),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: shadows,
          ),
          child: Row(
            children: [
              // 좌측 컬러 바
              Container(
                width: 4.0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    bottomLeft: Radius.circular(AppRadius.lg),
                  ),
                ),
              ),
              // 콘텐츠 영역
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: TimelineEventContent(
                    todo: todo,
                    height: effectiveHeight,
                    isCompleted: isCompleted,
                    isOverlapping: isOverlapping,
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
