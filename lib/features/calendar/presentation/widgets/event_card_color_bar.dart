// F2 위젯: EventCardColorBar - 이벤트 카드 좌측 색상 인디케이터 바
// 완료 상태에 따라 불투명도가 애니메이션으로 변화한다
import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 이벤트 카드 좌측 색상 인디케이터 바
/// 4px 너비의 둥근 막대로, 완료 시 불투명도가 감소한다
class EventCardColorBar extends StatelessWidget {
  /// 인디케이터 색상
  final Color color;

  /// 완료 여부 (true면 불투명도 감소)
  final bool isCompleted;

  const EventCardColorBar({
    super.key,
    required this.color,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isCompleted ? AppAnimation.completedTextAlpha : 1.0,
      duration: AppAnimation.textFade,
      curve: Curves.easeInOut,
      child: Container(
        width: AppLayout.colorBarWidth,
        height: AppLayout.colorBarHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),
    );
  }
}
