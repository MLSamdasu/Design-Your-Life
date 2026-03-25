// C0.5: 레이아웃 디자인 토큰 — 목표/만다라트/위저드 관련
// 목표(Goal), 만다라트(Mandalart), 위저드(Wizard) 기능에서 사용하는 레이아웃 상수를 정의한다.

/// 목표/만다라트/위저드 레이아웃 토큰
abstract class GoalLayout {
  // ─── 목표 연도 범위 ──────────────────────────────────────────────────
  /// 10 - 목표 연도 선택기 범위 (총 년수)
  static const int goalYearRange = 10;

  /// 2 - 목표 연도 선택기 과거 오프셋 (현재 연도 기준 과거 몇 년부터 표시)
  static const int goalYearPastOffset = 2;

  // ─── 만다라트 그리드 ────────────────────────────────────────────────
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

  // ─── 인터랙티브 뷰어 ────────────────────────────────────────────────
  /// 0.5 - InteractiveViewer 최소 배율
  static const double interactiveMinScale = 0.5;

  /// 3.0 - InteractiveViewer 최대 배율
  static const double interactiveMaxScale = 3.0;

  // ─── FAB 엘리베이션 ──────────────────────────────────────────────────
  /// 4.0 - FAB 기본 그림자 높이
  static const double fabElevation = 4.0;

  // ─── 인디케이터 (위저드) ──────────────────────────────────────────────
  /// 4px - 단계 인디케이터 높이
  static const double stepIndicatorHeight = 4;

  // ─── 하단 여백 (목표 리스트) ──────────────────────────────────────────
  /// 100px - FAB가 가리지 않도록 리스트 하단 여백
  static const double listBottomPaddingWithFab = 100;

  // ─── 스켈레톤/플레이스홀더 ────────────────────────────────────────────
  /// 20px - 스켈레톤 텍스트 높이 (수치 플레이스홀더)
  static const double skeletonTextHeight = 20;

  /// 40px - 스켈레톤 텍스트 너비 (수치 플레이스홀더)
  static const double skeletonTextWidth = 40;

  // ─── 뱃지 ────────────────────────────────────────────────────────
  /// 20px - 소형 뱃지 크기 (순번 표시 등)
  static const double badgeSm = 20;

  // ─── 스피너 ──────────────────────────────────────────────────────
  /// 16px - 소형 스피너 크기 (버튼 내부 로딩)
  static const double spinnerSm = 16;

  /// 2px - 소형 스피너 선 두께
  static const double spinnerStrokeWidth = 2;
}
