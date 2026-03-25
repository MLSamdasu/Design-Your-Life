// F3 위젯: QuickInputPreview — 파싱 결과 미리보기
// QuickInputBar 하단에 날짜·시간·태그·제목 칩을 표시한다
import 'package:flutter/material.dart';

import '../../../../core/nlp/parsed_todo.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 파싱 결과 미리보기 위젯
/// 날짜/시간/태그/제목이 파싱된 경우 각각 아이콘과 함께 표시한다
class QuickInputPreview extends StatelessWidget {
  /// 표시할 파싱 결과
  final ParsedTodo parsed;

  const QuickInputPreview({super.key, required this.parsed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lgXl,
        AppSpacing.md,
        AppSpacing.lgXl,
        AppSpacing.mdLg,
      ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.xs,
        children: [
          // 날짜 표시: 파싱된 날짜가 있을 때만 보여준다
          if (parsed.hasDate)
            QuickInputPreviewChip(
              emoji: '📅',
              label: AppDateUtils.toShortDate(parsed.date!),
            ),
          // 시간 표시: 파싱된 시간이 있을 때만 보여준다
          if (parsed.hasTime)
            QuickInputPreviewChip(
              emoji: '⏰',
              label: _formatTime(parsed.time!),
            ),
          // 태그 표시: 파싱된 태그가 있을 때만 보여준다
          if (parsed.hasTags)
            ...parsed.tagNames.map(
              (name) => QuickInputPreviewChip(
                emoji: '🏷️',
                label: '#$name',
              ),
            ),
          // 제목 표시: 제목이 있을 때만 보여준다
          if (parsed.title.isNotEmpty)
            QuickInputPreviewChip(
              emoji: '✏️',
              label: parsed.title,
            ),
        ],
      ),
    );
  }

  /// TimeOfDay를 "오전/오후 H:MM" 형식으로 포맷한다
  String _formatTime(TimeOfDay time) {
    final isAm = time.hour < 12;
    final displayHour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minuteStr = time.minute.toString().padLeft(2, '0');
    final amPm = isAm ? '오전' : '오후';
    return '$amPm $displayHour:$minuteStr';
  }
}

/// 미리보기 개별 칩 위젯 (이모지 + 라벨 조합)
class QuickInputPreviewChip extends StatelessWidget {
  /// 앞에 표시할 이모지
  final String emoji;

  /// 표시할 텍스트 라벨
  final String label;

  const QuickInputPreviewChip({
    super.key,
    required this.emoji,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: AppTypography.captionMd,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: AppTypography.captionMd.copyWith(
            // 파싱 미리보기 라벨: 배경 테마에 맞는 악센트 색상을 사용한다
            color: context.themeColors.accent,
            fontWeight: AppTypography.weightSemiBold,
          ),
        ),
      ],
    );
  }
}
