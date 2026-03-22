// F4: 루틴 Riverpod Provider (Single Source of Truth 아키텍처)
// allRoutinesRawProvider에서 파생하여 CRUD 시 자동 동기화된다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../shared/models/routine.dart';
import '../services/routine_repository.dart';

// ─── Repository Provider ────────────────────────────────────────────────────

/// RoutineRepository Provider
/// HiveCacheService를 주입하여 로컬 퍼스트로 동작한다
final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return RoutineRepository(cache: cache);
});

// ─── 루틴 목록 Provider (Single Source of Truth에서 파생) ──────────────────

/// 전체 루틴 목록 Provider (동기 Provider)
/// allRoutinesRawProvider(Single Source of Truth)에서 파생한다
/// Hive 조회는 모두 동기 연산이므로 FutureProvider가 불필요하다.
final routinesProvider = Provider<List<Routine>>((ref) {
  final allRoutines = ref.watch(allRoutinesRawProvider);
  return allRoutines.map((r) => Routine.fromMap(r)).toList();
});

/// 활성 루틴만 Provider (동기 Provider)
/// allRoutinesRawProvider(Single Source of Truth)에서 파생한다
/// Hive 조회는 모두 동기 연산이므로 FutureProvider가 불필요하다.
final activeRoutinesProvider = Provider<List<Routine>>((ref) {
  final allRoutines = ref.watch(allRoutinesRawProvider);
  return allRoutines
      .where((r) => r['is_active'] == true || r['isActive'] == true)
      .map((r) => Routine.fromMap(r))
      .toList();
});

// ─── 루틴 CRUD 액션 Provider ────────────────────────────────────────────────

/// 새 루틴 생성 액션
final createRoutineProvider = Provider<Future<void> Function(Routine)>((ref) {
  final repository = ref.watch(routineRepositoryProvider);

  return (Routine routine) async {
    try {
      await repository.createRoutine(routine);
      // 버전 카운터 증가 → 홈/캘린더/습관 탭 모두 자동 갱신
      ref.read(routineDataVersionProvider.notifier).state++;
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  };
});

/// 루틴 활성/비활성 토글 액션
final toggleRoutineActiveProvider =
    Provider<Future<void> Function(String, bool)>((ref) {
  final repository = ref.watch(routineRepositoryProvider);

  return (String routineId, bool isActive) async {
    try {
      await repository.toggleRoutineActive(routineId, isActive);
      // 버전 카운터 증가 → 모든 파생 Provider 자동 갱신
      ref.read(routineDataVersionProvider.notifier).state++;
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  };
});

/// 루틴 수정 액션
final updateRoutineProvider =
    Provider<Future<void> Function(String, Routine)>((ref) {
  final repository = ref.watch(routineRepositoryProvider);

  return (String routineId, Routine routine) async {
    try {
      await repository.updateRoutine(routineId, routine);
      // 버전 카운터 증가 → 모든 파생 Provider 자동 갱신
      ref.read(routineDataVersionProvider.notifier).state++;
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  };
});

/// 루틴 삭제 액션
final deleteRoutineProvider =
    Provider<Future<void> Function(String)>((ref) {
  final repository = ref.watch(routineRepositoryProvider);

  return (String routineId) async {
    try {
      // 루틴 삭제 전 관련 RoutineLog를 먼저 정리한다 (고아 데이터 방지)
      final cache = ref.read(hiveCacheServiceProvider);
      final allLogs = cache.getAll(AppConstants.routineLogsBox);
      for (final log in allLogs) {
        if ((log['routine_id'] ?? log['routineId']) == routineId) {
          final logId = log['id']?.toString();
          if (logId != null && logId.isNotEmpty) {
            await cache.delete(AppConstants.routineLogsBox, logId);
          }
        }
      }
      await repository.deleteRoutine(routineId);
      // 버전 카운터 증가 → 모든 파생 Provider 자동 갱신
      ref.read(routineDataVersionProvider.notifier).state++;
      ref.read(routineLogDataVersionProvider.notifier).state++;
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  };
});
