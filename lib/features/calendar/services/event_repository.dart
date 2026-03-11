// F2: EventRepository (로컬 퍼스트 아키텍처)
// 모든 CRUD는 Hive 로컬 저장소에서 수행한다.
// 인터넷 없이도 완전히 동작한다.

import 'package:uuid/uuid.dart';

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/event.dart';

/// 이벤트 저장소 (로컬 퍼스트 아키텍처)
/// Hive 로컬 저장소를 기본 저장소로 사용하여 오프라인에서도 완전히 동작한다
class EventRepository {
  final HiveCacheService _cache;

  /// Hive에서 이벤트 데이터를 저장하는 박스 이름
  static const _boxName = AppConstants.eventsBox;

  /// UUID 생성기 (로컬에서 UUID를 생성한다)
  static const _uuid = Uuid();

  EventRepository({required HiveCacheService cache}) : _cache = cache;

  // ─── 조회 ──────────────────────────────────────────────────────────────────

  /// 특정 월의 이벤트 목록을 로컬 Hive에서 조회한다
  /// start_date 필드가 해당 월 범위 내에 있는 이벤트만 반환한다
  List<Event> getEventsForMonth(int year, int month) {
    // 해당 월의 시작일과 종료일을 계산한다
    final startDate = DateTime(year, month, 1);
    // month + 1의 0일 = 해당 월의 마지막 날
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    // "YYYY-MM-DD" 경계 문자열 (문자열 비교로 날짜 범위를 판단한다)
    final startStr =
        '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr =
        '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    // 전체 박스를 스캔하여 해당 월의 이벤트만 필터링한다
    final items = _cache.query(
      _boxName,
      (map) {
        // start_date 필드는 ISO 8601 문자열이다 (예: "2026-03-15T00:00:00.000")
        final raw = map['start_date'] as String?;
        if (raw == null) return false;
        // 날짜 부분(YYYY-MM-DD)만 추출하여 범위를 비교한다
        final datePart = raw.length >= 10 ? raw.substring(0, 10) : raw;
        return datePart.compareTo(startStr) >= 0 &&
            datePart.compareTo(endStr) <= 0;
      },
    );

    // start_date 오름차순으로 정렬하여 반환한다
    final events = items.map((m) => Event.fromMap(m)).toList();
    events.sort((a, b) => a.startDate.compareTo(b.startDate));
    return events;
  }

  // ─── 생성 ──────────────────────────────────────────────────────────────────

  /// 새 이벤트를 로컬 Hive에 생성한다
  /// 클라이언트에서 UUID v4를 생성하여 ID로 사용한다
  Event createEvent(Event event) {
    // 로컬에서 고유 ID를 생성한다
    final id = _uuid.v4();
    final now = DateTime.now();

    // INSERT용 맵을 생성하고 로컬 전용 필드를 추가한다
    final map = event.toInsertMap('local_user')
      ..['id'] = id
      ..['created_at'] = now.toIso8601String()
      ..['updated_at'] = now.toIso8601String();

    // Hive에 저장한다
    _cache.put(_boxName, id, map);

    return Event.fromMap(map);
  }

  // ─── 수정 ──────────────────────────────────────────────────────────────────

  /// 이벤트를 수정한다
  /// 기존 id와 created_at을 유지하고 나머지 필드를 업데이트한다
  Event? updateEvent(String eventId, Event event) {
    final existing = _cache.get(_boxName, eventId);
    // 해당 ID의 항목이 없으면 null을 반환한다
    if (existing == null) return null;

    // UPDATE용 맵에 메타 필드를 추가한다
    final updatedMap = event.toUpdateMap()
      ..['id'] = eventId
      ..['user_id'] = existing['user_id'] ?? 'local_user'
      ..['created_at'] = existing['created_at']
      ..['updated_at'] = DateTime.now().toIso8601String();

    _cache.put(_boxName, eventId, updatedMap);
    return Event.fromMap(updatedMap);
  }

  // ─── 삭제 ──────────────────────────────────────────────────────────────────

  /// 이벤트를 로컬 Hive에서 삭제한다
  void deleteEvent(String eventId) {
    _cache.deleteById(_boxName, eventId);
  }
}
