// F4: 루틴 Riverpod Provider
// routinesProvider: 루틴 목록 (FutureProvider)
// activeRoutinesProvider: 활성 루틴 목록. F2(캘린더)가 watch한다.
// 로컬 퍼스트 아키텍처: Hive 로컬 박스에서 데이터를 조회한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
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

// ─── 루틴 목록 Provider ───────────────────────────────────────────────────

/// 전체 루틴 목록 Provider (FutureProvider)
/// 로컬 Hive에서 동기적으로 읽되 FutureProvider 인터페이스를 유지한다
final routinesProvider = FutureProvider<List<Routine>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(routineRepositoryProvider);

  if (userId == null) return const [];
  // 로컬 퍼스트: Hive에서 동기 조회한다
  return repository.getRoutines();
});

/// 활성 루틴만 Provider (FutureProvider)
/// F2(캘린더)에서 타임라인 연동에 사용한다
final activeRoutinesProvider = FutureProvider<List<Routine>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(routineRepositoryProvider);

  if (userId == null) return const [];
  // 로컬 퍼스트: Hive에서 is_active 필터링하여 동기 조회한다
  return repository.getActiveRoutines();
});

// ─── 루틴 CRUD 액션 Provider ────────────────────────────────────────────────

/// 새 루틴 생성 액션
final createRoutineProvider = Provider<Future<void> Function(Routine)>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(routineRepositoryProvider);

  return (Routine routine) async {
    if (userId == null) return;
    await repository.createRoutine(routine);
    // 생성 후 루틴 목록을 다시 로드한다
    ref.invalidate(routinesProvider);
    ref.invalidate(activeRoutinesProvider);
  };
});

/// 루틴 활성/비활성 토글 액션
final toggleRoutineActiveProvider =
    Provider<Future<void> Function(String, bool)>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(routineRepositoryProvider);

  return (String routineId, bool isActive) async {
    if (userId == null) return;
    await repository.toggleRoutineActive(routineId, isActive);
    // 토글 후 루틴 목록을 다시 로드한다
    ref.invalidate(routinesProvider);
    ref.invalidate(activeRoutinesProvider);
  };
});

/// 루틴 삭제 액션
final deleteRoutineProvider =
    Provider<Future<void> Function(String)>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(routineRepositoryProvider);

  return (String routineId) async {
    if (userId == null) return;
    await repository.deleteRoutine(routineId);
    // 삭제 후 루틴 목록을 다시 로드한다
    ref.invalidate(routinesProvider);
    ref.invalidate(activeRoutinesProvider);
  };
});

/// 새 루틴 ID 생성 헬퍼
/// REST API에서는 서버가 ID를 할당하므로 클라이언트에서 임시 ID를 생성한다
final generateRoutineIdProvider = Provider<String Function()>((ref) {
  return () {
    return DateTime.now().millisecondsSinceEpoch.toString();
  };
});
