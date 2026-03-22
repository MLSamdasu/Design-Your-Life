// 공유 모델: Tag (태그/카테고리)
// Hive tagsBox에 저장되는 태그 모델이다.
// 필드: id, user_id, name, color_index, created_at
import '../../core/utils/date_parser.dart';
import '../../core/error/app_exception.dart';

/// 태그 모델
/// Hive tagsBox에 저장된다
class Tag {
  final String id;
  final String userId;

  /// 태그 이름 (최대 20자)
  final String name;

  /// 태그 색상 인덱스 (0~7)
  final int colorIndex;

  final DateTime createdAt;

  /// 태그 이름 최대 글자 수
  static const int nameMaxLength = 20;

  /// 사용자 계정당 최대 태그 수 제한
  static const int maxTagsPerUser = 20;

  /// 아이템당 부착 가능한 최대 태그 수 제한
  static const int maxTagsPerItem = 5;

  const Tag({
    required this.id,
    required this.userId,
    required this.name,
    required this.colorIndex,
    required this.createdAt,
  });

  /// Map 데이터에서 Tag 객체를 생성한다
  factory Tag.fromMap(Map<String, dynamic> map) {
    try {
      return Tag(
        id: map['id']?.toString() ?? '',
        userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
        name: (map['name'] as String?) ?? '',
        // colorIndex 범위를 0~7로 제한하여 인덱스 초과 에러를 방지한다
        colorIndex: ((map['color_index'] ?? map['colorIndex'] ?? 0) as num).toInt().clamp(0, 7),
        createdAt: DateParser.parse(
            map['created_at'] ?? map['createdAt'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'Tag 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (id 제외, user_id 포함)
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'name': name,
      'color_index': colorIndex,
    };
  }

  /// UPDATE용 Map (id, user_id 제외)
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'color_index': colorIndex,
    };
  }

  /// 레거시 호환: 기존 toMap 호출부를 위한 별칭
  Map<String, dynamic> toMap() => toUpdateMap();

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  Tag copyWith({
    String? name,
    int? colorIndex,
  }) {
    return Tag(
      id: id,
      userId: userId,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt,
    );
  }
}
