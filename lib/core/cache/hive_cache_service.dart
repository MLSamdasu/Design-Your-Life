// C0.6: Hive 캐시 읽기/쓰기 범용 서비스
// userProfileBox, eventsBox, todosBox, habitsBox, habitLogsBox,
// routinesBox, goalsBox, settingsBox, syncMetaBox를 관리한다.
// Write-Through + Read-from-Cache 패턴을 구현한다.
// 모든 Box는 HiveInitializer에서 <dynamic>으로 열리므로,
// 여기서도 반드시 <dynamic>으로 접근해야 타입 불일치 오류를 방지한다.
import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Hive 캐시 서비스 (C0.6)
/// 오프라인 고속 캐시의 읽기/쓰기 인터페이스를 제공한다
/// Write-Through 패턴: API 쓰기 성공 후 캐시 갱신
/// Read-from-Cache 패턴: 캐시 우선 반환 + 백그라운드 서버 동기화
class HiveCacheService {
  /// 동일 box+id에 대한 동시 비동기 업데이트를 직렬화하기 위한 락 맵
  /// Flutter는 싱글 이솔레이트이지만, async gap 사이에 인터리빙이 발생할 수 있다
  final Map<String, Future<void>> _locks = {};

  // ─── 안전한 Box 접근 헬퍼 ──────────────────────────────────────────────────
  /// Hive.box() 호출을 감싸서 박스가 열리지 않았거나 닫힌 경우를 처리한다
  /// 실패 시 developer.log로 기록하고 명확한 에러 메시지로 다시 던진다
  Box<dynamic> _box(String boxName) {
    try {
      return Hive.box<dynamic>(boxName);
    } catch (e) {
      developer.log(
        'Hive 박스 접근 실패: $boxName — $e',
        name: 'HiveCacheService',
        error: e,
      );
      throw HiveError(
        'Hive 박스 "$boxName"에 접근할 수 없습니다. '
        '박스가 열려 있는지 확인하세요: $e',
      );
    }
  }

  // ─── 설정 값 읽기/쓰기 ───────────────────────────────────────────────────
  /// 앱 설정 값 저장 (테마 모드, 마지막 탭 등)
  /// value는 Hive가 지원하는 기본 타입(String, int, bool, double, DateTime)만 허용한다
  Future<void> saveSetting(String key, Object value) async {
    final box = _box(AppConstants.settingsBox);
    await box.put(key, value);
  }

  /// 앱 설정 값 읽기
  T? readSetting<T>(String key) {
    final box = _box(AppConstants.settingsBox);
    final value = box.get(key);
    // 타입 안전 반환: 캐스팅 실패 시 null 반환
    if (value is T) return value;
    return null;
  }

  // ─── 일반 데이터 캐시 ────────────────────────────────────────────────────
  /// 캐시 박스에 JSON 데이터를 저장한다
  /// 동시에 해당 키의 타임스탬프를 syncMetaBox에 기록한다
  Future<void> put(
      String boxName, String key, Map<String, dynamic> data) async {
    final box = _box(boxName);
    await box.put(key, data);
    // 캐시 갱신 시각을 기록하여 불필요한 재캐싱을 방지한다
    await _saveCacheTimestamp(boxName, key);
  }

  /// 캐시 박스에서 JSON 데이터를 읽는다
  /// 깊은 복사를 수행하여 Hive 내부 객체 참조를 차단한다
  Map<String, dynamic>? get(String boxName, String key) {
    final box = _box(boxName);
    final data = box.get(key);
    // dynamic에서 Map으로 안전하게 캐스팅한다
    if (data is! Map) return null;
    // Map<dynamic, dynamic>을 Map<String, dynamic>으로 깊은 복사한다
    // 중첩 Map/List가 Hive 내부 객체를 직접 참조하면 외부 수정이 캐시를 오염시킬 수 있다
    return _deepCopyMap(data);
  }

  /// Map을 재귀적으로 깊은 복사한다
  /// Hive 내부 데이터와의 참조 공유를 완전히 차단한다
  static Map<String, dynamic> _deepCopyMap(Map<dynamic, dynamic> source) {
    return source.map((k, v) => MapEntry(k.toString(), _deepCopyValue(v)));
  }

