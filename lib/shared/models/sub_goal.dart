// 공유 모델: SubGoal (목표의 하위 목표)
// Hive subGoalsBox에 저장되는 하위 목표 모델이다.
// 필드: id, goal_id, title, is_completed, order_index, created_at
import '../../core/utils/date_parser.dart';
import '../../core/error/app_exception.dart';

/// 하위 목표 모델
/// 년간 목표에 속하는 월간 수준의 세부 목표를 나타낸다
/// 만다라트에서 핵심 목표 주변 8개 칸 중 하나에 해당한다
class SubGoal {
  final String id;

  /// 소속 목표 ID
  final String goalId;

  /// 하위 목표 제목 (최대 200자)
  final String title;

  /// 완료 여부
  final bool isCompleted;

  /// 만다라트 위치 인덱스 (0~7)
  final int orderIndex;

  final DateTime createdAt;

  const SubGoal({
    required this.id,
    required this.goalId,
    required this.title,
    this.isCompleted = false,
    required this.orderIndex,
    required this.createdAt,
  });

  /// Map 데이터에서 SubGoal 객체를 생성한다
  factory SubGoal.fromMap(Map<String, dynamic> map) {
    try {
      return SubGoal(
        id: map['id']?.toString() ?? '',
        goalId: (map['goal_id'] ?? map['goalId']).toString(),
        title: map['title'] as String,
        isCompleted: map['is_completed'] as bool? ??
            map['isCompleted'] as bool? ??
            false,
        orderIndex: map['order_index'] as int? ??
            map['orderIndex'] as int? ??
            0,
        createdAt: DateParser.parse(
            map['created_at'] ?? map['createdAt'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'SubGoal 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (id 제외)
  Map<String, dynamic> toInsertMap() {
    return {
      'goal_id': int.tryParse(goalId) ?? goalId,
      'title': title,
      'is_completed': isCompleted,
      'order_index': orderIndex,
    };
  }

  /// UPDATE용 Map (id, goal_id 제외)
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'is_completed': isCompleted,
      'order_index': orderIndex,
    };
  }

  /// 레거시 호환: 기존 toMap 호출부를 위한 별칭
  Map<String, dynamic> toMap() => toUpdateMap();

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  SubGoal copyWith({
    String? title,
    bool? isCompleted,
    int? orderIndex,
  }) {
    return SubGoal(
      id: id,
      goalId: goalId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt,
    );
  }
}
