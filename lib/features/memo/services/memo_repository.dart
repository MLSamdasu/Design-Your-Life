// F-Memo: MemoRepository (로컬 퍼스트 아키텍처)
// 모든 CRUD는 Hive 로컬 저장소에서 수행한다.
// 인터넷 없이도 완전히 동작한다.

import 'package:uuid/uuid.dart';

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/memo.dart';

/// 메모 저장소 (로컬 퍼스트 아키텍처)
/// Hive 로컬 저장소를 기본 저장소로 사용하여 오프라인에서도 완전히 동작한다
class MemoRepository {
  final HiveCacheService _cache;

  /// Hive에서 메모 데이터를 저장하는 박스 이름
  static const _boxName = AppConstants.memosBox;

  /// UUID 생성기 (로컬에서 UUID를 생성한다)
  static const _uuid = Uuid();

  MemoRepository({required HiveCacheService cache}) : _cache = cache;

  // ─── 조회 ──────────────────────────────────────────────────────────────────

  /// 전체 메모 목록을 로컬 Hive에서 조회한다
  List<Memo> getAllMemos() {
    final items = _cache.getAll(_boxName);
    return items.map((m) => Memo.fromMap(m)).toList();
  }

  /// 특정 메모를 ID로 조회한다
  Memo? getMemo(String memoId) {
    final map = _cache.get(_boxName, memoId);
    if (map == null) return null;
    return Memo.fromMap(map);
  }

  // ─── 생성 ──────────────────────────────────────────────────────────────────

  /// 새 메모를 로컬 Hive에 생성한다
  /// 생성된 메모의 ID를 반환한다
  Future<String> createMemo(Memo memo) async {
    final id = memo.id.isNotEmpty ? memo.id : _uuid.v4();
    final now = DateTime.now();

    // INSERT용 맵을 생성하고 메타 필드를 추가한다
    final map = memo.toInsertMap(AppConstants.localUserId)
      ..['id'] = id
      ..['created_at'] = now.toIso8601String()
      ..['updated_at'] = now.toIso8601String();

    // Hive에 저장 완료를 대기한다
    await _cache.put(_boxName, id, map);
    return id;
  }

  // ─── 수정 ──────────────────────────────────────────────────────────────────

  /// 메모를 수정한다
  /// 기존 id와 created_at을 유지하고 나머지 필드를 업데이트한다
  Future<Memo?> updateMemo(String memoId, Memo memo) async {
    final existing = _cache.get(_boxName, memoId);
    // 해당 ID의 항목이 없으면 null을 반환한다
    if (existing == null) return null;

    // UPDATE용 맵에 메타 필드를 추가한다
    final updatedMap = memo.toUpdateMap()
      ..['id'] = memoId
      ..['user_id'] = existing['user_id'] ?? AppConstants.localUserId
      ..['created_at'] = existing['created_at']
      ..['updated_at'] = DateTime.now().toIso8601String();

    // Hive에 저장 완료를 대기한다
    await _cache.put(_boxName, memoId, updatedMap);
    return Memo.fromMap(updatedMap);
  }

  // ─── 삭제 ──────────────────────────────────────────────────────────────────

  /// 메모를 로컬 Hive에서 삭제한다
  Future<void> deleteMemo(String memoId) async {
    await _cache.deleteById(_boxName, memoId);
  }
}
