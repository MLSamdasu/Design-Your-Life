// C0.5: 레이아웃 디자인 토큰 — 기타 (스플래시, 인증, 설정, 이모지, 미니 카드 등)
// 스플래시, 온보딩, 설정, 이모지, 핸들 바, 타이머, D-Day 등 개별 기능의 레이아웃 상수를 정의한다.

/// 기타 레이아웃 토큰 (스플래시, 인증/온보딩, 설정, 이모지, 미니 카드, 핸들 바, 타이머 등)
abstract class MiscLayout {
  // ─── 스플래시/로고 ──────────────────────────────────────────────────
  /// 96px - 스플래시 로고 아이콘 크기
  static const double splashLogoSize = 96;
  /// 80px - 로그인 화면 앱 아이콘 크기
  static const double appIconSize = 80;
  /// 20px - Google 로고 컨테이너 크기
  static const double googleLogoSize = 20;

  // ─── 이모지 폰트 사이즈 ────────────────────────────────────────────
  /// 28px - 업적 카드 이모지 크기
  static const double emojiBadgeLg = 28;
  /// 36px - 업적 다이얼로그 이모지 크기
  static const double emojiDialogXl = 36;
  /// 38px - 스플래시 로고 이모지 크기
  static const double emojiSplash = 38;
  /// 32px - 로그인 앱 아이콘 이모지 크기
  static const double emojiAppIcon = 32;

  // ─── 온보딩 ──────────────────────────────────────────────────────
  /// 22px - 온보딩 동의 체크박스 크기
  static const double checkboxOnboarding = 22;
  /// 24px - 스텝 인디케이터 활성 너비
  static const double stepIndicatorActiveWidth = 24;
  /// 8px - 스텝 인디케이터 비활성 너비
  static const double stepIndicatorInactiveWidth = 8;
  /// 8px - 스텝 인디케이터 높이 (온보딩)
  static const double stepIndicatorHeightLg = 8;

  // ─── 설정 시트 비율 ────────────────────────────────────────────────
  /// 0.85 - 설정 모달 시트 초기 크기 비율
  static const double settingsSheetInitialSize = 0.85;
  /// 0.5 - 설정 모달 시트 최소 크기 비율
  static const double settingsSheetMinSize = 0.5;
  /// 0.95 - 설정 모달 시트 최대 크기 비율
  static const double settingsSheetMaxSize = 0.95;

  // ─── 업적/테마 그리드 ──────────────────────────────────────────────
  /// 0.90 - 업적 카드 그리드 가로세로 비율
  static const double achievementGridAspectRatio = 0.90;
  /// 1.2 - 테마 미리보기 카드 가로세로 비율
  static const double themePreviewAspectRatio = 1.2;

  // ─── 미니 카드 (테마 프리뷰) ──────────────────────────────────────────
  /// 50px - 테마 미리보기 미니 카드 너비
  static const double miniCardWidth = 50;
  /// 28px - 테마 미리보기 미니 카드 높이 (donutMini와 동일)
  static const double miniCardHeight = 28;
  /// 3px - 미니 카드 타이틀 줄 높이
  static const double miniLineHeightLg = 3;
  /// 2px - 미니 카드 본문 줄 높이
  static const double miniLineHeightSm = 2;
  /// 24px - 미니 카드 타이틀 줄 너비
  static const double miniLineTitleWidth = 24;
  /// 36px - 미니 카드 본문 줄 너비
  static const double miniLineBodyWidth = 36;

  // ─── D-Day 섹션 ────────────────────────────────────────────────────
  /// 120px - D-Day 스켈레톤 높이
  static const double ddaySkeletonHeight = 120;
  /// 110px - D-Day 스켈레톤 카드 높이
  static const double ddaySkeletonCardHeight = 110;
  /// 130px - D-Day 목록 높이
  static const double ddayListHeight = 130;

  // ─── 핸들 바 ──────────────────────────────────────────────────────
  /// 36px - 바텀 시트 핸들 바 너비
  static const double handleBarWidth = 36;
  /// 4px - 바텀 시트 핸들 바 높이
  static const double handleBarHeight = 4;

  // ─── 투두 선택 시트 ───────────────────────────────────────────────
  /// 0.6 - 드래그 시트 초기 크기 비율
  static const double sheetInitialSize = 0.6;
  /// 0.3 - 드래그 시트 최소 크기 비율
  static const double sheetMinSize = 0.3;
  /// 0.85 - 드래그 시트 최대 크기 비율
  static const double sheetMaxSize = 0.85;
  /// 32px - 바텀시트 내부 로딩 스피너 크기
  static const double sheetSpinnerSize = 32;

