// F3 위젯: TodoTitleSection - 투두 제목 + 시간 + 취소선 애니메이션
// 빨간 연필 취소선이 좌→우로 진행되며 완료 상태를 시각적으로 표현한다
import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import 'todo_strikethrough_painter.dart';

/// 투두 제목 텍스트 + 시간 표시 + 취소선 애니메이션을 포함하는 섹션
/// [strikethroughAnimation]의 진행도에 따라 취소선을 그린다
class TodoTitleSection extends StatelessWidget {
  final String title;
  final TimeOfDay? time;
  final Animation<double> strikethroughAnimation;

  const TodoTitleSection({
    required this.title,
    required this.time,
    required this.strikethroughAnimation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 텍스트 위에 빨간 연필 취소선을 그리기 위해 Stack 사용
        AnimatedBuilder(
          animation: strikethroughAnimation,
          builder: (context, _) {
            return Stack(
              children: [
                // 텍스트 본문 (기본 lineThrough 대신 커스텀 취소선 사용)
                AnimatedDefaultTextStyle(
                  duration: AppAnimation.slow,
                  curve: Curves.easeInOut,
                  style: AppTypography.bodyLg.copyWith(
                    // 취소선 애니메이션 완료 후 투명도를 낮춘다
                    color: Color.lerp(
                      context.themeColors.textPrimary,
                      context.themeColors.textPrimaryWithAlpha(0.5),
                      strikethroughAnimation.value,
                    ),
                  ),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 빨간 연필 취소선 (좌→우 애니메이션)
                if (strikethroughAnimation.value > 0)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: RedPencilStrikethroughPainter(
                        progress: strikethroughAnimation.value,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (time != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
            // WCAG: 시간 텍스트 알파 0.55 이상으로 가독성 보장
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.55),
            ),
          ),
        ],
      ],
    );
  }
}
