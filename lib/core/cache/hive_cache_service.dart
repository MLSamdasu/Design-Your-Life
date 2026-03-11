// C0.6: Hive 캐시 읽기/쓰기 범용 서비스
// userProfileBox, eventsBox, todosBox, habitsBox, habitLogsBox,
// routinesBox, goalsBox, settingsBox, syncMetaBox를 관리한다.
// Write-Through + Read-from-Cache 패턴을 구현한다.
// 모든 Box는 HiveInitializer에서 <dynamic>으로 열리므로,
// 여기서도 반드시 <dynamic>으로 접근해야 타입 불일치 오류를 방지한다.
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Hive 캐시 서비스 (C0.6)
/// 오프라인 고속 캐시의 읽기/쓰기 인터페이스를 제공한다
/// Write-Through 패턴: API 쓰기 성공 후 캐시 갱신
/// Read-from-Cache 패턴: 캐시 우선 반환 + 백그라운드 서버 동기화
class HiveCacheService {
  // ─── 설정 값 읽기/쓰기 ───────────────────────────────────────────────────
  /// 앱 설정 값 저장 (테마 모드, 마지막 탭 등)
  /// value는 Hive가 지원하는 기본 타입(String, int, bool, double, DateTime)만 허용한다
  Future<void> saveSetting(String key, Object value) async {
    // HiveInitializer가 <dynamic>으로 열었으므로 동일 타입으로 접근한다
    final box = Hive.box<dynamic>(AppConstants.settingsBox);
    await box.put(key, value);
  }

  /// 앱 설정 값 읽기
  T? readSetting<T>(String key) {
    final box = Hive.box<dynamic>(AppConstants.settingsBox);
    final value = box.get(key);
    // 타입 안전 반환: 캐스팅 실패 시 null 반환
    if (value is T) return value;
    return null;
  }

  // ─── 동기화 메타데이터 ────────────────────────────────────────────────────
  /// 마지막 동기화 시각 저장
  Future<void> saveLastSyncTime(String boxName, DateTime time) async {
    final box = Hive.box<dynamic>(AppConstants.syncMetaBox);
    await box.put('lastSync_$boxName', time.toIso8601String());
  }

