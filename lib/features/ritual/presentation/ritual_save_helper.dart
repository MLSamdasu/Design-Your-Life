// 데일리 리추얼: 저장 헬퍼
// DailyRitualScreen에서 사용하는 저장 로직을 분리한다.
// Provider를 통해 리추얼 데이터와 오늘의 할 일을 Hive에 저장한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/global_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../models/daily_ritual.dart';
import '../models/daily_three.dart';
import '../providers/ritual_provider.dart';
import '../providers/ritual_todo_provider.dart';
import 'ritual_state_holder.dart';

/// 리추얼 데이터 저장 헬퍼
/// WidgetRef를 받아 Provider를 통해 저장한다
class RitualSaveHelper {
  final WidgetRef _ref;
  final RitualStateHolder _state;
  final String _periodKey;

  const RitualSaveHelper({
    required WidgetRef ref,
    required RitualStateHolder state,
    required String periodKey,
  })  : _ref = ref,
        _state = state,
        _periodKey = periodKey;

  /// 리추얼(25개 목표 + Top 5) 저장
  Future<void> saveRitual() async {
    final now = DateTime.now();
    final existing = _ref.read(
      currentRitualProvider(
        (periodType: 'monthly', periodKey: _periodKey),
      ),
    );

    final ritual = DailyRitual(
      id: existing?.id ?? const Uuid().v4(),
      periodType: 'monthly',
      periodKey: _periodKey,
      goals: _state.goals,
      top5Indices: _state.selectedTop5.toList(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final save = _ref.read(saveRitualProvider);
    await save(ritual);
  }

  /// 오늘의 3가지를 저장하고 Todo를 생성한다
  Future<void> saveDailyThreeWithTodos() async {
    final tasks = _state.dailyThreeControllers
        .map((c) => c.text)
        .toList();
    final nonEmpty =
        tasks.where((t) => t.trim().isNotEmpty).toList();
    if (nonEmpty.isEmpty) return;

    final save = _ref.read(saveDailyThreeWithTodosProvider);
    await save(tasks);
  }

  /// 건너뛰기 시 오늘의 DailyThree를 완료 상태로 저장한다
  /// Todo는 생성하지 않지만, 오늘 리추얼을 다시 표시하지 않도록 isCompleted를 true로 설정한다
  Future<void> markTodayAsCompleted() async {
    final today = _ref.read(todayDateProvider);
    final dateStr = AppDateUtils.toDateString(today);
    final existing = _ref.read(todayDailyThreeProvider);

    // 이미 완료 상태이면 중복 저장하지 않는다
    if (existing?.isCompleted == true) return;

    final dailyThree = DailyThree(
      id: existing?.id ?? const Uuid().v4(),
      date: dateStr,
      tasks: existing?.tasks ?? List.filled(3, ''),
      todoIds: existing?.todoIds ?? [],
      isCompleted: true,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    final save = _ref.read(saveDailyThreeProvider);
    await save(dailyThree);
  }
}