  // ─── 타이머 디스플레이 ────────────────────────────────────────────────
  /// 240px - 타이머 디스플레이 기본 크기
  static const double timerDisplaySize = 240;
  /// 10px - 타이머 원형 진행률 바 두께
  static const double timerStrokeWidth = 10;
  /// 2.0 - 타이머 시간 텍스트 자간 (고정폭 시뮬레이션)
  static const double timerTimeLetterSpacing = 2.0;
  /// 0.65 - 타이머 원형 디스플레이 대비 투두 제목 너비 비율
  static const double timerTodoTitleWidthRatio = 0.65;

  // ─── 텍스트 입력 제한 ──────────────────────────────────────────────
  /// 50 - 루틴 이름 최대 글자 수
  static const int routineNameMaxLength = 50;
  /// 100 - 습관 이름 최대 글자 수
  static const int habitNameMaxLength = 100;
  /// 100 - 투두 제목 최대 글자 수
  static const int todoTitleMaxLength = 100;

  // ─── 콘텐츠/팝업/스위치/기타 ────────────────────────────────────────
  /// 70px - 개인정보 동의 라벨 너비
  static const double consentLabelWidth = 70;
  /// 120px - 팝업 메뉴 좌측 오프셋
  static const double popupMenuOffsetLeft = 120;
  /// 100px - 팝업 메뉴 하단 오프셋
  static const double popupMenuOffsetBottom = 100;
  /// 0.8 - 소형 스위치 스케일
  static const double switchScaleSmall = 0.8;
  /// 0.5 - 바텀 시트 콘텐츠 최대 높이 비율
  static const double bottomSheetContentMaxRatio = 0.5;
  /// 6px - 빠른 지속 시간 버튼 간 간격
  static const double quickDurationGap = 6;
  /// 18px - IconButton 스플래시 반경
  static const double iconButtonSplashRadius = 18;
  /// 28px - Glass 로그인/온보딩 카드 내부 패딩
  static const double loginCardPadding = 28;

  // ─── 스켈레톤 반지름/텍스트 폭/높이 ─────────────────────────────────
  /// 45px - 도넛 차트 스켈레톤 반원 반지름 (90px 원의 절반)
  static const double skeletonDonutRadius = 45;
  /// 180px - 넓은 스켈레톤 텍스트 폭 (긴 부제/설명)
  static const double skeletonWidthLg = 180;
  /// 120px - 중간 스켈레톤 텍스트 폭 (제목)
  static const double skeletonWidthMd = 120;
  /// 100px - 작은 스켈레톤 텍스트 폭 (짧은 제목)
  static const double skeletonWidthSm = 100;
  /// 80px - 좁은 스켈레톤 텍스트 폭 (부제/카운터)
  static const double skeletonWidthXs = 80;
  /// 70px - 최소 스켈레톤 텍스트 폭 (최소 부제)
  static const double skeletonWidthXxs = 70;
  /// 16px - 큰 스켈레톤 텍스트 높이 (제목)
  static const double skeletonHeightLg = 16;
  /// 14px - 중간 스켈레톤 텍스트 높이
  static const double skeletonHeightMd = 14;
  /// 12px - 작은 스켈레톤 텍스트 높이 (부제)
  static const double skeletonHeightSm = 12;

  // ─── 타이포그래피/디바이더/스트릭 ──────────────────────────────────
  /// -0.8 - 타이트 자간 (로그인 타이틀 등)
  static const double letterSpacingTight = -0.8;
  /// -1.0 - 매우 타이트 자간 (스플래시 타이틀 등)
  static const double letterSpacingTighter = -1.0;
  /// 56px - 태그 목록 디바이더 들여쓰기
  static const double tagDividerIndent = 56;
  /// 7 - 스트릭 강조 표시 임계값 (불꽃 이모지 + 골드 색상)
  static const int streakHighlightThreshold = 7;

  // ─── 추가 아이콘/컨테이너 ──────────────────────────────────────────
  /// 64px - 태그 빈 상태 아이콘 크기
  static const double iconEmptyXl = 64;
  /// 13px - 체크마크 아이콘 크기 (테마 프리뷰 선택 체크)
  static const double iconCheckSm = 13;
  /// 48px - 루틴/타이머 아이콘 컨테이너 크기
  static const double containerRoutine = 48;
  /// 40px - 업적 요약 카드 아이콘 컨테이너 크기
  static const double containerAchievement = 40;
}
