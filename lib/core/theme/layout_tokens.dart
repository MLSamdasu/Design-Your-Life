// C0.5: 레이아웃 디자인 토큰
// 앱 전체에서 사용하는 레이아웃 크기/제약 값을 정의한다.
// 하드코딩 금지: 반드시 이 클래스를 통해 참조한다.

/// 앱 전체 레이아웃 토큰
abstract class AppLayout {
  // ─── 다이얼로그 제약 ─────────────────────────────────────────────────
  /// 360px - 소형 다이얼로그 최대 너비
  static const double dialogMaxWidthSm = 360;

  /// 420px - 중형 다이얼로그 최대 너비
  static const double dialogMaxWidthMd = 420;

  /// 480px - 대형 다이얼로그 최대 너비
  static const double dialogMaxWidthLg = 480;

  /// 600px - 다이얼로그 최대 높이
  static const double dialogMaxHeight = 600;

  // ─── 터치 타겟 / 버튼 ────────────────────────────────────────────────
  /// 44px - WCAG 2.1 기준 최소 터치 타겟
  static const double minTouchTarget = 44;

  /// 28px - 최소 버튼 크기
  static const double minButtonSize = 28;

  // ─── 아이콘 크기 ─────────────────────────────────────────────────────
  /// 14px - 소형 아이콘 (칩 내부, 작은 인디케이터)
  static const double iconSm = 14;

  /// 16px - 기본 아이콘 (리스트 아이템, 통계 카드)
  static const double iconMd = 16;

  /// 18px - 중형 아이콘 (버튼 내부)
  static const double iconLg = 18;

  /// 20px - 기본 큰 아이콘 (입력 필드, 습관 아이콘)
  static const double iconXl = 20;

  /// 22px - 네비게이션 아이콘
  static const double iconNav = 22;

  /// 24px - 대형 아이콘 (스피너 등)
  static const double iconXxl = 24;

  /// 28px - 초대형 아이콘
  static const double iconHuge = 28;

  /// 48px - 빈 상태 아이콘
  static const double iconEmpty = 48;

  // ─── 시간 상수 ───────────────────────────────────────────────────────
  /// 하루 시간 수
  static const int hoursInDay = 24;

  /// 일주일 일 수
  static const int daysInWeek = 7;

  /// 타임테이블 시작 시간 (5시)
  static const int timetableStartHour = 5;

  /// 타임테이블 종료 시간 (23시)
  static const int timetableEndHour = 23;

  // ─── 네비게이션 ──────────────────────────────────────────────────────
  /// 56px - 하단 네비게이션 바 높이
  static const double bottomNavHeight = 56;

  /// 82px - 하단 네비게이션 영역 (바 높이 + 여백)
  static const double bottomNavArea = 82;

  /// 40px - 필터 바 높이
  static const double filterBarHeight = 40;

  // ─── 카드/컴포넌트 ───────────────────────────────────────────────────
  /// 140px - D-day 카드 최소 너비
  static const double ddayCardMinWidth = 140;

  /// 120px - 도넛 차트 (대형)
  static const double donutLarge = 120;

  /// 90px - 도넛 차트 (중형)
  static const double donutMedium = 90;

  /// 28px - 도넛 차트 (미니)
  static const double donutMini = 28;
}
