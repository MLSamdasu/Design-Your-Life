// F5: GoalTask → Todo 변환 Provider
// 목표의 실천 과제를 투두로 변환하여 todosBox에 저장한다.
// 변환된 투두의 scheduled_date는 오늘, 제목은 GoalTask.title을 사용한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/goal_task.dart';

/// GoalTask → Todo 변환 액션 Provider
/// 목표의 실천 과제를 투두로 변환하여 todosBox에 저장한다
/// 변환된 투두의 scheduled_date는 오늘, 제목은 GoalTask.title을 사용한다
final exportGoalTaskAsTodoProvider =
    Provider<Future<void> Function(GoalTask task)>((ref) {
  return (GoalTask task) async {
    final cacheService = ref.read(hiveCacheServiceProvider);
    final now = DateTime.now();
    final todoId = const Uuid().v4();

    // Bug 3 Fix: user_id 누락 방지 — 로컬 퍼스트에서도 user_id를 설정한다
    final userId =
        ref.read(currentUserIdProvider) ?? AppConstants.localUserId;

    // Bug 5 Fix: 기존 투두 수를 세어 display_order를 마지막에 배치한다
    final existingTodos = cacheService.getAll(AppConstants.todosBox);
    final displayOrder = existingTodos.length;

    final todoMap = {
      'id': todoId,
      'user_id': userId,
      'title': task.title,
      'scheduled_date': AppDateUtils.toDateString(now),
      'is_completed': false,
      'display_order': displayOrder,
      'created_at': now.toIso8601String(),
    };

    await cacheService.put(AppConstants.todosBox, todoId, todoMap);
    // 투두 데이터 버전을 증가시켜 UI 갱신을 트리거한다
    ref.read(todoDataVersionProvider.notifier).state++;
  };
});
