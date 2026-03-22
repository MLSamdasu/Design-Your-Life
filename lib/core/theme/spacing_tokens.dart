// C0.5: 간격 디자인 토큰
// 앱 전체에서 사용하는 패딩, 마진, 갭 값을 정의한다.
// 하드코딩 금지: 반드시 이 클래스를 통해 참조한다.

/// 앱 전체 간격 토큰
abstract class AppSpacing {
  // ─── 기본 간격 스케일 ──────────────────────────────────────────────────
  /// 2px - 최소 간격 (아이콘 내부, 인라인 요소)
  static const double xxs = 2;

  /// 4px - 매우 좁은 간격 (칩 내부 패딩, 텍스트 사이)
  static const double xs = 4;

  /// 6px - 좁은 간격 (리스트 아이템 사이, 라벨-값 사이)
  static const double sm = 6;

  /// 8px - 기본 작은 간격 (카드 내부 요소 사이)
  static const double md = 8;

  /// 10px - 중간 작은 간격
  static const double mdLg = 10;

  /// 12px - 기본 중간 간격 (폼 필드 패딩, 리스트 간격)
  static const double lg = 12;

  /// 14px - 중간 간격 변형
  static const double lgXl = 14;

  /// 16px - 표준 간격 (섹션 내부 패딩)
  static const double xl = 16;

  /// 20px - 큰 간격 (카드/섹션 패딩)
  static const double xxl = 20;

  /// 24px - 매우 큰 간격 (섹션 사이, 다이얼로그 패딩)
  static const double xxxl = 24;

  /// 32px - 최대 간격 (페이지 패딩, 섹션 분리)
  static const double huge = 32;

  /// 40px - 초대형 간격
  static const double massive = 40;

  /// 48px - 초대형 간격 2
  static const double enormous = 48;

  // ─── 시맨틱 간격 ───────────────────────────────────────────────────────
  /// 카드 내부 패딩 (20px)
  static const double cardPadding = 20;

  /// 다이얼로그 내부 패딩 (24px)
  static const double dialogPadding = 24;

  /// 페이지 수평 패딩 (20px)
  static const double pageHorizontal = 20;

  /// 페이지 수직 패딩 (16px)
  static const double pageVertical = 16;

  /// 폼 필드 내부 패딩 (12px)
  static const double inputPadding = 12;

  /// 리스트 아이템 간 간격 (12px)
  static const double listItemGap = 12;

  /// 섹션 간 간격 (24px)
  static const double sectionGap = 24;

  /// 하단 영역 여분 (24px) - 사이드 네비게이션 전환 후 최소 스크롤 여백
  static const double bottomScrollPadding = 24;
}
