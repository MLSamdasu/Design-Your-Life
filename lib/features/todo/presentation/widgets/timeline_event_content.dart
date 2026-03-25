// 타임라인 이벤트 블록의 적응적 콘텐츠 위젯
// 블록 높이에 따라 표시할 정보 수준을 조절한다
import 'package:flutter/material.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/models/todo.dart';
import 'timeline_format_helpers.dart';

/// 블록 높이에 따라 적응적으로 콘텐츠를 표시하는 위젯
///
/// | 높이       | 내용                                         |
/// |------------|----------------------------------------------|
/// | >= 60px    | 유형 아이콘 + 제목 1줄 + "09:00 ~ 10:30" + 소요시간 |
/// | 40~59px    | 유형 아이콘 + 제목 1줄 (시간은 위치에서 확인)    |
/// | 30~39px    | 제목 1줄 (툴팁으로 전체 정보)                  |
/// | < 30px     | 축약 제목 (툴팁)                              |
class TimelineEventContent extends StatelessWidget {
  final Todo todo;
  final double height;
  final bool isCompleted;
  final bool isOverlapping;

  const TimelineEventContent({
    super.key,
    required this.todo,
    required this.height,
    required this.isCompleted,
    required this.isOverlapping,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        isOverlapping ? AppTypography.captionMd : AppTypography.bodyMd;
    final textColor = isCompleted
        ? context.themeColors.textPrimaryWithAlpha(0.5)
        : context.themeColors.textPrimary;
    final typeIcon = getTypeIcon(todo);
    final startStr = formatTimeOfDay(todo.startTime);
    final endStr = formatTimeOfDay(todo.endTime);
    final timeRangeStr =
        endStr != null ? '$startStr ~ $endStr' : startStr;
    final durationStr = formatDuration(todo.startTime, todo.endTime);

    if (height >= TimelineLayout.eventBlockLargeThreshold) {
      return _buildLargeBlock(
        context, titleStyle, textColor, typeIcon, timeRangeStr, durationStr,
      );
    } else if (height >= TimelineLayout.eventBlockMediumThreshold) {
      return _buildMediumBlock(context, titleStyle, textColor, typeIcon);
    } else if (height >= TimelineLayout.eventBlockSmallThreshold) {
      return _buildSmallBlock(context, textColor, timeRangeStr);
    } else {
      return _buildTinyBlock(context, textColor, timeRangeStr);
    }
  }

  /// 큰 블록 (1시간 이상): 제목 + 시간 범위 + 소요시간
  Widget _buildLargeBlock(
    BuildContext context,
    TextStyle titleStyle,
    Color textColor,
    IconData? typeIcon,
    String? timeRangeStr,
    String? durationStr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (typeIcon != null) ...[
              Icon(
                typeIcon,
                size: 12,
                color: context.themeColors.textPrimaryWithAlpha(0.5),
              ),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Expanded(
              child: Text(
                todo.title,
                style: titleStyle.copyWith(color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (timeRangeStr != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              // 시간 범위 텍스트 — Flexible로 감싸 좁은 블록에서 오버플로를 방지한다
              Flexible(
                child: Text(
                  timeRangeStr,
                  style: AppTypography.captionSm.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (durationStr != null && !isOverlapping) ...[
                const SizedBox(width: AppSpacing.sm),
                // 소요시간 텍스트 — 오버플로 가드 추가
                Text(
                  durationStr,
                  style: AppTypography.captionSm.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  /// 중간 블록 (40~59px): 유형 아이콘 + 제목만
  Widget _buildMediumBlock(
    BuildContext context,
    TextStyle titleStyle,
    Color textColor,
    IconData? typeIcon,
  ) {
    return Row(
      children: [
        if (typeIcon != null) ...[
          Icon(
            typeIcon,
            size: 12,
            color: context.themeColors.textPrimaryWithAlpha(0.5),
          ),
          const SizedBox(width: AppSpacing.xxs),
        ],
        Expanded(
          child: Text(
            todo.title,
            style: titleStyle.copyWith(color: textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 작은 블록 (30~39px): 제목만 + 툴팁
  Widget _buildSmallBlock(
    BuildContext context,
    Color textColor,
    String? timeRangeStr,
  ) {
    return Tooltip(
      message: '${todo.title} ($timeRangeStr)',
      child: Text(
        todo.title,
        style: (isOverlapping
                ? AppTypography.captionSm
                : AppTypography.captionMd)
            .copyWith(color: textColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 매우 작은 블록: 축약 제목 + 툴팁
  Widget _buildTinyBlock(
    BuildContext context,
    Color textColor,
    String? timeRangeStr,
  ) {
    final shortTitle =
        todo.title.length > TimelineLayout.eventBlockTruncateLength
            ? '${todo.title.substring(0, TimelineLayout.eventBlockTruncateLength)}...'
            : todo.title;
    return Tooltip(
      message: '${todo.title} ($timeRangeStr)',
      child: Text(
        shortTitle,
        style: AppTypography.captionSm.copyWith(color: textColor),
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }
}
