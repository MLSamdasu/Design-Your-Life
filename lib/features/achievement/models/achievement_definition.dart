// F8: 업적 정의 (하드코딩 상수)
// HabitPreset 패턴을 따라 앱 번들에 업적 정의를 하드코딩한다.
// 서버 공개 컬렉션 없이 즉시 사용 가능하도록 정적으로 포함한다.

/// 업적 달성 조건 모델
class AchievementCondition {
  /// 조건 유형 (streak_days / total_todos / total_habits / total_goals /
  ///            total_mandalarts / all_habits_today / early_bird)
  final String type;

  /// 달성 기준 수치 (연속일, 완료 수 등)
  final int threshold;

  const AchievementCondition({
    required this.type,
    required this.threshold,
  });
}

/// 업적 정의 모델 (앱 번들 하드코딩)
/// 서버에 저장하지 않고 코드에 고정하여 관리 복잡도를 낮춘다
class AchievementDef {
  /// 고유 ID (백엔드 레코드 ID로 사용하여 중복 잠금)
  final String id;

  /// 업적 유형 (streak / completion / milestone / special)
  final String type;

  final String title;
  final String description;

  /// 이모지 아이콘 문자열
  final String iconName;

  /// 달성 시 획득 XP
  final int xpReward;

  /// 달성 조건
  final AchievementCondition condition;

  const AchievementDef({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.iconName,
    required this.xpReward,
    required this.condition,
  });

  // ─── 전체 업적 정의 목록 (12개) ─────────────────────────────────────────

  /// 앱에서 제공하는 전체 업적 목록
  static const List<AchievementDef> all = [
    // ─── 스트릭 업적 ──────────────────────────────────────────────────────
    AchievementDef(
      id: 'streak_7',
      type: 'streak',
      title: '일주일 전사',
      description: '7일 연속으로 습관을 달성하세요',
      iconName: '🔥',
      xpReward: 50,
      condition: AchievementCondition(type: 'streak_days', threshold: 7),
    ),
    AchievementDef(
      id: 'streak_30',
      type: 'streak',
      title: '한 달의 힘',
      description: '30일 연속으로 습관을 달성하세요',
      iconName: '💎',
      xpReward: 200,
      condition: AchievementCondition(type: 'streak_days', threshold: 30),
    ),
    AchievementDef(
      id: 'streak_100',
      type: 'streak',
      title: '100일의 기적',
      description: '100일 연속으로 습관을 달성하세요',
      iconName: '👑',
      xpReward: 500,
      condition: AchievementCondition(type: 'streak_days', threshold: 100),
    ),

    // ─── 완료 업적 ──────────────────────────────────────────────────────
    AchievementDef(
      id: 'todo_first',
      type: 'completion',
      title: '첫 걸음',
      description: '첫 번째 할 일을 완료하세요',
      iconName: '✅',
      xpReward: 10,
      condition: AchievementCondition(type: 'total_todos', threshold: 1),
    ),
    AchievementDef(
      id: 'todo_50',
      type: 'completion',
      title: '실행가',
      description: '할 일 50개를 완료하세요',
      iconName: '📋',
      xpReward: 100,
      condition: AchievementCondition(type: 'total_todos', threshold: 50),
    ),
    AchievementDef(
      id: 'todo_100',
      type: 'completion',
      title: '완수의 달인',
      description: '할 일 100개를 완료하세요',
      iconName: '🏆',
      xpReward: 300,
      condition: AchievementCondition(type: 'total_todos', threshold: 100),
    ),
    AchievementDef(
      id: 'todo_500',
      type: 'completion',
      title: '생산성 마스터',
      description: '할 일 500개를 완료하세요',
      iconName: '⭐',
      xpReward: 500,
      condition: AchievementCondition(type: 'total_todos', threshold: 500),
    ),

    // ─── 마일스톤 업적 ──────────────────────────────────────────────────
    AchievementDef(
      id: 'habit_first',
      type: 'milestone',
      title: '습관의 시작',
      description: '첫 번째 습관을 만드세요',
      iconName: '🌱',
      xpReward: 10,
      condition: AchievementCondition(type: 'total_habits', threshold: 1),
    ),
    AchievementDef(
      id: 'goal_first',
      type: 'milestone',
      title: '목표 설정자',
      description: '첫 번째 목표를 만드세요',
      iconName: '🎯',
      xpReward: 10,
      condition: AchievementCondition(type: 'total_goals', threshold: 1),
    ),

    // ─── 특별 업적 ──────────────────────────────────────────────────────
    AchievementDef(
      id: 'mandalart_first',
      type: 'special',
      title: '만다라트 마스터',
      description: '만다라트 목표를 완성하세요',
      iconName: '🎨',
      xpReward: 200,
      condition: AchievementCondition(type: 'total_mandalarts', threshold: 1),
    ),
    AchievementDef(
      id: 'all_habits_day',
      type: 'special',
      title: '완벽한 하루',
      description: '오늘의 모든 습관을 달성하세요',
      iconName: '💯',
      xpReward: 50,
      condition: AchievementCondition(type: 'all_habits_today', threshold: 1),
    ),
    AchievementDef(
      id: 'early_bird',
      type: 'special',
      title: '얼리버드',
      description: '오전 6시 이전에 앱을 사용하세요',
      iconName: '🌅',
      xpReward: 30,
      condition: AchievementCondition(type: 'early_bird', threshold: 1),
    ),
  ];
}
