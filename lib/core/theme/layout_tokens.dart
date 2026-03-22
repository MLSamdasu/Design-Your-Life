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
  static const double iconNav = 24;

  /// 24px - 대형 아이콘 (스피너 등)
  static const double iconXxl = 24;

  /// 28px - 초대형 아이콘
  static const double iconHuge = 28;

  /// 48px - 빈 상태 아이콘
  static const double iconEmpty = 48;

  // ─── 시간 상수 ───────────────────────────────────────────────────────
  /// 하루 시간 수
  static const int hoursInDay = 24;

  /// 1시간 = 60분
  static const int minutesPerHour = 60;

  /// 일주일 일 수
  static const int daysInWeek = 7;

  /// 1년 = 12개월
  static const int monthsInYear = 12;

  /// 목표 연도 선택기 범위 (총 년수)
  static const int goalYearRange = 10;

  /// 목표 연도 선택기 과거 오프셋 (현재 연도 기준 과거 몇 년부터 표시)
  static const int goalYearPastOffset = 2;

  /// 타임테이블 시작 시간 (5시)
  static const int timetableStartHour = 5;

  /// 타임테이블 종료 시간 (23시)
  static const int timetableEndHour = 23;

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

  // ─── 컴포넌트 크기 ─────────────────────────────────────────────────
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

  // ─── 타임라인 ──────────────────────────────────────────────────────
  /// 60px - 투두/캘린더 일간 뷰 시간당 높이
  static const double timelineHourHeight = 60;

  /// 52px - 투두 일간 뷰 시간 라벨 열 너비
  static const double timelineTimeColumnLg = 52;

  /// 44px - 캘린더 주간 뷰 시간 라벨 열 너비
  static const double timelineTimeColumnMd = 44;

  /// 24px - 이벤트 블록 최소 높이
  static const double timelineMinBlockHeight = 24;

  /// 300px - 타임라인 하단 여백 (23시를 스크롤 중앙에 배치하기 위한 공간)
  /// 5시간 분량(timelineHourHeight * 5)으로, 끝까지 스크롤해도 23시가 화면 중간쯤에 위치한다
  static const double timelineBottomPadding = 300;

  /// 40px - 습관 주간 시간표 시간당 높이
  static const double timetableHourHeight = 40;

  /// 36px - 습관 주간 시간표 시간 라벨 너비
  static const double timetableTimeLabelWidth = 36;

  /// 44px - 습관 주간 시간표 요일 열 너비
  static const double timetableDayColumnWidth = 44;

  // ─── 아이콘 추가 크기 ──────────────────────────────────────────────────
  /// 11px - 초소형 아이콘 (체크마크 내부, 작은 뱃지)
  static const double iconXxs = 11;

  /// 12px - 극소형 아이콘 (XP 뱃지, 상태 표시)
  static const double iconXxxs = 12;

  /// 56px - 대형 빈 상태 아이콘
  static const double iconEmptyLg = 56;

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

  // ─── 추가 레이아웃 상수 ─────────────────────────────────────────────────
  /// 68px - 주간 뷰 헤더 높이 (요일 + 날짜 + 습관 완료율 표시)
  static const double weeklyHeaderHeight = 68;

  /// 80px - 일간 뷰 루틴/시간 열 너비
  static const double dailyRoutineColumnWidth = 80;

  /// 240px - 타이머 디스플레이 기본 크기
  static const double timerDisplaySize = 240;

  /// 10px - 타이머 원형 진행률 바 두께
  static const double timerStrokeWidth = 10;

  /// 5px - 캘린더 마커 크기
  static const double calendarMarkerSize = 5;

  /// 48px - 폼 버튼 높이
  static const double formButtonHeight = 48;

  // ─── 캘린더 타임라인 상수 ──────────────────────────────────────────────
  /// 56px - 주간 뷰 시간당 높이
  static const double weeklyHourHeight = 56;

  /// 120px - 주간 뷰 자동 스크롤 오프셋 (현재 시간이 화면 중앙에 오도록)
  static const double weeklyScrollOffset = 120;

  /// 100px - 일간 뷰 자동 스크롤 오프셋 (현재 시간이 화면 중앙에 오도록)
  static const double dailyScrollOffset = 100;

  /// 7px - 주간 뷰 시간 라벨 수직 보정값 (텍스트가 시간선과 정렬되도록)
  static const double weeklyTimeLabelOffset = 7;

  /// 8px - 일간 뷰 시간 라벨 수직 보정값 (텍스트가 시간선과 정렬되도록)
  static const double dailyTimeLabelOffset = 8;

  /// 20px - 주간 뷰 이벤트 블록 최소 높이
  static const double weeklyEventMinHeight = 20;

  /// 30px - 일간 뷰 이벤트/루틴 블록 최소 높이
  static const double dailyEventMinHeight = 30;

  /// 40px - 이벤트 블록 텍스트 2줄 전환 임계 높이 (일간 뷰)
  static const double dailyEventMultiLineThreshold = 40;

  /// 30px - 이벤트 블록 텍스트 2줄 전환 임계 높이 (주간 뷰)
  static const double weeklyEventMultiLineThreshold = 30;

  // ─── 색상 피커 ──────────────────────────────────────────────────────
  /// 28px - 색상 피커 원 기본 크기
  static const double colorPickerSize = 28;

  /// 34px - 색상 피커 원 선택 크기
  static const double colorPickerSelectedSize = 34;

  // ─── 블러/그림자 ────────────────────────────────────────────────────
  /// 24px - 모달 다이얼로그 블러 반경 (BackdropFilter sigmaX/Y)
  static const double modalBlurSigma = 24;

  /// 8px - 선택된 색상 피커 그림자 블러 반경
  static const double colorPickerShadowBlur = 8;

  /// 1px - 선택된 색상 피커 그림자 확산 반경
  static const double colorPickerShadowSpread = 1;

  // ─── FAB/엘리베이션 ─────────────────────────────────────────────────
  /// 0px - FAB 기본 엘리베이션 (그림자 없음)
  static const double elevationNone = 0;

  // ─── 투두 타임라인 스케줄 뷰 ──────────────────────────────────────────
  /// 80px - 일간 스케줄 현재 시간 자동 스크롤 여유 오프셋
  static const double scheduleAutoScrollOffset = 80;

  /// 0.30 - 일간 스케줄 좌측 통계 패널 너비 비율
  static const double scheduleStatsPanelRatio = 0.30;

  /// 120px - 일간 스케줄 좌측 통계 패널 최소 너비
  static const double scheduleStatsPanelMinWidth = 120;

  /// 160px - 일간 스케줄 좌측 통계 패널 최대 너비
  static const double scheduleStatsPanelMaxWidth = 160;

  /// 8px - 타임라인 시간 라벨과 이벤트 영역 사이 간격
  static const double timelineGutter = 8;

  /// 3 - 타임라인 겹침 이벤트 최대 표시 개수
  static const int timelineMaxVisibleOverlaps = 3;

  /// 3px - 현재 시간 인디케이터 Y축 보정값 (인디케이터 높이의 절반)
  static const double timelineCurrentTimeOffset = 3;

  // ─── 투두 이벤트 블록 ──────────────────────────────────────────────────
  /// 60px - 이벤트 블록 대형 임계 높이 (2줄 제목 + 시간 표시)
  static const double eventBlockLargeThreshold = 60;

  /// 40px - 이벤트 블록 중형 임계 높이 (1줄 제목 + 인라인 시간)
  static const double eventBlockMediumThreshold = 40;

  /// 30px - 이벤트 블록 소형 임계 높이 (1줄 제목만)
  static const double eventBlockSmallThreshold = 30;

  /// 6 - 매우 작은 이벤트 블록의 제목 잘림 글자 수
  static const int eventBlockTruncateLength = 6;

  /// 0.25 - 겹침 없는 이벤트 블록 배경 불투명도
  static const double eventBlockBgAlpha = 0.25;

  /// 0.20 - 겹침 이벤트 블록 배경 기본 불투명도
  static const double eventBlockOverlapBgAlphaBase = 0.20;

  /// 0.05 - 겹침 순서당 배경 불투명도 증가량
  static const double eventBlockOverlapBgAlphaStep = 0.05;

  /// 3.0px - 비겹침 이벤트 좌측 컬러 바 너비
  static const double eventBlockColorBarWidth = 3.0;

  /// 2.0px - 겹침 이벤트 좌측 컬러 바 기본 너비
  static const double eventBlockOverlapColorBarBase = 2.0;

  /// 0.5px - 겹침 순서당 좌측 컬러 바 너비 증가량
  static const double eventBlockOverlapColorBarStep = 0.5;

  // ─── 밀도 배경 불투명도 ───────────────────────────────────────────────
  /// 0.03 - 겹침 수 1 이하일 때 밀도 배경 불투명도
  static const double densityAlphaLow = 0.03;

  /// 0.06 - 겹침 수 2일 때 밀도 배경 불투명도
  static const double densityAlphaMedium = 0.06;

  /// 0.10 - 겹침 수 3 이상일 때 밀도 배경 불투명도
  static const double densityAlphaHigh = 0.10;

  // ─── 타임라인 캐스케이드 레이아웃 ─────────────────────────────────────────
  /// 0.75 - 겹침 2개일 때 각 이벤트 블록 너비 비율
  static const double cascadeWidth2 = 0.75;

  /// 0.25 - 겹침 2개일 때 컬럼 오프셋 스텝
  static const double cascadeOffset2 = 0.25;

  /// 0.65 - 겹침 3개 이상일 때 각 이벤트 블록 너비 비율
  static const double cascadeWidth3Plus = 0.65;

  /// 0.175 - 겹침 3개 이상일 때 컬럼 오프셋 스텝
  static const double cascadeOffset3Plus = 0.175;

  /// 30 - 종료 시간 미설정 시 기본 지속 시간 (분)
  static const int defaultDurationMinutes = 30;

  // ─── 연필 취소선 ───────────────────────────────────────────────────────
  /// 2.5px - 빨간 연필 취소선 두께
  static const double pencilStrokeWidth = 2.5;

  /// 0.85 - 빨간 연필 취소선 색상 불투명도
  static const double pencilStrokeAlpha = 0.85;

  /// 0.45 - 빨간 연필 취소선 텍스트 중앙 비율 (첫 줄 기준)
  static const double pencilStrokeCenterY = 0.45;

  /// 8.0px - 빨간 연필 취소선 세그먼트 간격
  static const double pencilSegmentWidth = 8.0;

  /// 2.4px - 빨간 연필 취소선 Y축 흔들림 범위 (전체 범위, +-half)
  static const double pencilWavinessRange = 2.4;

  // ─── 박스 그림자 ───────────────────────────────────────────────────────
  /// 0.12 - 겹침 이벤트 그림자 불투명도
  static const double overlapShadowAlpha = 0.12;

  /// 4px - 겹침 이벤트 그림자 블러 반경
  static const double overlapShadowBlur = 4;

  /// 0.30 - 오버플로우 뱃지 그림자 불투명도
  static const double badgeShadowAlpha = 0.30;

  /// 16px - CTA 버튼 그림자 블러 반경
  static const double ctaShadowBlur = 16;

  /// 4px - CTA 버튼 그림자 Y 오프셋
  static const double ctaShadowOffsetY = 4;

  // ─── 체크박스 애니메이션 ──────────────────────────────────────────────
  /// 0.3 - 체크박스 bounce 효과 최대 스케일 증가량
  static const double checkboxBounceScale = 0.3;

  /// 0.15 - 체크박스 bounce 효과 최소 스케일 감소량
  static const double checkboxShrinkScale = 0.15;

  // ─── 반응형 다이얼로그 ──────────────────────────────────────────────────
  /// 600px - 반응형 레이아웃 전환 임계 너비
  static const double responsiveBreakpointSm = 600;

  // ─── 스플래시 반경 ─────────────────────────────────────────────────────
  /// 18px - IconButton 스플래시 반경
  static const double iconButtonSplashRadius = 18;

  // ─── 투두 선택 시트 ───────────────────────────────────────────────────
  /// 0.6 - 드래그 시트 초기 크기 비율
  static const double sheetInitialSize = 0.6;

  /// 0.3 - 드래그 시트 최소 크기 비율
  static const double sheetMinSize = 0.3;

  /// 0.85 - 드래그 시트 최대 크기 비율
  static const double sheetMaxSize = 0.85;

  // ─── 빠른 지속 시간 버튼 간격 ──────────────────────────────────────────
  /// 6px - 빠른 지속 시간 버튼 간 간격
  static const double quickDurationGap = 6;

  // ─── 로딩 스피너 ──────────────────────────────────────────────────────
  /// 32px - 바텀시트 내부 로딩 스피너 크기
  static const double sheetSpinnerSize = 32;

  // ─── 타이머 디스플레이 ──────────────────────────────────────────────────
  /// 2.0 - 타이머 시간 텍스트 자간 (고정폭 시뮬레이션)
  static const double timerTimeLetterSpacing = 2.0;

  /// 0.65 - 타이머 원형 디스플레이 대비 투두 제목 너비 비율
  static const double timerTodoTitleWidthRatio = 0.65;

  // ─── 블러 시그마 (습관/루틴) ──────────────────────────────────────────────
  /// 16 - 서브탭/필터 글래스 블러 시그마
  static const double blurSigmaMd = 16;

  // ─── 타임테이블 추가 상수 ────────────────────────────────────────────────
  /// 7px - 타임테이블 시간 레이블 세로 오프셋 (텍스트 수직 중앙 정렬)
  static const double timetableTimeLabelOffset = 7;

  /// 15분 - 루틴 최소 지속 시간 (분)
  static const int routineMinDurationMinutes = 15;

  /// 1440분 - 하루 최대 분 (24시간 × 60분)
  static const int dayTotalMinutes = 1440;

  /// 8px - 루틴 블록 최소 높이 (시간표 내)
  static const double routineBlockMinHeight = 8;

  /// 20px - 루틴 블록 텍스트 표시 최소 높이 임계값
  static const double routineBlockTextThreshold = 20;

  // ─── 스켈레톤 카드 ───────────────────────────────────────────────────────
  /// 72px - 루틴 스켈레톤 카드 높이
  static const double routineSkeletonHeight = 72;

  /// 60px - 습관 스켈레톤 카드 높이
  static const double habitSkeletonHeight = 60;

  // ─── 캘린더 범위 ────────────────────────────────────────────────────────
  /// 2020 - 캘린더 시작 연도
  static const int calendarStartYear = 2020;

  /// 2030 - 캘린더 종료 연도
  static const int calendarEndYear = 2030;

  // ─── 스트릭 임계값 ──────────────────────────────────────────────────────
  /// 7 - 스트릭 강조 표시 임계값 (불꽃 이모지 + 골드 색상)
  static const int streakHighlightThreshold = 7;

  // ─── 팝업 메뉴 위치 ─────────────────────────────────────────────────────
  /// 120px - 팝업 메뉴 좌측 오프셋
  static const double popupMenuOffsetLeft = 120;

  /// 100px - 팝업 메뉴 하단 오프셋
  static const double popupMenuOffsetBottom = 100;

  // ─── 스위치/토글 ────────────────────────────────────────────────────────
  /// 0.8 - 소형 스위치 스케일
  static const double switchScaleSmall = 0.8;

  // ─── 다이얼로그/시트 비율 ─────────────────────────────────────────────────
  /// 0.5 - 바텀 시트 콘텐츠 최대 높이 비율
  static const double bottomSheetContentMaxRatio = 0.5;

  /// 0.85 - 다이얼로그 최대 높이 비율
  static const double dialogMaxHeightRatio = 0.85;

  // ─── 다이얼로그 진입 애니메이션 ─────────────────────────────────────────
  /// 0.9 - 다이얼로그 Scale 애니메이션 시작값
  static const double dialogScaleStart = 0.9;

  // ─── 텍스트 입력 제한 ──────────────────────────────────────────────────
  /// 50 - 루틴 이름 최대 글자 수
  static const int routineNameMaxLength = 50;

  /// 100 - 습관 이름 최대 글자 수
  static const int habitNameMaxLength = 100;

  /// 100 - 투두 제목 최대 글자 수
  static const int todoTitleMaxLength = 100;

  // ─── 타임테이블 헤더 ────────────────────────────────────────────────────
  /// 32px - 타임테이블 요일 헤더 행 높이 (iconHuge 28 + xs 4)
  static const double timetableHeaderHeight = 32;

  // ─── 블러 반경 (BoxShadow blurRadius) ─────────────────────────────────
  /// 0px - 블러 없음
  static const double blurRadiusNone = 0.0;

  /// 8px - 극소 블러 반경 (클린 카드 미세 그림자)
  static const double blurRadiusXs = 8.0;

  /// 12px - 작은 블러 반경
  static const double blurRadiusSm = 12.0;

  /// 16px - 중간 블러 반경
  static const double blurRadiusMd = 16.0;

  /// 20px - 큰 블러 반경
  static const double blurRadiusLg = 20.0;

  /// 24px - 매우 큰 블러 반경
  static const double blurRadiusXl = 24.0;

  /// 32px - 초대형 블러 반경
  static const double blurRadiusXxl = 32.0;

  /// 40px - 극대형 블러 반경
  static const double blurRadiusXxxl = 40.0;

  /// 48px - 최대 블러 반경
  static const double blurRadiusMax = 48.0;

  // ─── 블러 시그마 (BackdropFilter / blurSigma) ──────────────────────
  /// 0px - 블러 시그마 없음
  static const double blurSigmaNone = 0.0;

  /// 12px - 작은 블러 시그마 (네온 프리셋 약한 블러)
  static const double blurSigmaSm = 12.0;

  // ─── Glass 블러 시그마 (표준) ────────────────────────────────────────
  /// 20px - 표준 유리 블러 시그마 (Glass 카드, 모달 오버레이)
  static const double blurSigmaStandard = 20;

  /// 20px - 큰 블러 시그마 (blurSigmaStandard 별칭)
  static const double blurSigmaLg = 20.0;

  // ─── 스플래시/로고 아이콘 크기 ─────────────────────────────────────────
  /// 96px - 스플래시 로고 아이콘 크기
  static const double splashLogoSize = 96;

  /// 80px - 로그인 화면 앱 아이콘 크기
  static const double appIconSize = 80;

  // ─── 미니 카드 크기 (테마 프리뷰) ──────────────────────────────────────
  /// 50px - 테마 미리보기 미니 카드 너비
  static const double miniCardWidth = 50;

  /// 28px - 테마 미리보기 미니 카드 높이 (donutMini와 동일)
  static const double miniCardHeight = 28;

  // ─── 미니 카드 내부 줄 크기 ─────────────────────────────────────────────
  /// 3px - 미니 카드 타이틀 줄 높이
  static const double miniLineHeightLg = 3;

  /// 2px - 미니 카드 본문 줄 높이
  static const double miniLineHeightSm = 2;

  /// 24px - 미니 카드 타이틀 줄 너비
  static const double miniLineTitleWidth = 24;

  /// 36px - 미니 카드 본문 줄 너비
  static const double miniLineBodyWidth = 36;

  // ─── D-Day 섹션 높이 ────────────────────────────────────────────────
  /// 120px - D-Day 스켈레톤 높이
  static const double ddaySkeletonHeight = 120;

  /// 110px - D-Day 스켈레톤 카드 높이
  static const double ddaySkeletonCardHeight = 110;

  /// 130px - D-Day 목록 높이
  static const double ddayListHeight = 130;

  // ─── 빈 상태 아이콘 확장 ─────────────────────────────────────────────
  /// 64px - 태그 빈 상태 아이콘 크기
  static const double iconEmptyXl = 64;

  // ─── 디바이더 인덴트 ────────────────────────────────────────────────
  /// 56px - 태그 목록 디바이더 들여쓰기
  static const double tagDividerIndent = 56;

  // ─── 콘텐츠 라벨 너비 ────────────────────────────────────────────────
  /// 70px - 개인정보 동의 라벨 너비
  static const double consentLabelWidth = 70;

  // ─── 추가 아이콘 사이즈 ────────────────────────────────────────────────
  /// 13px - 체크마크 아이콘 크기 (테마 프리뷰 선택 체크)
  static const double iconCheckSm = 13;

  // ─── 루틴/타이머 아이콘 컨테이너 ────────────────────────────────────────
  /// 48px - 루틴/타이머 아이콘 컨테이너 크기
  static const double containerRoutine = 48;

  // ─── 업적 아이콘 컨테이너 ────────────────────────────────────────────
  /// 40px - 업적 요약 카드 아이콘 컨테이너 크기
  static const double containerAchievement = 40;

  // ─── Google 'G' 로고 컨테이너 ─────────────────────────────────────────
  /// 20px - Google 로고 컨테이너 크기
  static const double googleLogoSize = 20;

  // ─── 핸들 바 크기 ──────────────────────────────────────────────────────
  /// 36px - 바텀 시트 핸들 바 너비
  static const double handleBarWidth = 36;

  /// 4px - 바텀 시트 핸들 바 높이
  static const double handleBarHeight = 4;

  // ─── 이모지 폰트 사이즈 ────────────────────────────────────────────────
  /// 28px - 업적 카드 이모지 크기
  static const double emojiBadgeLg = 28;

  /// 36px - 업적 다이얼로그 이모지 크기
  static const double emojiDialogXl = 36;

  /// 38px - 스플래시 로고 이모지 크기
  static const double emojiSplash = 38;

  /// 32px - 로그인 앱 아이콘 이모지 크기
  static const double emojiAppIcon = 32;

  // ─── 온보딩 체크박스 ────────────────────────────────────────────────────
  /// 22px - 온보딩 동의 체크박스 크기
  static const double checkboxOnboarding = 22;

  // ─── 온보딩 스텝 인디케이터 ─────────────────────────────────────────────
  /// 24px - 스텝 인디케이터 활성 너비
  static const double stepIndicatorActiveWidth = 24;

  /// 8px - 스텝 인디케이터 비활성 너비
  static const double stepIndicatorInactiveWidth = 8;

  /// 8px - 스텝 인디케이터 높이 (온보딩)
  static const double stepIndicatorHeightLg = 8;

  // ─── 설정 시트 비율 ────────────────────────────────────────────────────
  /// 0.85 - 설정 모달 시트 초기 크기 비율
  static const double settingsSheetInitialSize = 0.85;

  /// 0.5 - 설정 모달 시트 최소 크기 비율
  static const double settingsSheetMinSize = 0.5;

  /// 0.95 - 설정 모달 시트 최대 크기 비율
  static const double settingsSheetMaxSize = 0.95;

  // ─── 업적 그리드 ──────────────────────────────────────────────────────
  /// 0.90 - 업적 카드 그리드 가로세로 비율
  static const double achievementGridAspectRatio = 0.90;

  // ─── 설정 그리드 ──────────────────────────────────────────────────────
  /// 1.2 - 테마 미리보기 카드 가로세로 비율
  static const double themePreviewAspectRatio = 1.2;

  // ─── 스켈레톤/플레이스홀더 (목표) ────────────────────────────────────────────
  /// 20px - 스켈레톤 텍스트 높이 (수치 플레이스홀더)
  static const double skeletonTextHeight = 20;

  /// 40px - 스켈레톤 텍스트 너비 (수치 플레이스홀더)
  static const double skeletonTextWidth = 40;

  // ─── 뱃지 (목표) ──────────────────────────────────────────────────────────
  /// 20px - 소형 뱃지 크기 (순번 표시 등)
  static const double badgeSm = 20;

  // ─── 스피너 (목표) ────────────────────────────────────────────────────────
  /// 16px - 소형 스피너 크기 (버튼 내부 로딩)
  static const double spinnerSm = 16;

  /// 2px - 소형 스피너 선 두께
  static const double spinnerStrokeWidth = 2;

  // ─── 인터랙티브 뷰어 ────────────────────────────────────────────────────
  /// 0.5 - InteractiveViewer 최소 배율
  static const double interactiveMinScale = 0.5;

  /// 3.0 - InteractiveViewer 최대 배율
  static const double interactiveMaxScale = 3.0;

  // ─── 만다라트 그리드 ────────────────────────────────────────────────────
  /// 2px - 만다라트 그리드 셀 간 간격
  static const double gridCellSpacing = 2;

  /// 9 - 만다라트 그리드 행/열 개수
  static const int mandalartGridSize = 9;

  /// 81 - 만다라트 그리드 전체 셀 수
  static const int mandalartCellCount = 81;

  /// 8 - 만다라트 세부목표/실천과제 수 (그리드당)
  static const int mandalartSubGoalCount = 8;

  /// 4 - 만다라트 그리드 중앙 인덱스 (9 ~/ 2)
  static const int mandalartCenterIndex = 4;

  /// 3 - 만다라트 위저드 단계 수
  static const int wizardStepCount = 3;

  // ─── 그림자 (목표/만다라트) ────────────────────────────────────────────────
  /// 12px - 중간 그림자 블러 반경 (버튼 호버 등)
  static const double shadowBlurMd = 12;

  /// 18px - 큰 그림자 블러 반경 (CTA 버튼 등)
  static const double shadowBlurLg = 18;

  /// 4px - 작은 그림자 오프셋 Y값
  static const double shadowOffsetSm = 4;

  /// 6px - 중간 그림자 오프셋 Y값
  static const double shadowOffsetMd = 6;

  // ─── FAB 엘리베이션 (목표) ────────────────────────────────────────────────
  /// 4.0 - FAB 기본 그림자 높이
  static const double fabElevation = 4.0;

  // ─── 인디케이터 (위저드) ──────────────────────────────────────────────────
  /// 4px - 단계 인디케이터 높이
  static const double stepIndicatorHeight = 4;

  // ─── 하단 여백 (목표 리스트) ──────────────────────────────────────────────
  /// 100px - FAB가 가리지 않도록 리스트 하단 여백
  static const double listBottomPaddingWithFab = 100;

  // ─── 로그인/온보딩 카드 패딩 ──────────────────────────────────────────
  /// 28px - Glass 로그인/온보딩 카드 내부 패딩
  static const double loginCardPadding = 28;

  // ─── 그림자 블러 반경 (추가) ──────────────────────────────────────────
  /// 20px - 중형 그림자 블러 반경 (앱 아이콘 등)
  static const double shadowBlurXl = 20;

  /// 32px - 대형 그림자 블러 반경 (로그인 카드 등)
  static const double shadowBlurXxl = 32;

  // ─── 그림자 오프셋 (추가) ────────────────────────────────────────────
  /// 8px - 큰 그림자 오프셋 Y값
  static const double shadowOffsetLg = 8;

  // ─── 타이포그래피 자간 ───────────────────────────────────────────────
  /// -0.8 - 타이트 자간 (로그인 타이틀 등)
  static const double letterSpacingTight = -0.8;

  /// -1.0 - 매우 타이트 자간 (스플래시 타이틀 등)
  static const double letterSpacingTighter = -1.0;

  // ─── 스켈레톤 반지름 (추가) ──────────────────────────────────────────
  /// 45px - 도넛 차트 스켈레톤 반원 반지름 (90px 원의 절반)
  static const double skeletonDonutRadius = 45;

  // ─── 스켈레톤 텍스트 폭 ──────────────────────────────────────────────
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

  // ─── 스켈레톤 텍스트 높이 ─────────────────────────────────────────────
  /// 16px - 큰 스켈레톤 텍스트 높이 (제목)
  static const double skeletonHeightLg = 16;

  /// 14px - 중간 스켈레톤 텍스트 높이
  static const double skeletonHeightMd = 14;

  /// 12px - 작은 스켈레톤 텍스트 높이 (부제)
  static const double skeletonHeightSm = 12;
}
