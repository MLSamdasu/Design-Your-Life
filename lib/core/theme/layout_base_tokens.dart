// C0.5: 레이아웃 디자인 토큰 — 기본 공통 토큰
// 앱 전체에서 가장 많이 참조되는 레이아웃 크기/제약 값을 정의한다.

/// 앱 기본 레이아웃 토큰 (다이얼로그, 터치 타겟, 아이콘, 시간 상수, 네비게이션, 카드, 테두리, 진행률 바, 색상 피커 등)
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

  /// 0.85 - 다이얼로그 최대 높이 비율
  static const double dialogMaxHeightRatio = 0.85;

  /// 0.9 - 다이얼로그 Scale 애니메이션 시작값
  static const double dialogScaleStart = 0.9;

  // ─── 터치 타겟 / 버튼 ────────────────────────────────────────────────
  /// 44px - WCAG 2.1 기준 최소 터치 타겟
  static const double minTouchTarget = 44;

  /// 28px - 최소 버튼 크기
  static const double minButtonSize = 28;

  /// 48px - 폼 버튼 높이
  static const double formButtonHeight = 48;

  // ─── 아이콘 크기 ─────────────────────────────────────────────────────
  /// 11px - 초소형 아이콘 (체크마크 내부, 작은 뱃지)
  static const double iconXxs = 11;

  /// 12px - 극소형 아이콘 (XP 뱃지, 상태 표시)
  static const double iconXxxs = 12;

  /// 14px - 소형 아이콘 (칩 내부, 작은 인디케이터)
  static const double iconSm = 14;

  /// 16px - 기본 아이콘 (리스트 아이템, 통계 카드)
  static const double iconMd = 16;

  /// 18px - 중형 아이콘 (버튼 내부)
  static const double iconLg = 18;

  /// 20px - 기본 큰 아이콘 (입력 필드, 습관 아이콘)
  static const double iconXl = 20;

  /// 22px - 네비게이션 아이콘
  static const double iconNav = 24;

  /// 24px - 대형 아이콘 (스피너 등)
  static const double iconXxl = 24;

  /// 28px - 초대형 아이콘
  static const double iconHuge = 28;

  /// 48px - 빈 상태 아이콘
  static const double iconEmpty = 48;

  /// 56px - 대형 빈 상태 아이콘
  static const double iconEmptyLg = 56;

  // ─── 시간 상수 ───────────────────────────────────────────────────────
  /// 하루 시간 수
  static const int hoursInDay = 24;

  /// 1시간 = 60분
  static const int minutesPerHour = 60;

  /// 일주일 일 수
  static const int daysInWeek = 7;

  /// 1년 = 12개월
  static const int monthsInYear = 12;

  // ─── 네비게이션 ──────────────────────────────────────────────────────
  /// 64px - 네비게이션 바 높이 (레거시, 하단→사이드 전환 후 참고용)
  static const double bottomNavHeight = 64;

  /// 16px - 하단 여백 (사이드 네비게이션 전환 후 최소 하단 마진)
  static const double bottomNavArea = 16;

  /// 56px - 사이드 네비게이션 레일 캡슐 기본 너비
  static const double sideNavWidth = 56;

  /// 48px - 사이드 네비게이션 레일 최소 너비 (WCAG 터치 타겟 보장)
  static const double sideNavWidthMin = 48;

  /// 80px - 사이드 네비게이션 레일 최대 너비 (화면 과점유 방지)
  static const double sideNavWidthMax = 80;

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

  // ─── 컴포넌트 크기 ───────────────────────────────────────────────────
  /// 32px - 중형 컨테이너 (아이콘 래퍼, 프로필 등)
  static const double containerMd = 32;

  /// 36px - 색상 선택 원, 폼 버튼
  static const double containerLg = 36;

  /// 80px - 대형 디스플레이 (업적 아이콘 등)
  static const double containerXl = 80;

  /// 4px - 색상 인디케이터 바 너비
  static const double colorBarWidth = 4;

  /// 36px - 색상 인디케이터 바 높이 (기본)
  static const double colorBarHeight = 36;

  // ─── 체크박스 ──────────────────────────────────────────────────────
  /// 20px - 기본 체크박스 크기
  static const double checkboxMd = 20;

  /// 24px - 대형 체크박스 크기
  static const double checkboxLg = 24;

  // ─── 진행률 바 ─────────────────────────────────────────────────────────
  /// 6px - 기본 진행률 바 높이
  static const double progressBarHeight = 6;

  /// 4px - 소형 진행률 바 높이 (서브 목표 카드 등)
  static const double progressBarHeightSm = 4;

  // ─── 테두리 두께 ───────────────────────────────────────────────────────
  /// 0.5px - 극세 테두리 (그리드 셀 구분)
  static const double borderHairline = 0.5;

  /// 1px - 기본 테두리
  static const double borderThin = 1;

  /// 1.5px - 중간 테두리 (체크박스, 시간 인디케이터)
  static const double borderMedium = 1.5;

  /// 2px - 두꺼운 테두리 (선택된 체크박스, 활성 상태)
  static const double borderThick = 2;

  /// 2.5px - 강조 테두리 (선택된 색상 피커)
  static const double borderAccent = 2.5;

  // ─── 구분선/선 두께 ────────────────────────────────────────────────────
  /// 1px - 기본 구분선 높이
  static const double dividerHeight = 1;

  /// 1.5px - 중간 구분선 (현재 시간 인디케이터 등)
  static const double lineHeightMedium = 1.5;

  /// 14px - 세로 구분선 높이 (세션 정보 구분)
  static const double separatorHeight = 14;

  // ─── 색상 피커 ──────────────────────────────────────────────────────
  /// 28px - 색상 피커 원 기본 크기
  static const double colorPickerSize = 28;

  /// 34px - 색상 피커 원 선택 크기
  static const double colorPickerSelectedSize = 34;

  // ─── 반응형 다이얼로그 ──────────────────────────────────────────────────
  /// 600px - 반응형 레이아웃 전환 임계 너비
  static const double responsiveBreakpointSm = 600;
}
