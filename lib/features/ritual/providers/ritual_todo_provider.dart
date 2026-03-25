// F-Ritual: DailyThree → Todo 생성 연동 Provider
// 3개 할일을 작성하면 각각을 실제 Todo로 생성하고,
// 생성된 todoId를 DailyThree에 기록한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/todo.dart';
import '../../todo/providers/todo_crud_providers.dart';
import '../models/daily_three.dart';
import 'ritual_provider.dart';

/// DailyThree 저장 + Todo 자동 생성 액션
/// 3개 할일 텍스트를 받아 각각 Todo를 생성한 뒤
/// 생성된 todoId를 DailyThree에 기록하고 저장한다
final saveDailyThreeWithTodosProvider =
    Provider<Future<DailyThree> Function(List<String> tasks)>((ref) {
  final repository = ref.watch(ritualRepositoryProvider);
  final createTodo = ref.watch(createTodoProvider);
  final today = ref.watch(todayDateProvider);

  return (List<String> tasks) async {
    final dateStr = AppDateUtils.toDateString(today);
    const uuid = Uuid();

    // 비어있지 않은 할일만 Todo로 생성한다
    final todoIds = <String>[];
    for (final task in tasks) {
      if (task.trim().isEmpty) continue;

      final todoId = uuid.v4();
      final todo = Todo(
        id: todoId,
        title: task.trim(),
        date: today,
        createdAt: DateTime.now(),
      );
      await createTodo(todo);
      todoIds.add(todoId);
    }

    // DailyThree를 저장한다
    final dailyThree = DailyThree(
      id: uuid.v4(),
      date: dateStr,
      tasks: _padTasks(tasks),
      todoIds: todoIds,
      isCompleted: true,
      createdAt: DateTime.now(),
    );

    await repository.saveDailyThree(dailyThree);
    ref.read(dailyThreeDataVersionProvider.notifier).state++;

    return dailyThree;
  };
});

/// tasks 리스트를 항상 3개로 맞춘다 (부족하면 빈 문자열 패딩)
List<String> _padTasks(List<String> tasks) {
  final padded = List<String>.from(tasks);
  while (padded.length < 3) {
    padded.add('');
  }
  return padded.take(3).toList();
}
