// C0.5: 모서리 반지름 디자인 토큰
// 앱 전체에서 사용하는 BorderRadius 값을 정의한다.
// 하드코딩 금지: 반드시 이 클래스를 통해 참조한다.

/// 앱 전체 모서리 반지름 토큰
abstract class AppRadius {
  // ─── 기본 스케일 ──────────────────────────────────────────────────────
  /// 2px - 최소 반지름 (아이콘 내부, 인라인 요소)
  static const double xs = 2;

  /// 4px - 매우 작은 반지름 (진행바, 세부 요소)
  static const double sm = 4;

  /// 6px - 작은 반지름 (체크박스, 작은 컨테이너)
  static const double md = 6;

  /// 8px - 기본 반지름 (고스트 버튼, 작은 카드)
  static const double lg = 8;

  /// 10px - 중간 작은 반지름
  static const double lgXl = 10;

  /// 12px - 중간 반지름 (버튼, 입력 필드, 보조 카드)
  static const double xl = 12;

  /// 14px - 중간 큰 반지름 (주간 통계 카드)
  static const double xlLg = 14;

  /// 16px - 큰 반지름 (습관 필, D-day 카드)
  static const double xxl = 16;

  /// 20px - 매우 큰 반지름 (기본 카드, 스켈레톤)
  static const double huge = 20;

  /// 24px - 최대 반지름 (강조 카드, 다이얼로그)
  static const double massive = 24;

  /// 28px - 캡슐/바텀 시트
  static const double pill = 28;

  /// 32px - 큰 알약형 (레트로 모달)
  static const double pillLg = 32;

  /// 100px - 완전 원형 (네비게이션 아이템)
  static const double circle = 100;

  // ─── 시맨틱 반지름 ────────────────────────────────────────────────────
  /// 입력 필드 반지름 (12px)
  static const double input = 12;

  /// 카드 반지름 (20px)
  static const double card = 20;

  /// 버튼 반지름 (12px)
  static const double button = 12;

  /// 다이얼로그 반지름 (24px)
  static const double dialog = 24;

  /// 바텀 시트 반지름 (28px)
  static const double bottomSheet = 28;

  /// 칩 반지름 (8px)
  static const double chip = 8;

  /// FAB 반지름 (16px)
  static const double fab = 16;
}
