// F2: 이벤트 데이터 Provider (Single Source of Truth 아키텍처)
// Repository + CRUD 액션 Provider만 포함한다.
// 모델, 월별/일별/주별 파생 Provider는 별도 파일로 분리되었으며
// 하위 호환성을 위해 barrel export한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../services/event_repository.dart';
import '../../../shared/models/event.dart';

// ─── Barrel Exports (하위 호환성 유지) ─────────────────────────────────────────
export 'event_models.dart';
export 'event_month_provider.dart';
export 'calendar_day_providers.dart';
export 'calendar_week_providers.dart';

// ─── Repository Provider ─────────────────────────────────────────────────────

/// EventRepository Provider (로컬 퍼스트)
/// HiveCacheService를 주입받아 로컬 Hive 저장소에 접근한다
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return EventRepository(cache: cache);
});

// ─── CRUD 액션 Provider ──────────────────────────────────────────────────────

/// 이벤트 생성 액션 Provider
/// 로컬 Hive에 즉시 저장하고 월별 이벤트 목록을 다시 로드한다
final createEventProvider =
    Provider<Future<void> Function(Event)>((ref) {
  final repository = ref.watch(eventRepositoryProvider);

  return (Event event) async {
    try {
      await repository.createEvent(event);
      // 버전 카운터 증가 → allEventsRawProvider 재평가
      ref.read(eventDataVersionProvider.notifier).state++;
    } catch (e) {
      rethrow;
    }
  };
});

/// 이벤트 수정 액션 Provider
final updateEventProvider =
    Provider<Future<void> Function(Event)>((ref) {
  final repository = ref.watch(eventRepositoryProvider);

  return (Event event) async {
    try {
      await repository.updateEvent(event.id, event);
      ref.read(eventDataVersionProvider.notifier).state++;
    } catch (e) {
      rethrow;
    }
  };
});

/// 이벤트 삭제 액션 Provider
final deleteEventProvider =
    Provider<Future<void> Function(String)>((ref) {
  final repository = ref.watch(eventRepositoryProvider);

  return (String eventId) async {
    try {
      await repository.deleteEvent(eventId);
      ref.read(eventDataVersionProvider.notifier).state++;
    } catch (e) {
      rethrow;
    }
  };
});

/// 새 이벤트 ID 생성 헬퍼 Provider
final generateEventIdProvider = Provider<String Function()>((ref) {
  return () {
    return const Uuid().v4();
  };
});
