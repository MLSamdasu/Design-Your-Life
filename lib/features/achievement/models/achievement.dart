// F8: 업적 데이터 모델
// Hive achievementsBox에 저장되는 업적 모델이다.
// 필드: id, user_id, type, title, description, icon_name,
//   xp_reward, unlocked_at, created_at
import '../../../core/utils/date_parser.dart';
import '../../../core/error/app_exception.dart';

/// 업적(배지) 데이터 모델
/// 사용자가 달성한 업적을 Hive에 저장한다
class Achievement {
  final String id;
  final String userId;

  /// 업적 유형 (streak / completion / milestone / special)
  final String type;

  final String title;
  final String description;

  /// 이모지 아이콘 문자열
  final String iconName;

  /// 업적 달성 시 획득하는 XP 포인트
  final int xpReward;

  /// 업적을 달성한 시각
  final DateTime unlockedAt;

  final DateTime createdAt;

  const Achievement({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.iconName,
    required this.xpReward,
    required this.unlockedAt,
    required this.createdAt,
  });

  /// Map 데이터에서 Achievement 객체를 생성한다
  factory Achievement.fromMap(Map<String, dynamic> map) {
    try {
      return Achievement(
        id: map['id']?.toString() ?? '',
        userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
        type: (map['type'] as String?) ?? '',
        title: (map['title'] as String?) ?? '',
        description: (map['description'] as String?) ?? '',
        iconName: (map['icon_name'] ?? map['iconName'] ?? '') as String,
        // JSON 역직렬화 시 num → int 안전 변환 (int/double 모두 처리)
        xpReward: (map['xp_reward'] as num?)?.toInt() ??
            (map['xpReward'] as num?)?.toInt() ??
            0,
        unlockedAt: DateParser.parse(
            map['unlocked_at'] ?? map['unlockedAt'] ?? DateTime.now()),
        createdAt: DateParser.parse(
            map['created_at'] ?? map['createdAt'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'Achievement 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (user_id 포함)
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'type': type,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'xp_reward': xpReward,
      'unlocked_at': unlockedAt.toIso8601String(),
    };
  }

  /// 레거시 호환: 기존 toMap 호출부를 위한 별칭
  Map<String, dynamic> toMap() => toInsertMap(userId);

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  Achievement copyWith({
    String? type,
    String? title,
    String? description,
    String? iconName,
    int? xpReward,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      userId: userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      xpReward: xpReward ?? this.xpReward,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      createdAt: createdAt,
    );
  }
}
