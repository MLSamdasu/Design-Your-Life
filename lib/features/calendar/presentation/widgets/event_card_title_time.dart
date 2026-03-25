// F2 위젯: EventCardTitleTime - 이벤트 제목 + 시간 영역
// 완료 상태에 따라 취소선 draw/erase + 불투명도 애니메이션을 표시한다
import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';

/// 이벤트 카드 제목과 시간 텍스트 영역
/// 완료 시 취소선 draw 애니메이션과 불투명도 감소가 적용된다
class EventCardTitleTime extends StatelessWidget {
  /// 이벤트 제목
  final String title;

  /// 시작 시간 문자열 (null이면 시간 표시 안 함)
  final String? startTime;

  /// 종료 시간 문자열
  final String? endTime;

  /// 완료 여부
  final bool isCompleted;

  const EventCardTitleTime({
    super.key,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 공용 AnimatedStrikethrough로 취소선 draw/erase 애니메이션 적용
        AnimatedOpacity(
          opacity: isCompleted ? AppAnimation.completedTextAlpha : 1.0,
          duration: AppAnimation.textFade,
          curve: Curves.easeInOut,
          child: AnimatedStrikethrough(
            isActive: isCompleted,
            text: title,
            style: AppTypography.bodyLg.copyWith(
              color: context.themeColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (startTime != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          AnimatedOpacity(
            opacity: isCompleted ? AppAnimation.completedTextAlpha : 1.0,
            duration: AppAnimation.textFade,
            curve: Curves.easeInOut,
            child: Text(
              endTime != null ? '$startTime - $endTime' : startTime!,
              style: AppTypography.captionMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.60),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
