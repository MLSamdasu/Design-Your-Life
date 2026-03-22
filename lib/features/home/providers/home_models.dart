// F1: 홈 대시보드 뷰 데이터 모델
// home_provider.dart에서 추출한다 (SRP 분리).
// 포함: TodoSummary, TodoPreviewItem, HabitSummary, HabitPreviewItem, DdayItem,
//   TodaySummary, UpcomingEventItem
import '../../../shared/enums/urgency_level.dart';

/// 오늘의 투두 요약
class TodoSummary {
  final int totalCount;
  final int completedCount;
  final double completionRate;
  // 홈 카드 미리보기용 (최대 5개)
  final List<TodoPreviewItem> previewItems;

  const TodoSummary({
    required this.totalCount,
    required this.completedCount,
    required this.completionRate,
    required this.previewItems,
  });

  static const empty = TodoSummary(
    totalCount: 0,
    completedCount: 0,
    completionRate: 0,
    previewItems: [],
  );
}

/// 투두 미리보기 아이템
class TodoPreviewItem {
  final String id;
  final String title;
  final bool isCompleted;

  const TodoPreviewItem({
    required this.id,
    required this.title,
    required this.isCompleted,
  });
}

/// 오늘의 습관 요약
class HabitSummary {
  final int totalCount;
  final int completedCount;
  final double achievementRate;
  // 홈 카드 미리보기용 (최대 3개)
  final List<HabitPreviewItem> previewItems;

  const HabitSummary({
    required this.totalCount,
    required this.completedCount,
    required this.achievementRate,
    required this.previewItems,
  });

  static const empty = HabitSummary(
    totalCount: 0,
    completedCount: 0,
    achievementRate: 0,
    previewItems: [],
  );
}

/// 습관 미리보기 아이템
class HabitPreviewItem {
  final String id;
  final String name;
  final String? icon;
  final bool isCompleted;
  final int streak;

  const HabitPreviewItem({
    required this.id,
    required this.name,
    this.icon,
    required this.isCompleted,
    required this.streak,
  });
}

/// D-day 아이템
class DdayItem {
  final String id;
  final String eventName;
  final int daysRemaining;
  final String dateLabel;
  final UrgencyLevel urgencyLevel;

  const DdayItem({
    required this.id,
    required this.eventName,
    required this.daysRemaining,
    required this.dateLabel,
    required this.urgencyLevel,
  });
}

/// 오늘의 루틴 요약
class RoutineSummary {
  final int total;
  // 시간순 정렬된 루틴 아이템 목록
  final List<RoutinePreviewItem> routineItems;

  const RoutineSummary({
    required this.total,
    required this.routineItems,
  });

  static const empty = RoutineSummary(total: 0, routineItems: []);
}

/// 루틴 미리보기 아이템
class RoutinePreviewItem {
  /// 루틴 ID (완료 토글에 필요하다)
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final int colorIndex;

  const RoutinePreviewItem({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.colorIndex,
  });
}

/// 오늘의 목표 요약 (현재 연도 기준)
class GoalSummary {
  /// 전체 목표 수
  final int totalCount;

  /// 완료된 목표 수
  final int completedCount;

  /// 달성률 (0.0 ~ 1.0)
  final double achievementRate;

  /// 평균 진행률 (0.0 ~ 1.0)
  final double avgProgress;

  const GoalSummary({
    required this.totalCount,
    required this.completedCount,
    required this.achievementRate,
    required this.avgProgress,
  });

  static const empty = GoalSummary(
    totalCount: 0,
    completedCount: 0,
    achievementRate: 0,
    avgProgress: 0,
  );
}

/// 다가오는 일정 아이템 (이벤트 + 미완료 투두 통합)
class UpcomingEventItem {
  /// 이벤트 또는 투두 ID
  final String id;

  /// 일정/투두 제목
  final String title;

  /// 시간 라벨 ("14:00 ~ 15:30" 또는 "종일")
  final String timeLabel;

  /// 색상 인덱스 (0~8, ColorTokens.eventColor 참조)
  final int colorIndex;

  /// 투두에서 변환된 항목인지 여부
  final bool isTodoEvent;

  /// 투두 완료 여부 (isTodoEvent가 true일 때만 유의미하다)
  final bool isCompleted;

  const UpcomingEventItem({
    required this.id,
    required this.title,
    required this.timeLabel,
    required this.colorIndex,
    required this.isTodoEvent,
    this.isCompleted = false,
  });
}

/// 오늘의 요약 (투두 완료율 + 습관 달성률)
class TodaySummary {
  final double todoTodayRate;
  final double habitTodayRate;

  const TodaySummary({
    required this.todoTodayRate,
    required this.habitTodayRate,
  });

  static const empty = TodaySummary(todoTodayRate: 0, habitTodayRate: 0);
}
