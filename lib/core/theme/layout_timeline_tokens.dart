// C0.5: 레이아웃 디자인 토큰 — 타임라인/캘린더/시간표 관련
// 캘린더, 타임라인, 시간표, 일간/주간 뷰에서 사용하는 레이아웃 상수를 정의한다.

/// 타임라인/캘린더/시간표 레이아웃 토큰
abstract class TimelineLayout {
  // ─── 타임라인 기본 ──────────────────────────────────────────────────
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

  /// 8px - 타임라인 시간 라벨과 이벤트 영역 사이 간격
  static const double timelineGutter = 8;

  /// 3 - 타임라인 겹침 이벤트 최대 표시 개수
  static const int timelineMaxVisibleOverlaps = 3;

  /// 3px - 현재 시간 인디케이터 Y축 보정값 (인디케이터 높이의 절반)
  static const double timelineCurrentTimeOffset = 3;

  // ─── 주간 뷰 ──────────────────────────────────────────────────────
  /// 56px - 주간 뷰 시간당 높이
  static const double weeklyHourHeight = 56;

  /// 120px - 주간 뷰 자동 스크롤 오프셋 (현재 시간이 화면 중앙에 오도록)
  static const double weeklyScrollOffset = 120;

  /// 7px - 주간 뷰 시간 라벨 수직 보정값 (텍스트가 시간선과 정렬되도록)
  static const double weeklyTimeLabelOffset = 7;

  /// 20px - 주간 뷰 이벤트 블록 최소 높이
  static const double weeklyEventMinHeight = 20;

  /// 30px - 이벤트 블록 텍스트 2줄 전환 임계 높이 (주간 뷰)
  static const double weeklyEventMultiLineThreshold = 30;

  /// 68px - 주간 뷰 헤더 높이 (요일 + 날짜 + 습관 완료율 표시)
  static const double weeklyHeaderHeight = 68;

  // ─── 일간 뷰 ──────────────────────────────────────────────────────
  /// 100px - 일간 뷰 자동 스크롤 오프셋 (현재 시간이 화면 중앙에 오도록)
  static const double dailyScrollOffset = 100;

  /// 8px - 일간 뷰 시간 라벨 수직 보정값 (텍스트가 시간선과 정렬되도록)
  static const double dailyTimeLabelOffset = 8;

  /// 30px - 일간 뷰 이벤트/루틴 블록 최소 높이
  static const double dailyEventMinHeight = 30;

  /// 40px - 이벤트 블록 텍스트 2줄 전환 임계 높이 (일간 뷰)
  static const double dailyEventMultiLineThreshold = 40;

  /// 80px - 일간 뷰 루틴/시간 열 너비
  static const double dailyRoutineColumnWidth = 80;

  // ─── 캘린더 범위 ────────────────────────────────────────────────────
  /// 5px - 캘린더 마커 크기
  static const double calendarMarkerSize = 5;

  /// 2020 - 캘린더 시작 연도
  static const int calendarStartYear = 2020;

  /// 2030 - 캘린더 종료 연도
  static const int calendarEndYear = 2030;

  // ─── 타임테이블 ────────────────────────────────────────────────────
  /// 7 - 타임테이블 시작 시간 (5시) (note: 원래 코드값 유지)
  static const int timetableStartHour = 5;

  /// 23 - 타임테이블 종료 시간 (23시)
  static const int timetableEndHour = 23;

  /// 40px - 습관 주간 시간표 시간당 높이
  static const double timetableHourHeight = 40;

  /// 36px - 습관 주간 시간표 시간 라벨 너비
  static const double timetableTimeLabelWidth = 36;

  /// 44px - 습관 주간 시간표 요일 열 너비
  static const double timetableDayColumnWidth = 44;

  /// 7px - 타임테이블 시간 레이블 세로 오프셋 (텍스트 수직 중앙 정렬)
  static const double timetableTimeLabelOffset = 7;

  /// 32px - 타임테이블 요일 헤더 행 높이 (iconHuge 28 + xs 4)
  static const double timetableHeaderHeight = 32;

  // ─── 루틴/습관 블록 ────────────────────────────────────────────────
  /// 15분 - 루틴 최소 지속 시간 (분)
  static const int routineMinDurationMinutes = 15;

  /// 1440분 - 하루 최대 분 (24시간 x 60분)
  static const int dayTotalMinutes = 1440;

  /// 8px - 루틴 블록 최소 높이 (시간표 내)
  static const double routineBlockMinHeight = 8;

  /// 20px - 루틴 블록 텍스트 표시 최소 높이 임계값
  static const double routineBlockTextThreshold = 20;

  /// 72px - 루틴 스켈레톤 카드 높이
  static const double routineSkeletonHeight = 72;

  /// 60px - 습관 스켈레톤 카드 높이
  static const double habitSkeletonHeight = 60;

  // ─── 스케줄 뷰 통계 ────────────────────────────────────────────────
  /// 80px - 일간 스케줄 현재 시간 자동 스크롤 여유 오프셋
  static const double scheduleAutoScrollOffset = 80;

  /// 0.30 - 일간 스케줄 좌측 통계 패널 너비 비율
  static const double scheduleStatsPanelRatio = 0.30;

  /// 120px - 일간 스케줄 좌측 통계 패널 최소 너비
  static const double scheduleStatsPanelMinWidth = 120;

  /// 160px - 일간 스케줄 좌측 통계 패널 최대 너비
  static const double scheduleStatsPanelMaxWidth = 160;

  /// 30 - 종료 시간 미설정 시 기본 지속 시간 (분)
  static const int defaultDurationMinutes = 30;

  // ─── 이벤트 블록 크기 임계값 ──────────────────────────────────────────
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
}
