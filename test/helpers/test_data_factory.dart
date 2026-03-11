// 테스트 데이터 팩토리: 각 모델의 테스트 데이터를 생성하는 헬퍼
// Supabase 테이블 형식의 테스트 데이터를 일관되게 생성하여 테스트 코드 중복을 최소화한다.
// DateTime은 ISO 8601 문자열로 직렬화하여 실제 Supabase 응답과 동일한 형식을 사용한다.
// 컬럼명은 snake_case를 사용한다 (Supabase 컨벤션).

/// 테스트 기준 날짜
final testBaseDate = DateTime(2026, 3, 9);
final testBaseIso = testBaseDate.toIso8601String();
final testCreatedIso = DateTime(2026, 1, 1).toIso8601String();
final testUpdatedIso = DateTime(2026, 3, 9).toIso8601String();

/// 투두 Supabase Map 데이터를 생성한다
Map<String, dynamic> createTodoMap({
  String id = 'todo-1',
  String userId = 'user-1',
  String title = '테스트 투두',
  DateTime? date,
  String? startTime,
  bool isCompleted = false,
  String? color,
  String? memo,
  int displayOrder = 0,
  String? createdAt,
}) {
  return {
    'id': id,
    'user_id': userId,
    'title': title,
    'scheduled_date': _dateToLocalDateString(date ?? testBaseDate),
    if (startTime != null) 'start_time': startTime,
    'is_completed': isCompleted,
    'color': color,
    'memo': memo,
    'display_order': displayOrder,
    'created_at': createdAt ?? testCreatedIso,
  };
}

/// 습관 Supabase Map 데이터를 생성한다
Map<String, dynamic> createHabitMap({
  String id = 'habit-1',
  String userId = 'user-1',
  String name = '테스트 습관',
  String? icon = '💪',
  String? color,
  bool isActive = true,
  String? createdAt,
}) {
  return {
    'id': id,
    'user_id': userId,
    'name': name,
    'icon': icon,
    'color': color,
    'is_active': isActive,
    'created_at': createdAt ?? testCreatedIso,
  };
}

/// 습관 로그 Supabase Map 데이터를 생성한다
Map<String, dynamic> createHabitLogMap({
  String id = 'habit-1_2026-03-09',
  String habitId = 'habit-1',
  String userId = 'user-1',
  DateTime? date,
  bool isCompleted = true,
  DateTime? checkedAt,
}) {
  return {
    'id': id,
    'habit_id': habitId,
    'user_id': userId,
    'log_date': _dateToLocalDateString(date ?? testBaseDate),
    'is_completed': isCompleted,
    'completed_at': (checkedAt ?? testBaseDate).toIso8601String(),
  };
}

/// 루틴 Supabase Map 데이터를 생성한다
Map<String, dynamic> createRoutineMap({
  String id = 'routine-1',
  String userId = 'user-1',
  String name = '테스트 루틴',
  List<String> daysOfWeek = const ['MON', 'TUE', 'WED', 'THU', 'FRI'],
  String startTime = '09:00',
  String endTime = '10:00',
  String? color,
  bool isActive = true,
  String? createdAt,
  String? updatedAt,
}) {
  return {
    'id': id,
    'user_id': userId,
    'name': name,
    'days_of_week': daysOfWeek,
    'start_time': startTime,
    'end_time': endTime,
    'color': color,
    'is_active': isActive,
    'created_at': createdAt ?? testCreatedIso,
    'updated_at': updatedAt ?? testUpdatedIso,
  };
}

/// 이벤트 Supabase Map 데이터를 생성한다
Map<String, dynamic> createEventMap({
  String id = 'event-1',
  String userId = 'user-1',
  String title = '테스트 이벤트',
  String eventType = 'normal',
  DateTime? startDate,
  DateTime? endDate,
  bool allDay = false,
  String? color,
  String? location,
  String? memo,
  String? recurrenceRule,
  String? rangeTag,
  String? createdAt,
}) {
  return {
    'id': id,
    'user_id': userId,
    'title': title,
    'event_type': eventType,
    'start_date': (startDate ?? testBaseDate).toIso8601String(),
    if (endDate != null) 'end_date': endDate.toIso8601String(),
    'all_day': allDay,
    'color': color,
    if (location != null) 'location': location,
    if (memo != null) 'memo': memo,
    if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
    if (rangeTag != null) 'range_tag': rangeTag,
    'created_at': createdAt ?? testCreatedIso,
  };
}

/// 목표 Supabase Map 데이터를 생성한다
Map<String, dynamic> createGoalMap({
  String id = 'goal-1',
  String userId = 'user-1',
  String title = '테스트 목표',
  String? description,
  String period = 'yearly',
  int year = 2026,
  int? month,
  bool isCompleted = false,
  String? createdAt,
  String? updatedAt,
}) {
  return {
    'id': id,
    'user_id': userId,
    'title': title,
    'description': description,
    'period': period,
    'year': year,
    'month': month,
    'is_completed': isCompleted,
    'created_at': createdAt ?? testCreatedIso,
    'updated_at': updatedAt ?? testUpdatedIso,
  };
}

/// 하위 목표 Supabase Map 데이터를 생성한다
Map<String, dynamic> createSubGoalMap({
  String id = 'subgoal-1',
  String goalId = 'goal-1',
  String title = '테스트 하위 목표',
  bool isCompleted = false,
  int orderIndex = 0,
  String? createdAt,
}) {
  return {
    'id': id,
    'goal_id': goalId,
    'title': title,
    'is_completed': isCompleted,
    'order_index': orderIndex,
    'created_at': createdAt ?? testCreatedIso,
  };
}

/// 실천 할일 Supabase Map 데이터를 생성한다
Map<String, dynamic> createGoalTaskMap({
  String id = 'task-1',
  String subGoalId = 'subgoal-1',
  String title = '테스트 실천 할일',
  bool isCompleted = false,
  int orderIndex = 0,
  String? createdAt,
}) {
  return {
    'id': id,
    'sub_goal_id': subGoalId,
    'title': title,
    'is_completed': isCompleted,
    'order_index': orderIndex,
    'created_at': createdAt ?? testCreatedIso,
  };
}

/// DateTime을 "yyyy-MM-dd" 문자열로 변환한다
String _dateToLocalDateString(DateTime dt) {
  return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
