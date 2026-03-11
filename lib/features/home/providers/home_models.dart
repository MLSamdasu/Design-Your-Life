// F1: 홈 대시보드 뷰 데이터 모델
// home_provider.dart에서 추출한다 (SRP 분리).
// 포함: TodoSummary, TodoPreviewItem, HabitSummary, HabitPreviewItem, DdayItem, WeeklySummary
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

/// 주간 요약
class WeeklySummary {
  final double todoWeekRate;
  final double habitWeekRate;

  const WeeklySummary({
    required this.todoWeekRate,
    required this.habitWeekRate,
  });

  static const empty = WeeklySummary(todoWeekRate: 0, habitWeekRate: 0);
}
