// F3: 투두 CRUD Provider
// Repository 초기화와 생성/수정/삭제/완료 토글 액션을 담당한다.
// CRUD 후 todoDataVersionProvider를 증가시켜 전체 파생 체인이 자동 갱신된다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../shared/models/todo.dart';
import '../../achievement/providers/achievement_provider.dart';
import '../../timer/providers/timer_provider.dart';
import '../services/todo_repository.dart';

// ─── Repository Provider ────────────────────────────────────────────────────

/// TodoRepository Provider (로컬 퍼스트)
/// HiveCacheService를 주입받아 로컬 Hive 저장소에 접근한다
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return TodoRepository(cache: cache);
});

// ─── 투두 CRUD 액션 Provider ────────────────────────────────────────────────

/// 투두 생성 액션
/// 로컬 Hive에 즉시 저장하고 버전 카운터를 증가시켜 전체 파생 Provider를 갱신한다
final createTodoProvider = Provider<Future<void> Function(Todo)>((ref) {
  final repository = ref.watch(todoRepositoryProvider);

  return (Todo todo) async {
    try {
      await repository.createTodo(todo);
      // 버전 카운터 증가 → allTodosRawProvider 재평가 → 홈/캘린더/투두 탭 모두 자동 갱신
      ref.read(todoDataVersionProvider.notifier).state++;
    } catch (e) {
      rethrow;
    }
  };
});

/// 투두 완료 상태 설정 액션
/// isCompleted 파라미터를 그대로 전달하여 원하는 상태로 설정한다
final toggleTodoProvider =
    Provider<Future<void> Function(String, bool)>((ref) {
  final repository = ref.watch(todoRepositoryProvider);

  return (String todoId, bool isCompleted) async {
    try {
      await repository.toggleTodoCompleted(todoId, isCompleted: isCompleted);
      // 버전 카운터 증가 → 홈/캘린더/투두 탭 모두 자동 갱신
      ref.read(todoDataVersionProvider.notifier).state++;

      // 완료로 전환된 경우 업적 달성 조건을 확인한다
      if (isCompleted) {
        await checkAchievementsAndNotify(ref);
      }
    } catch (e) {
      rethrow;
    }
  };
});

/// 투두 수정 액션
/// 기존 투두의 필드를 업데이트하고 버전 카운터를 증가시킨다
final updateTodoProvider = Provider<Future<void> Function(String, Todo)>((ref) {
  final repository = ref.watch(todoRepositoryProvider);

  return (String todoId, Todo todo) async {
    try {
      await repository.updateTodo(todoId, todo);
      // 버전 카운터 증가 → 모든 파생 Provider 자동 갱신
      ref.read(todoDataVersionProvider.notifier).state++;
    } catch (e) {
      rethrow;
    }
  };
});

/// 투두 삭제 액션
final deleteTodoProvider = Provider<Future<void> Function(String)>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  final timerRepository = ref.watch(timerRepositoryProvider);

  return (String todoId) async {
    try {
      // V3-010: 고아 타이머 로그 정리를 TimerRepository에 위임한다
      await timerRepository.deleteLogsByTodoId(todoId);

      await repository.deleteTodo(todoId);
      // 버전 카운터 증가 → 모든 파생 Provider 자동 갱신
      ref.read(todoDataVersionProvider.notifier).state++;
      // 타이머 로그도 변경되었으므로 타이머 버전도 증가시킨다
      ref.read(timerLogDataVersionProvider.notifier).state++;
    } catch (e) {
      rethrow;
    }
  };
});

/// 새 투두 ID 생성 헬퍼
final generateTodoIdProvider = Provider<String Function()>((ref) {
  return () {
    return const Uuid().v4();
  };
});
