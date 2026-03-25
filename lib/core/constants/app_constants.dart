// C0.7: 앱 전역 상수
// 색상 팔레트 인덱스(0~7), 반응형 브레이크포인트, 날짜 포맷 문자열,
// Hive Box 이름, 인기 습관 프리셋 데이터 등 정적 상수를 정의한다.
import 'hive_keys.dart';

export 'hive_keys.dart';

/// 앱 전역 상수 모음
/// 변경 가능성이 낮은 고정 값들을 한 곳에서 관리한다
abstract class AppConstants {
  // ─── 입력 필드 길이 제한 ──────────────────────────────────────────────────
  static const int maxTitleLength = 200;
  static const int maxHabitNameLength = 100;
  static const int maxMemoLength = 2000;
  static const int maxLocationLength = 200;
  static const int maxDescriptionLength = 1000;
  static const int maxDisplayNameLength = 50;
  static const int minDisplayNameLength = 1;

  // ─── 색상 시스템 ────────────────────────────────────────────────────────
  static const int eventColorCount = 8;
  static const List<String> eventColorIds = [
    'work', 'personal', 'study', 'health',
    'social', 'finance', 'creative', 'important',
  ];

  // ─── 캘린더 ─────────────────────────────────────────────────────────────
  static const List<String> rangeTags = [
    'travel', 'exam', 'vacation', 'project', 'other',
  ];
  static const Map<String, String> rangeTagNames = {
    'travel': '여행', 'exam': '시험', 'vacation': '휴가',
    'project': '프로젝트', 'other': '기타',
  };

  // ─── 습관 프리셋 ─────────────────────────────────────────────────────────
  /// 앱 번들에 하드코딩된 인기 습관 프리셋
  static const List<Map<String, String>> habitPresets = [
    {'name': '운동 30분', 'icon': '🏃', 'description': '매일 30분 이상 운동하기'},
    {'name': '독서', 'icon': '📚', 'description': '매일 독서하기'},
    {'name': '물 2L', 'icon': '💧', 'description': '하루 물 2리터 마시기'},
    {'name': '영어 공부', 'icon': '💬', 'description': '매일 영어 학습하기'},
    {'name': '일기 쓰기', 'icon': '✏️', 'description': '매일 일기 쓰기'},
  ];

  // ─── D-day 긴급도 기준 ───────────────────────────────────────────────────
  static const int ddayCriticalThreshold = 3;
  static const int ddayWarningThreshold = 7;

  // ─── 반응형 브레이크포인트 ──────────────────────────────────────────────────
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopMaxContentWidth = 960;

  // ─── Hive Box 이름 ───────────────────────────────────────────────────────
  static const String userProfileBox = 'userProfileBox';
  static const String eventsBox = 'eventsBox';
  static const String todosBox = 'todosBox';
  static const String habitsBox = 'habitsBox';
  static const String habitLogsBox = 'habitLogsBox';
  static const String routinesBox = 'routinesBox';
  static const String routineLogsBox = 'routineLogsBox';
  static const String goalsBox = 'goalsBox';
  static const String subGoalsBox = 'subGoalsBox';
  static const String goalTasksBox = 'goalTasksBox';
  static const String timerLogsBox = 'timerLogsBox';
  static const String achievementsBox = 'achievementsBox';
  static const String tagsBox = 'tagsBox';
  static const String dailyRitualBox = 'dailyRitualBox';
  static const String dailyThreeBox = 'dailyThreeBox';
  static const String memosBox = 'memosBox';
  static const String settingsBox = 'settingsBox';
  static const String syncMetaBox = 'syncMetaBox';

  // ─── Hive 설정 키 (HiveKeys 위임, 하위 호환) ──────────────────────────────
  static const String settingsKeyDarkMode = HiveKeys.darkMode;
  static const String settingsKeyLastTab = HiveKeys.lastTab;
  static const String settingsKeyThemePreset = HiveKeys.themePreset;
  static const String settingsKeyNavSide = HiveKeys.navSide;
  static const String settingsKeyNavVerticalPos = HiveKeys.navVerticalPos;
  static const String settingsKeyNavSize = HiveKeys.navSize;
  static const String settingsKeyCalendarRatio = HiveKeys.calendarRatio;
  static const String settingsKeyHasSeenTutorial = HiveKeys.hasSeenTutorial;
  static const String settingsKeyLastBackupTime = HiveKeys.lastBackupTime;
  static const String settingsKeyTimerFocusMinutes = HiveKeys.timerFocusMinutes;
  static const String settingsKeyTimerShortBreakMinutes = HiveKeys.timerShortBreakMinutes;
  static const String settingsKeyTimerLongBreakMinutes = HiveKeys.timerLongBreakMinutes;
  static const String settingsKeyTimerSessionsBeforeLongBreak = HiveKeys.timerSessionsBeforeLongBreak;
  static const String settingsKeyDailyRitualEnabled = HiveKeys.dailyRitualEnabled;
  static const String settingsKeyGithubBackupInterval = HiveKeys.githubBackupInterval;
  static const String settingsKeyLastGithubBackupTime = HiveKeys.lastGithubBackupTime;

  // ─── 만다라트 ─────────────────────────────────────────────────────────────
  static const int mandalartGridSize = 9;
  static const int maxSubGoals = 8;
  static const int maxTasksPerSubGoal = 8;

  // ─── Rate Limiting ───────────────────────────────────────────────────────
  static const Duration habitCheckDebounce = Duration(milliseconds: 300);
  static const Duration searchDebounce = Duration(milliseconds: 500);

  // ─── 포모도로 타이머 ──────────────────────────────────────────────────────
  static const int pomodoroFocusSeconds = 25 * 60;
  static const int pomodoroShortBreakSeconds = 5 * 60;
  static const int pomodoroLongBreakSeconds = 15 * 60;
  static const int pomodoroSessionsBeforeLongBreak = 4;

  // ─── 날짜 포맷 ───────────────────────────────────────────────────────────
  static const String dateOnlyFormat = 'yyyy-MM-dd';
  static const String habitLogDateFormat = 'yyyy-MM-dd';

  // ─── 로컬 퍼스트 사용자 ID ─────────────────────────────────────────────
  /// 로컬 퍼스트 아키텍처에서 사용하는 기본 사용자 ID
  static const String localUserId = 'local_user';
}
