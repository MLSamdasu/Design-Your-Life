// C0.5: 애니메이션 디자인 토큰
// 앱 전체에서 사용하는 Duration 값을 정의한다.
// 하드코딩 금지: 반드시 이 클래스를 통해 참조한다.

/// 앱 전체 애니메이션 토큰
abstract class AppAnimation {
  // ─── 기본 지속 시간 ──────────────────────────────────────────────────
  /// 100ms - 즉각 피드백 (hover 상태 등)
  static const Duration instant = Duration(milliseconds: 100);

  /// 150ms - 빠른 전환 (버튼 프레스, 칩 선택)
  static const Duration fast = Duration(milliseconds: 150);

  /// 200ms - 일반 전환 (컨테이너 변경, opacity)
  static const Duration normal = Duration(milliseconds: 200);

  /// 250ms - 표준 전환 (네비게이션 아이템)
  static const Duration standard = Duration(milliseconds: 250);

  /// 300ms - 중간 전환 (체크 애니메이션, 탭 전환)
  static const Duration medium = Duration(milliseconds: 300);

  /// 350ms - 느린 전환
  static const Duration slow = Duration(milliseconds: 350);

  /// 400ms - 더 느린 전환
  static const Duration slower = Duration(milliseconds: 400);

  /// 500ms - 강조 전환
  static const Duration emphasis = Duration(milliseconds: 500);

  /// 600ms - 극적 전환
  static const Duration dramatic = Duration(milliseconds: 600);

  /// 800ms - 이펙트 (차트 sweep 등)
  static const Duration effect = Duration(milliseconds: 800);

  // ─── 특수 지속 시간 ──────────────────────────────────────────────────
  /// 1500ms - 스켈레톤 시머 반복
  static const Duration shimmer = Duration(milliseconds: 1500);

  /// 2000ms - 스낵바 표시 / 부유 애니메이션
  static const Duration snackBar = Duration(milliseconds: 2000);

  /// 3000ms - 긴 메시지
  static const Duration longMessage = Duration(milliseconds: 3000);
}
