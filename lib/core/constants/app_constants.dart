// C0.7: 앱 전역 상수
// 색상 팔레트 인덱스(0~7), 반응형 브레이크포인트, 날짜 포맷 문자열,
// Hive Box 이름, 인기 습관 프리셋 데이터 등 정적 상수를 정의한다.

/// 앱 전역 상수 모음
/// 변경 가능성이 낮은 고정 값들을 한 곳에서 관리한다
abstract class AppConstants {
  // ─── 입력 필드 길이 제한 ──────────────────────────────────────────────────
  /// 일정/투두/루틴/목표 제목 최대 글자 수
  static const int maxTitleLength = 200;

  /// 습관 이름 최대 글자 수
  static const int maxHabitNameLength = 100;

  /// 메모 최대 글자 수
  static const int maxMemoLength = 2000;

  /// 위치 정보 최대 글자 수
  static const int maxLocationLength = 200;

  /// 목표 설명 최대 글자 수
  static const int maxDescriptionLength = 1000;

  /// 사용자 이름 최대 글자 수
  static const int maxDisplayNameLength = 50;

  /// 사용자 이름 최소 글자 수
  static const int minDisplayNameLength = 1;

  // ─── 색상 시스템 ────────────────────────────────────────────────────────
  /// 캘린더 이벤트/투두/루틴에서 선택 가능한 색상 수
  static const int eventColorCount = 8;

  /// 이벤트 색상 인덱스 매핑 (0~7)
  /// 0=work, 1=personal, 2=study, 3=health, 4=social, 5=finance, 6=creative, 7=important
  static const List<String> eventColorIds = [
    'work',
    'personal',
    'study',
    'health',
    'social',
    'finance',
    'creative',
    'important',
  ];

  // ─── 캘린더 ─────────────────────────────────────────────────────────────
  /// 범위 일정 태그 옵션 (서버 저장값)
  static const List<String> rangeTags = [
    'travel',
    'exam',
    'vacation',
    'project',
    'other',
  ];

  /// 범위 일정 태그 한국어 표시명
  static const Map<String, String> rangeTagNames = {
    'travel': '여행',
    'exam': '시험',
    'vacation': '휴가',
    'project': '프로젝트',
    'other': '기타',
  };

  // ─── 습관 프리셋 ─────────────────────────────────────────────────────────
  /// 앱 번들에 하드코딩된 인기 습관 프리셋
  /// 서버 API 호출 없이 즉시 사용 가능하도록 앱 번들에 하드코딩한다
  static const List<Map<String, String>> habitPresets = [
    {'name': '운동 30분', 'icon': '🏃', 'description': '매일 30분 이상 운동하기'},
    {'name': '독서', 'icon': '📚', 'description': '매일 독서하기'},
    {'name': '물 2L', 'icon': '💧', 'description': '하루 물 2리터 마시기'},
    {'name': '영어 공부', 'icon': '💬', 'description': '매일 영어 학습하기'},
    {'name': '일기 쓰기', 'icon': '✏️', 'description': '매일 일기 쓰기'},
  ];

  // ─── D-day 긴급도 기준 ───────────────────────────────────────────────────
  /// D-day critical 기준 (이 일수 이하 → 빨간색 강조)
  static const int ddayCriticalThreshold = 3;

  /// D-day warning 기준 (이 일수 이하 → 노란색 표시)
  static const int ddayWarningThreshold = 7;

  // ─── 반응형 브레이크포인트 ──────────────────────────────────────────────────
  /// 모바일 최대 너비 (px, < 600 = 모바일)
  static const double mobileBreakpoint = 600;

  /// 태블릿 최대 너비 (px, 600~900 = 태블릿)
  static const double tabletBreakpoint = 900;

  /// 데스크톱 콘텐츠 최대 너비 (px, 가운데 정렬)
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
  static const String settingsBox = 'settingsBox';
  static const String syncMetaBox = 'syncMetaBox';

  // ─── Hive 설정 키 ────────────────────────────────────────────────────────
  /// 다크 모드 설정 키
  static const String settingsKeyDarkMode = 'isDarkMode';

  /// 마지막 선택 탭 인덱스 키
  static const String settingsKeyLastTab = 'lastTabIndex';

  /// 테마 프리셋 설정 키 (ThemePreset.name 문자열로 저장)
  static const String settingsKeyThemePreset = 'themePreset';

