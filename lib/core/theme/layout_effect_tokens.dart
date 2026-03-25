// C0.5: 레이아웃 디자인 토큰 — 시각 효과 관련
// 블러, 그림자, 애니메이션, 불투명도 등 시각 효과에 사용하는 상수를 정의한다.

/// 시각 효과(블러, 그림자, 애니메이션, 불투명도) 레이아웃 토큰
abstract class EffectLayout {
  // ─── 블러 반경 (BoxShadow blurRadius) ─────────────────────────────
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

  /// 16 - 서브탭/필터 글래스 블러 시그마
  static const double blurSigmaMd = 16;

  /// 20px - 표준 유리 블러 시그마 (Glass 카드, 모달 오버레이)
  static const double blurSigmaStandard = 20;

  /// 20px - 큰 블러 시그마 (blurSigmaStandard 별칭)
  static const double blurSigmaLg = 20.0;

  /// 24px - 모달 다이얼로그 블러 반경 (BackdropFilter sigmaX/Y)
  static const double modalBlurSigma = 24;

  // ─── 박스 그림자 ───────────────────────────────────────────────────
  /// 12px - 중간 그림자 블러 반경 (버튼 호버 등)
  static const double shadowBlurMd = 12;

  /// 18px - 큰 그림자 블러 반경 (CTA 버튼 등)
  static const double shadowBlurLg = 18;

  /// 20px - 중형 그림자 블러 반경 (앱 아이콘 등)
  static const double shadowBlurXl = 20;

  /// 32px - 대형 그림자 블러 반경 (로그인 카드 등)
  static const double shadowBlurXxl = 32;

  /// 4px - 작은 그림자 오프셋 Y값
  static const double shadowOffsetSm = 4;

  /// 6px - 중간 그림자 오프셋 Y값
  static const double shadowOffsetMd = 6;

  /// 8px - 큰 그림자 오프셋 Y값
  static const double shadowOffsetLg = 8;

  // ─── 겹침 이벤트 그림자 ─────────────────────────────────────────────
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

  // ─── 색상 피커 그림자 ──────────────────────────────────────────────
  /// 8px - 선택된 색상 피커 그림자 블러 반경
  static const double colorPickerShadowBlur = 8;

  /// 1px - 선택된 색상 피커 그림자 확산 반경
  static const double colorPickerShadowSpread = 1;

  // ─── 밀도 배경 불투명도 ───────────────────────────────────────────────
  /// 0.03 - 겹침 수 1 이하일 때 밀도 배경 불투명도
  static const double densityAlphaLow = 0.03;

  /// 0.06 - 겹침 수 2일 때 밀도 배경 불투명도
  static const double densityAlphaMedium = 0.06;

  /// 0.10 - 겹침 수 3 이상일 때 밀도 배경 불투명도
  static const double densityAlphaHigh = 0.10;

  // ─── 타임라인 캐스케이드 레이아웃 ─────────────────────────────────────
  /// 0.75 - 겹침 2개일 때 각 이벤트 블록 너비 비율
  static const double cascadeWidth2 = 0.75;

  /// 0.25 - 겹침 2개일 때 컬럼 오프셋 스텝
  static const double cascadeOffset2 = 0.25;

  /// 0.65 - 겹침 3개 이상일 때 각 이벤트 블록 너비 비율
  static const double cascadeWidth3Plus = 0.65;

  /// 0.175 - 겹침 3개 이상일 때 컬럼 오프셋 스텝
  static const double cascadeOffset3Plus = 0.175;

  // ─── 체크박스 애니메이션 ──────────────────────────────────────────────
  /// 0.3 - 체크박스 bounce 효과 최대 스케일 증가량
  static const double checkboxBounceScale = 0.3;

  /// 0.15 - 체크박스 bounce 효과 최소 스케일 감소량
  static const double checkboxShrinkScale = 0.15;

  // ─── 연필 취소선 ───────────────────────────────────────────────────
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

  // ─── FAB/엘리베이션 ───────────────────────────────────────────────
  /// 0px - FAB 기본 엘리베이션 (그림자 없음)
  static const double elevationNone = 0;
}
