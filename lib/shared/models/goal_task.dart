// 공유 모델: GoalTask (실천 할일)
// Hive goalTasksBox에 저장되는 실천 할일 모델이다.
// 필드: id, sub_goal_id, title, is_completed, order_index, created_at
import '../../core/utils/date_parser.dart';
import '../../core/error/app_exception.dart';

/// 실천 할일 모델
/// Hive goalTasksBox에 저장된다
/// sub_goal_id 필드로 특정 SubGoal 소속 tasks를 필터링한다
class GoalTask {
  final String id;

  /// 소속 하위 목표 ID
  final String subGoalId;

  /// 실천 할일 제목 (최대 200자)
  final String title;

  /// 완료 여부
  final bool isCompleted;

  /// 만다라트 위치 인덱스 (0~7)
  final int orderIndex;

  final DateTime createdAt;

  const GoalTask({
    required this.id,
    required this.subGoalId,
    required this.title,
    this.isCompleted = false,
    required this.orderIndex,
    required this.createdAt,
  });

  /// Map 데이터에서 GoalTask 객체를 생성한다
  factory GoalTask.fromMap(Map<String, dynamic> map) {
    try {
      return GoalTask(
        id: map['id']?.toString() ?? '',
        subGoalId: (map['sub_goal_id'] ?? map['subGoalId']).toString(),
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
        'GoalTask 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (id 제외)
  Map<String, dynamic> toInsertMap() {
    return {
      'sub_goal_id': int.tryParse(subGoalId) ?? subGoalId,
      'title': title,
      'is_completed': isCompleted,
      'order_index': orderIndex,
    };
  }

  /// UPDATE용 Map (id, sub_goal_id 제외)
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
  GoalTask copyWith({
    String? title,
    bool? isCompleted,
    int? orderIndex,
  }) {
    return GoalTask(
      id: id,
      subGoalId: subGoalId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt,
    );
  }
}
