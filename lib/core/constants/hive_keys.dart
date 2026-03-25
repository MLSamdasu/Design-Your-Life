// C0.7: Hive 설정 키 상수
// Hive settingsBox에서 사용하는 키 문자열을 한 곳에서 관리한다 (SRP 분리)

/// Hive settingsBox 설정 키 모음
/// 사용자 설정(테마, 네비게이션, 타이머, 백업 등)의 키 문자열을 관리한다
abstract class HiveKeys {
  /// 다크 모드 설정 키
  static const String darkMode = 'isDarkMode';

  /// 마지막 선택 탭 인덱스 키
  static const String lastTab = 'lastTabIndex';

  /// 테마 프리셋 설정 키 (ThemePreset.name 문자열로 저장)
  static const String themePreset = 'themePreset';

  /// 네비게이션 바 좌/우 위치 키 ('left' | 'right')
  static const String navSide = 'navSide';

  /// 네비게이션 바 수직 위치 키 (Alignment.y 값, -1.0 ~ 1.0)
  static const String navVerticalPos = 'navVerticalPos';

  /// 네비게이션 바 크기 키 (double, 최소~최대 범위 내)
  static const String navSize = 'navSize';

  /// 캘린더 월간뷰 캘린더/리스트 비율 키 (double, 0.3~0.7)
  static const String calendarRatio = 'calendarRatio';

  /// 앱 튜토리얼 완료 여부 설정 키 (bool)
  static const String hasSeenTutorial = 'hasSeenTutorial';

  /// 마지막 백업 시각 설정 키
  static const String lastBackupTime = 'lastBackupTime';

  /// 포모도로 집중 시간 설정 키 (int, 분 단위)
  static const String timerFocusMinutes = 'timerFocusMinutes';

  /// 짧은 휴식 시간 설정 키 (int, 분 단위)
  static const String timerShortBreakMinutes = 'timerShortBreakMinutes';

  /// 긴 휴식 시간 설정 키 (int, 분 단위)
  static const String timerLongBreakMinutes = 'timerLongBreakMinutes';

  /// 긴 휴식 전 세션 횟수 설정 키 (int)
  static const String timerSessionsBeforeLongBreak = 'timerSessionsBeforeLongBreak';

  /// 데일리 리추얼 활성화 여부 설정 키 (bool)
  /// true: 매일 앱 시작 시 리추얼 화면을 표시한다 (기본값)
  static const String dailyRitualEnabled = 'dailyRitualEnabled';

  /// GitHub Personal Access Token 저장 키 (String, 암호화 박스 사용)
  static const String githubToken = 'githubToken';

  /// GitHub 사용자 이름 저장 키 (String)
  static const String githubUsername = 'githubUsername';

  /// GitHub 자동 백업 주기 설정 키 (int, 시간 단위: 1/6/12/24)
  static const String githubBackupInterval = 'githubBackupInterval';

  /// 마지막 GitHub 백업 시각 설정 키 (String, ISO 8601)
  static const String lastGithubBackupTime = 'lastGithubBackupTime';
}
