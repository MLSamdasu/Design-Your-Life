// C0.5: 애니메이션 디자인 토큰
// 앱 전체에서 사용하는 Duration 값을 정의한다.
// 하드코딩 금지: 반드시 이 클래스를 통해 참조한다.

/// 앱 전체 애니메이션 토큰
abstract class AppAnimation {
  // ─── 기본 지속 시간 ──────────────────────────────────────────────────
  /// 150ms - 즉각 피드백 (hover 상태 등)
  static const Duration instant = Duration(milliseconds: 150);

  /// 200ms - 빠른 전환 (버튼 프레스, 칩 선택)
  static const Duration fast = Duration(milliseconds: 200);

  /// 300ms - 일반 전환 (컨테이너 변경, opacity)
  static const Duration normal = Duration(milliseconds: 300);

  /// 350ms - 표준 전환 (네비게이션 아이템, iOS 기본 전환 속도)
  static const Duration standard = Duration(milliseconds: 350);

  /// 400ms - 중간 전환 (체크 애니메이션, 탭 전환)
  static const Duration medium = Duration(milliseconds: 400);

  /// 500ms - 느린 전환 (opacity 페이드, 체크박스 색상)
  static const Duration slow = Duration(milliseconds: 500);

  /// 550ms - 더 느린 전환 (복합 전환)
  static const Duration slower = Duration(milliseconds: 550);

  /// 600ms - 텍스트 페이드 인/아웃 (완료 상태 전환 시 사용)
  static const Duration textFade = Duration(milliseconds: 600);

  /// 650ms - 강조 전환
  static const Duration emphasis = Duration(milliseconds: 650);

  /// 750ms - 극적 전환
  static const Duration dramatic = Duration(milliseconds: 750);

  /// 800ms - 이펙트 (빨간펜 취소선, 차트 sweep 등)
  static const Duration effect = Duration(milliseconds: 800);

  // ─── 특수 지속 시간 ──────────────────────────────────────────────────
  /// 1500ms - 스켈레톤 시머 반복
  static const Duration shimmer = Duration(milliseconds: 1500);

  /// 2000ms - 스낵바 표시 / 부유 애니메이션
  static const Duration snackBar = Duration(milliseconds: 2000);

  /// 3000ms - 긴 메시지
  static const Duration longMessage = Duration(milliseconds: 3000);

  // ─── 스태거드 딜레이 ──────────────────────────────────────────────────
  /// 50ms - 리스트 아이템 스태거드 딜레이 단위
  static const int staggerDelayMs = 50;

  /// 350ms - 스태거드 딜레이 최대값 (clamp 상한)
  static const int staggerDelayMaxMs = 350;

  // ─── 부유/바운스 애니메이션 값 ─────────────────────────────────────────
  /// 4.0 - 부유 애니메이션 이동 범위 (px, 위아래)
  static const double floatOffset = 4.0;

  /// 6.0 - 부유 애니메이션 큰 이동 범위 (px, 위아래)
  static const double floatOffsetLg = 6.0;

  /// 1.15 - 체크박스 bounce 최대 스케일
  static const double bounceScale = 1.15;

  /// 0.05 - 카드 등장 슬라이드 시작 오프셋 (비율, 수직)
  static const double slideStartOffset = 0.05;

  /// 0.08 - 탭 전환 슬라이드 시작 오프셋 (비율, 수평)
  static const double tabSlideOffset = 0.08;

  // ─── 다이얼로그 전환 애니메이션 값 ─────────────────────────────────────
  /// 0.9 - 다이얼로그 Scale 전환 시작값
  static const double dialogScaleIn = 0.9;

  /// 0.88 - 위저드 Scale 전환 시작값
  static const double wizardScaleIn = 0.88;

  // ─── 배리어/오버레이 불투명도 ──────────────────────────────────────────
  /// 0.4 - 다이얼로그 배리어 불투명도
  static const double barrierAlpha = 0.4;

  /// 0.5 - 위저드 배리어 불투명도
  static const double barrierAlphaStrong = 0.5;

  /// 0.35 - 버튼 그림자 불투명도
  static const double buttonShadowAlpha = 0.35;

  /// 0.40 - CTA 버튼 그림자 불투명도
  static const double ctaButtonShadowAlpha = 0.40;

  // ─── 비활성/흐림 상태 불투명도 ──────────────────────────────────────────
  /// 0.4 - 비활성 버튼 배경 불투명도
  static const double disabledAlpha = 0.4;

  /// 0.3 - 흐림/딤 상태 불투명도 (Dismissible 배경, 딤 셀 등)
  static const double dimmedAlpha = 0.3;

  /// 0.6 - 에러 경계선 불투명도
  static const double errorBorderAlpha = 0.6;

  /// 0.5 - 완료된 항목 텍스트 불투명도 (취소선 텍스트)
  static const double completedTextAlpha = 0.5;

  /// 0.85 - 미완료 항목 텍스트 불투명도 (기본 활성 텍스트)
  static const double activeTextAlpha = 0.85;
}
