// 루틴 로그 Provider 체인
// routineLogDataVersionProvider, allRoutineLogsRawProvider는
// data_store_providers.dart에서 import한다
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/routine_log.dart';

/// 특정 날짜의 루틴 로그 목록
final routineLogsForDayProvider = Provider.family<List<RoutineLog>, DateTime>(
  (ref, date) {
    final allRaw = ref.watch(allRoutineLogsRawProvider);
    final dateStr = AppDateUtils.toDateString(date);
    return allRaw
        .map((m) => RoutineLog.fromMap(m))
        .where((log) => AppDateUtils.toDateString(log.date) == dateStr)
        .toList();
  },
);

/// 특정 루틴 + 특정 날짜의 완료 여부
final routineCompletionProvider =
    Provider.family<bool, ({String routineId, DateTime date})>(
  (ref, params) {
    final logs = ref.watch(routineLogsForDayProvider(params.date));
    return logs.any((log) =>
        log.routineId == params.routineId && log.isCompleted);
  },
);

/// 루틴 완료 토글 액션
final toggleRoutineLogProvider = Provider<
    Future<void> Function(String routineId, DateTime date, bool isCompleted)>(
  (ref) => (routineId, date, isCompleted) async {
    final cache = ref.read(hiveCacheServiceProvider);
    final dateStr = AppDateUtils.toDateString(date);
    final existingLogs = cache.query(
      AppConstants.routineLogsBox,
      (m) =>
          m['routine_id'] == routineId &&
          (m['log_date'] ?? m['logDate']) == dateStr,
    );

    if (isCompleted && existingLogs.isEmpty) {
      // 완료 체크: 신규 로그 생성
      final id = const Uuid().v4();
      final now = DateTime.now();
      final log = RoutineLog(
        id: id,
        routineId: routineId,
        date: date,
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      );
      final map = log.toInsertMap(AppConstants.localUserId)
        ..['id'] = id;
      await cache.put(
        AppConstants.routineLogsBox,
        id,
        map,
      );
    } else if (!isCompleted && existingLogs.isNotEmpty) {
      // 완료 해제: 기존 로그 삭제
      await cache.deleteById(
        AppConstants.routineLogsBox,
        existingLogs.first['id'].toString(),
      );
    }

    // 파생 Provider 갱신
    ref.read(routineLogDataVersionProvider.notifier).state++;
  },
);