  /// 값을 재귀적으로 깊은 복사한다
  static dynamic _deepCopyValue(dynamic value) {
    if (value is Map) {
      return _deepCopyMap(value);
    } else if (value is List) {
      return value.map(_deepCopyValue).toList();
    }
    // 기본 타입(String, int, double, bool, DateTime, null)은 불변이므로 그대로 반환
    return value;
  }

  /// 특정 키의 캐시 항목을 삭제한다
  Future<void> delete(String boxName, String key) async {
    final box = _box(boxName);
    await box.delete(key);
    // 타임스탬프도 함께 삭제한다
    final metaBox = _box(AppConstants.syncMetaBox);
    await metaBox.delete('ts_${boxName}_$key');
  }

  /// 박스 내 모든 캐시를 초기화한다
  Future<void> clearBox(String boxName) async {
    final box = _box(boxName);
    await box.clear();
  }

  // ─── 로컬 퍼스트 아키텍처 전용 메서드 ─────────────────────────────────────
  // Hive를 기본 저장소로 사용하는 로컬 퍼스트 아키텍처를 위한
  // 전체 조회, 조건 조회, 업데이트, ID 기반 삭제 기능을 제공한다.

  /// 특정 박스의 모든 항목을 리스트로 반환한다
  /// 로컬 퍼스트 아키텍처에서 전체 목록 조회 시 사용한다
  List<Map<String, dynamic>> getAll(String boxName) {
    final box = _box(boxName);
    final result = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final data = box.get(key);
      // Map 타입만 처리한다 (리스트 캐시 키나 타임스탬프 메타 키는 제외)
      // 깊은 복사로 Hive 내부 참조를 차단한다
      if (data is Map) {
        result.add(_deepCopyMap(data));
      }
    }
    return result;
  }

  /// 특정 박스에서 조건에 맞는 항목들을 반환한다
  /// predicate 함수가 true를 반환하는 항목만 리스트에 포함한다
  /// 최적화: 조건 불일치 항목은 깊은 복사를 생략하여 메모리·CPU를 절약한다
  List<Map<String, dynamic>> query(
    String boxName,
    bool Function(Map<String, dynamic>) predicate,
  ) {
    final box = _box(boxName);
    final result = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final data = box.get(key);
      if (data is! Map) continue;
      // 얕은 캐스팅으로 predicate를 평가한다 (읽기 전용이므로 안전하다)
      final shallow = data.map((k, v) => MapEntry(k.toString(), v));
      if (predicate(shallow)) {
        // 일치하는 항목만 깊은 복사하여 Hive 내부 참조를 차단한다
        result.add(_deepCopyMap(data));
      }
    }
    return result;
  }

  /// 항목을 ID 기반으로 업데이트한다
  /// 기존 데이터에 새 데이터를 머지(merge)하여 저장한다
  /// 동일 box+id에 대한 동시 호출을 락으로 직렬화하여 데이터 손실을 방지한다
  Future<void> update(
      String boxName, String id, Map<String, dynamic> data) async {
    final lockKey = '${boxName}_$id';
    // 이전 작업이 끝날 때까지 대기한 뒤 새 작업을 체이닝한다
    final previous = _locks[lockKey] ?? Future<void>.value();
    final completer = _locks[lockKey] = previous.then((_) async {
      final box = _box(boxName);
      final existing = box.get(id);
      // 기존 항목이 있으면 머지, 없으면 새로 삽입한다
      if (existing is Map) {
        final merged = existing.map((k, v) => MapEntry(k.toString(), v));
        merged.addAll(data);
        await box.put(id, merged);
      } else {
        await box.put(id, data);
      }
      await _saveCacheTimestamp(boxName, id);
    });
    await completer;
    // 체인의 마지막 작업이면 락을 정리하여 메모리 누수를 방지한다
    if (_locks[lockKey] == completer) {
      _locks.remove(lockKey);
    }
  }

  /// 항목을 ID 기반으로 삭제한다
  /// delete(boxName, key)와 동일하지만 명시적 의미를 부여한 메서드이다
  Future<void> deleteById(String boxName, String id) async {
    await delete(boxName, id);
  }

  /// 캐시 타임스탬프를 저장한다 (put 시 자동 호출)
  Future<void> _saveCacheTimestamp(String boxName, String key) async {
    final metaBox = _box(AppConstants.syncMetaBox);
    await metaBox.put(
      'ts_${boxName}_$key',
      DateTime.now().toIso8601String(),
    );
  }
}