  /// 마지막 동기화 시각 읽기
  DateTime? readLastSyncTime(String boxName) {
    final box = Hive.box<dynamic>(AppConstants.syncMetaBox);
    final raw = box.get('lastSync_$boxName');
    // dynamic에서 String으로 안전하게 캐스팅한다
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  // ─── 일반 데이터 캐시 ────────────────────────────────────────────────────
  /// 캐시 박스에 JSON 데이터를 저장한다
  /// 동시에 해당 키의 타임스탬프를 syncMetaBox에 기록한다
  Future<void> put(
      String boxName, String key, Map<String, dynamic> data) async {
    final box = Hive.box<dynamic>(boxName);
    await box.put(key, data);
    // 캐시 갱신 시각을 기록하여 불필요한 재캐싱을 방지한다
    await _saveCacheTimestamp(boxName, key);
  }

  /// 캐시 박스에서 JSON 데이터를 읽는다
  Map<String, dynamic>? get(String boxName, String key) {
    final box = Hive.box<dynamic>(boxName);
    final data = box.get(key);
    // dynamic에서 Map으로 안전하게 캐스팅한다
    if (data is! Map) return null;
    // Map<dynamic, dynamic>을 Map<String, dynamic>으로 변환
    return data.map((k, v) => MapEntry(k.toString(), v));
  }

  /// 캐시 박스에 리스트 데이터를 저장한다
  /// 동시에 해당 키의 타임스탬프를 syncMetaBox에 기록한다
  Future<void> putList(
      String boxName, String key, List<Map<String, dynamic>> items) async {
    final box = Hive.box<dynamic>(boxName);
    await box.put(key, items);
    // 캐시 갱신 시각을 기록하여 불필요한 재캐싱을 방지한다
    await _saveCacheTimestamp(boxName, key);
  }

  /// 캐시 박스에서 리스트 데이터를 읽는다
  List<Map<String, dynamic>>? getList(String boxName, String key) {
    final box = Hive.box<dynamic>(boxName);
    final data = box.get(key);
    // dynamic에서 List로 안전하게 캐스팅한다
    if (data is! List) return null;
    // 각 요소를 Map<String, dynamic>으로 안전하게 변환
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  /// 특정 키의 캐시 항목을 삭제한다
  Future<void> delete(String boxName, String key) async {
    final box = Hive.box<dynamic>(boxName);
    await box.delete(key);
    // 타임스탬프도 함께 삭제한다
    final metaBox = Hive.box<dynamic>(AppConstants.syncMetaBox);
    await metaBox.delete('ts_${boxName}_$key');
  }

  /// 박스 내 모든 캐시를 초기화한다
  Future<void> clearBox(String boxName) async {
    final box = Hive.box<dynamic>(boxName);
    await box.clear();
  }

  // ─── 로컬 퍼스트 아키텍처 전용 메서드 ─────────────────────────────────────
  // Hive를 기본 저장소로 사용하는 로컬 퍼스트 아키텍처를 위한
  // 전체 조회, 조건 조회, 업데이트, ID 기반 삭제 기능을 제공한다.

  /// 특정 박스의 모든 항목을 리스트로 반환한다
  /// 로컬 퍼스트 아키텍처에서 전체 목록 조회 시 사용한다
  List<Map<String, dynamic>> getAll(String boxName) {
    final box = Hive.box<dynamic>(boxName);
    final result = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final data = box.get(key);
      // Map 타입만 처리한다 (리스트 캐시 키나 타임스탬프 메타 키는 제외)
      if (data is Map) {
        result.add(data.map((k, v) => MapEntry(k.toString(), v)));
      }
    }
    return result;
  }

  /// 특정 박스에서 조건에 맞는 항목들을 반환한다
  /// predicate 함수가 true를 반환하는 항목만 리스트에 포함한다
  List<Map<String, dynamic>> query(
    String boxName,
    bool Function(Map<String, dynamic>) predicate,
  ) {
    // getAll로 전체를 가져온 뒤 predicate로 필터링한다
    return getAll(boxName).where(predicate).toList();
  }

  /// 항목을 ID 기반으로 업데이트한다
  /// 기존 데이터에 새 데이터를 머지(merge)하여 저장한다
  Future<void> update(
      String boxName, String id, Map<String, dynamic> data) async {
    final box = Hive.box<dynamic>(boxName);
    final existing = box.get(id);
    // 기존 항목이 없으면 새로 삽입한다
    if (existing is Map) {
      final merged = existing.map((k, v) => MapEntry(k.toString(), v));
      merged.addAll(data);
      await box.put(id, merged);
    } else {
      // 기존 항목이 없을 경우 새로 삽입한다
      await box.put(id, data);
    }
    await _saveCacheTimestamp(boxName, id);
  }

  /// 항목을 ID 기반으로 삭제한다
  /// delete(boxName, key)와 동일하지만 명시적 의미를 부여한 메서드이다
  Future<void> deleteById(String boxName, String id) async {
    await delete(boxName, id);
  }

  // ─── 타임스탬프 기반 캐시 갱신 최적화 ──────────────────────────────────────
  /// 서버에서 가져온 데이터의 수정 시각과 캐시 시각을 비교하여
  /// 변경이 없으면 재캐싱을 건너뛴다 (불필요한 디스크 I/O 방지)
  bool shouldUpdateCache(String boxName, String key, DateTime serverUpdatedAt) {
    final cachedAt = _readCacheTimestamp(boxName, key);
    if (cachedAt == null) return true; // 캐시 없음 → 갱신 필요
    // 서버 데이터가 캐시보다 새로운 경우에만 갱신한다
    return serverUpdatedAt.isAfter(cachedAt);
  }

  /// 캐시 타임스탬프를 저장한다 (put/putList 시 자동 호출)
  Future<void> _saveCacheTimestamp(String boxName, String key) async {
    final metaBox = Hive.box<dynamic>(AppConstants.syncMetaBox);
    await metaBox.put(
      'ts_${boxName}_$key',
      DateTime.now().toIso8601String(),
    );
  }

  /// 캐시 타임스탬프를 읽는다
  DateTime? _readCacheTimestamp(String boxName, String key) {
    final metaBox = Hive.box<dynamic>(AppConstants.syncMetaBox);
    final raw = metaBox.get('ts_${boxName}_$key');
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  // ─── 캐시 키 생성 헬퍼 ──────────────────────────────────────────────────
  /// 이벤트 캐시 키 (월별)
  static String eventsKey(DateTime month) =>
      'events_${month.year}-${month.month.toString().padLeft(2, '0')}';

  /// 투두 캐시 키 (일별)
  static String todosKey(DateTime date) =>
      'todos_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// 습관 로그 캐시 키 (월별)
  static String habitLogsKey(DateTime month) =>
      'logs_${month.year}-${month.month.toString().padLeft(2, '0')}';
}