  /// 네비게이션 바 좌/우 위치 키 ('left' | 'right')
  static const String settingsKeyNavSide = 'navSide';

  /// 네비게이션 바 수직 위치 키 (Alignment.y 값, -1.0 ~ 1.0)
  static const String settingsKeyNavVerticalPos = 'navVerticalPos';

  /// 네비게이션 바 크기 키 (double, 최소~최대 범위 내)
  static const String settingsKeyNavSize = 'navSize';

  /// 캘린더 월간뷰 캘린더/리스트 비율 키 (double, 0.3~0.7)
  static const String settingsKeyCalendarRatio = 'calendarRatio';

  // ─── 애니메이션 Duration ─────────────────────────────────────────────────
  // AppAnimation 토큰으로 통합됨:
  //   pageTransitionDuration → AppAnimation.standard (250ms)
  //   cardAppearDuration     → AppAnimation.slow (350ms)
  //   checkboxDuration       → AppAnimation.medium (300ms)
  //   donutChartDuration     → AppAnimation.effect (800ms)
  //   modalOpenDuration      → AppAnimation.standard (250ms)
  //   modalCloseDuration     → AppAnimation.normal (200ms)

  // ─── 만다라트 ─────────────────────────────────────────────────────────────
  /// 만다라트 전체 그리드 크기 (9x9)
  static const int mandalartGridSize = 9;

  /// 최대 세부 목표 수 (핵심 목표 주변 8개)
  static const int maxSubGoals = 8;

  /// 각 세부 목표당 최대 실천 과제 수
  static const int maxTasksPerSubGoal = 8;

  // ─── Rate Limiting ───────────────────────────────────────────────────────
  /// 습관 체크박스 디바운스 시간 (연속 탭 방지)
  static const Duration habitCheckDebounce = Duration(milliseconds: 300);

  /// 검색/필터 입력 디바운스 시간
  static const Duration searchDebounce = Duration(milliseconds: 500);

  // ─── 포모도로 타이머 ──────────────────────────────────────────────────────
  /// 포모도로 집중 시간 (초)
  static const int pomodoroFocusSeconds = 25 * 60;

  /// 짧은 휴식 시간 (초)
  static const int pomodoroShortBreakSeconds = 5 * 60;

  /// 긴 휴식 시간 (초)
  static const int pomodoroLongBreakSeconds = 15 * 60;

  /// 긴 휴식 전 필요한 포모도로 세션 횟수
  static const int pomodoroSessionsBeforeLongBreak = 4;

  // ─── Hive 설정 키 (튜토리얼) ────────────────────────────────────────────
  /// 앱 튜토리얼 완료 여부 설정 키 (bool)
  static const String settingsKeyHasSeenTutorial = 'hasSeenTutorial';

  // ─── Hive 설정 키 (백업 관련) ────────────────────────────────────────────
  /// 마지막 백업 시각 설정 키
  static const String settingsKeyLastBackupTime = 'lastBackupTime';

  // ─── Hive 설정 키 (타이머 설정) ────────────────────────────────────────
  /// 포모도로 집중 시간 설정 키 (int, 분 단위)
  static const String settingsKeyTimerFocusMinutes = 'timerFocusMinutes';

  /// 짧은 휴식 시간 설정 키 (int, 분 단위)
  static const String settingsKeyTimerShortBreakMinutes = 'timerShortBreakMinutes';

  /// 긴 휴식 시간 설정 키 (int, 분 단위)
  static const String settingsKeyTimerLongBreakMinutes = 'timerLongBreakMinutes';

  /// 긴 휴식 전 세션 횟수 설정 키 (int)
  static const String settingsKeyTimerSessionsBeforeLongBreak = 'timerSessionsBeforeLongBreak';

  // ─── 날짜 포맷 ───────────────────────────────────────────────────────────
  /// 날짜 전용 필드 포맷 (타임존 무관)
  static const String dateOnlyFormat = 'yyyy-MM-dd';

  /// HabitLog ID 날짜 포맷
  static const String habitLogDateFormat = 'yyyy-MM-dd';

  // ─── 로컬 퍼스트 사용자 ID ─────────────────────────────────────────────
  /// 로컬 퍼스트 아키텍처에서 사용하는 기본 사용자 ID
  /// 서버 없이 로컬 Hive에 저장할 때 user_id 필드에 사용한다
  static const String localUserId = 'local_user';
}
