// F1: 홈 대시보드 — 오늘 루틴 요약 Provider
// allRoutinesRawProvider(Single Source of Truth)에서 파생하여
// 루틴 CRUD 시 routineDataVersionProvider 증가 → 이 Provider 자동 갱신
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/error/error_handler.dart';
import '../../../shared/models/routine.dart';
import 'home_models.dart';

/// 오늘의 루틴 요약 Provider (동기)
/// allRoutinesRawProvider(Single Source of Truth)에서 파생하여
/// 루틴 CRUD 시 routineDataVersionProvider 증가 → 이 Provider 자동 갱신
final todayRoutinesProvider = Provider<RoutineSummary>((ref) {
  // 단일 진실 원천(SSOT): 중앙 데이터 스토어에서 파생한다
  final allRoutines = ref.watch(allRoutinesRawProvider);
  // 자정 경계 불일치 방지: 공유 todayDateProvider를 사용한다
  final today = ref.watch(todayDateProvider);

  try {
    // 활성 루틴만 필터링한다
    final activeRoutines = allRoutines
        .where((r) => r['is_active'] == true || r['isActive'] == true)
        .toList();

    // 오늘 요일 (ISO 8601: 1=월~7=일)
    final todayWeekday = today.weekday;

    // 오늘 요일에 해당하는 루틴만 필터링한다
    final todayRoutines = activeRoutines.where((r) {
      final routine = Routine.fromMap(r);
      return routine.repeatDays.contains(todayWeekday);
    }).toList();

    if (todayRoutines.isEmpty) return RoutineSummary.empty;

    // Routine 객체로 변환 후 startTime 기준 시간순 정렬한다
    final routines = todayRoutines
        .map((r) => Routine.fromMap(r))
        .toList()
      ..sort((a, b) {
        final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
        return aMinutes.compareTo(bMinutes);
      });

    /// TimeOfDay를 "HH:mm" 형식 문자열로 변환한다
    String formatTime(TimeOfDay t) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    return RoutineSummary(
      total: routines.length,
      routineItems: routines.map((routine) {
        return RoutinePreviewItem(
          id: routine.id,
          name: routine.name,
          startTime: formatTime(routine.startTime),
          endTime: formatTime(routine.endTime),
          colorIndex: routine.colorIndex,
        );
      }).toList(),
    );
  } catch (e, stack) {
    ErrorHandler.logServiceError('HomeProvider:todayRoutines', e, stack);
    return RoutineSummary.empty;
  }
});
