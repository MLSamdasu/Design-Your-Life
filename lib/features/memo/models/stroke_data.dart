// F7-M1: 드로잉 스트로크 데이터 모델
// 메모 캔버스의 각 스트로크(선분)를 표현하는 불변 모델이다.
// 입력: 사용자 터치/펜 포인트 (x, y, pressure)
// 출력: JSON 직렬화/역직렬화 가능한 StrokeData 객체

/// 캔버스 위의 단일 포인트 (좌표 + 필압)
/// Apple Pencil / S Pen의 pressure 값을 보존한다
class PointData {
  final double x;
  final double y;

  /// 필압 (0.0~1.0, 미지원 기기에서는 0.5 기본값)
  final double pressure;

  const PointData({
    required this.x,
    required this.y,
    this.pressure = 0.5,
  });

  /// JSON 맵으로 변환한다
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'p': pressure,
      };

  /// JSON 맵에서 복원한다
  factory PointData.fromJson(Map<String, dynamic> json) => PointData(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        pressure: (json['p'] as num?)?.toDouble() ?? 0.5,
      );
}

/// 하나의 연속된 스트로크 (시작~끝까지 손가락/펜을 떼지 않은 선)
/// 포인트 목록 + 색상 + 두께를 포함한다
class StrokeData {
  /// 스트로크를 구성하는 포인트 목록
  final List<PointData> points;

  /// 색상값 (Color.value 정수)
  final int colorValue;

  /// 펜 두께 (px)
  final double width;

  const StrokeData({
    required this.points,
    required this.colorValue,
    required this.width,
  });

  /// JSON 맵으로 변환한다
  Map<String, dynamic> toJson() => {
        'pts': points.map((p) => p.toJson()).toList(),
        'c': colorValue,
        'w': width,
      };

  /// JSON 맵에서 복원한다
  factory StrokeData.fromJson(Map<String, dynamic> json) => StrokeData(
        points: (json['pts'] as List)
            .map((p) => PointData.fromJson(p as Map<String, dynamic>))
            .toList(),
        colorValue: json['c'] as int,
        width: (json['w'] as num).toDouble(),
      );
}
