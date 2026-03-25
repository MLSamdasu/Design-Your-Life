// 도넛 차트 설정: 크기/타입 열거형 및 치수 상수
// DonutChart 위젯에서 사용하는 열거형, 크기 상수, 치수 헬퍼를 분리하여 관리한다.
import '../../core/theme/layout_tokens.dart';

/// 도넛 차트 크기 유형
enum DonutChartSize {
  /// 투두/습관 화면 메인 차트 (120px)
  large,

  /// 대시보드 카드 차트 (90px)
  medium,

  /// 습관 캘린더 미니 차트 (28px)
  mini,
}

/// 도넛 차트 색상 유형
enum DonutChartType {
  /// 투두 완료율 (흰색 계열)
  todo,

  /// 습관 달성률 (초록 계열)
  habit,
}

/// 도넛 차트 치수 상수 및 헬퍼
/// 크기별 차트 직경, 스트로크 너비, 중앙 반지름을 제공한다.
abstract final class DonutChartDimensions {
  /// 미니 도넛 차트 스트로크 너비
  static const double strokeMini = 3;

  /// 대형 도넛 차트 중앙 반지름
  static const double centerRadiusLarge = 45;

  /// 중형 도넛 차트 중앙 반지름
  static const double centerRadiusMedium = 35;

  /// 미니 도넛 차트 중앙 반지름
  static const double centerRadiusMini = 10;

  /// 크기 유형별 차트 직경 반환
  static double chartSize(DonutChartSize size) => switch (size) {
        DonutChartSize.large => AppLayout.donutLarge,
        DonutChartSize.medium => AppLayout.donutMedium,
        DonutChartSize.mini => AppLayout.donutMini,
      };

  /// 크기 유형별 스트로크 너비 반환
  static double strokeWidth(DonutChartSize size) => switch (size) {
        // 대형 도넛 차트: 타이머 스트로크 너비 토큰 (10px)
        DonutChartSize.large => MiscLayout.timerStrokeWidth,
        // 중형 도넛 차트: 기본 중간 간격 토큰 (8px)
        DonutChartSize.medium => AppLayout.iconMd / 2,
        // 미니 도넛 차트: 최소 스트로크 (3px)
        DonutChartSize.mini => strokeMini,
      };

  /// 크기 유형별 중앙 빈 공간 반지름 반환
  static double centerSpaceRadius(DonutChartSize size) => switch (size) {
        DonutChartSize.large => centerRadiusLarge,
        DonutChartSize.medium => centerRadiusMedium,
        DonutChartSize.mini => centerRadiusMini,
      };
}
