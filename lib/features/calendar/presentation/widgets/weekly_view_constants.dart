// F2 위젯: 주간 뷰 공용 상수 및 헬퍼 (SRP 분리)
// WeeklyEventBlock, WeeklyRoutineBlock 등에서 공유한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/animated_checkbox.dart';

// 1시간당 픽셀 높이 (TimelineLayout.weeklyHourHeight 토큰을 참조한다)
const double kWeeklyHourHeight = TimelineLayout.weeklyHourHeight;

/// 주간 뷰 타임라인 블록용 미니 체크박스 (CheckItem 스타일)
/// AnimatedCheckbox를 사용하여 스케일 바운스를 적용한다
/// 탭 이벤트는 부모 GestureDetector에서 처리하므로 onTap은 null이다
Widget buildWeeklyMiniCheckbox(BuildContext context, bool isCompleted) {
  return AnimatedCheckbox(
    isCompleted: isCompleted,
    size: AppLayout.iconSm,
  );
}
