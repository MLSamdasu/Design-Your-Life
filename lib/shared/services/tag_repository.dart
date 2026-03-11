// 공유 서비스: TagRepository (로컬 퍼스트 아키텍처)
// Hive tagsBox에 태그를 저장/조회한다.
// 인증 없이도 태그 기능이 정상 동작한다.

import '../../core/cache/hive_cache_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/tag.dart';

/// 태그 저장소 (로컬 퍼스트)
/// Hive tagsBox에 태그 데이터를 저장한다
/// 인증 상태와 무관하게 로컬 데이터를 유지한다
class TagRepository {
  final HiveCacheService _cache;

  TagRepository({required HiveCacheService cache}) : _cache = cache;

  // ─── 태그 목록 조회 ───────────────────────────────────────────────────────
  /// 사용자의 모든 태그를 Hive에서 조회한다
  /// 생성 시각 오름차순으로 정렬하여 반환한다
  Future<List<Tag>> getTags() async {
    final all = _cache.getAll(AppConstants.tagsBox);

    // created_at 오름차순 정렬 (먼저 생성된 태그가 상단에 위치)
    all.sort((a, b) {
      final aTime =
          DateTime.tryParse(a['createdAt'] as String? ?? '') ?? DateTime(0);
      final bTime =
          DateTime.tryParse(b['createdAt'] as String? ?? '') ?? DateTime(0);
      return aTime.compareTo(bTime);
    });

    return all.map(_fromHiveMap).toList();
  }

  // ─── 태그 생성 ────────────────────────────────────────────────────────────
  /// 새 태그를 Hive에 저장하고 저장된 Tag 객체를 반환한다
  /// ID는 클라이언트에서 타임스탬프 기반으로 생성한다
  Future<Tag> createTag(Tag tag) async {
    // 태그 생성 시각을 ID로 사용한다 (로컬 퍼스트에서는 서버 ID 불필요)
    final id = tag.id.isNotEmpty
        ? tag.id
        : DateTime.now().millisecondsSinceEpoch.toString();

    final now = tag.createdAt;
    final newTag = Tag(
      id: id,
      userId: tag.userId,
      name: tag.name,
      colorIndex: tag.colorIndex,
      createdAt: now,
    );

    await _cache.put(
      AppConstants.tagsBox,
      id,
      _toHiveMap(newTag),
    );

    return newTag;
  }

  // ─── 태그 수정 ────────────────────────────────────────────────────────────
  /// 기존 태그를 수정하고 수정된 Tag 객체를 반환한다
  Future<Tag> updateTag(Tag tag) async {
    await _cache.update(
      AppConstants.tagsBox,
      tag.id,
      _toHiveMap(tag),
    );
    return tag;
  }

  // ─── 태그 삭제 ────────────────────────────────────────────────────────────
  /// 태그를 ID 기반으로 Hive에서 삭제한다
  Future<void> deleteTag(String tagId) async {
    await _cache.deleteById(AppConstants.tagsBox, tagId);
  }

  // ─── 백업 전용 직렬화 ─────────────────────────────────────────────────────
  /// Hive에서 읽은 모든 태그를 백업용 Map 목록으로 변환한다
  /// BackupService에서 호출한다
  List<Map<String, dynamic>> getAllForBackup() {
    return _cache.getAll(AppConstants.tagsBox);
  }

  /// 백업에서 복원한 데이터로 Hive를 덮어쓴다
  /// BackupService의 restoreFromCloud에서 호출한다
  Future<void> restoreFromBackup(List<Map<String, dynamic>> tags) async {
    // 기존 데이터를 먼저 초기화한다
    await _cache.clearBox(AppConstants.tagsBox);
    for (final tag in tags) {
      final id = tag['id']?.toString();
      if (id == null || id.isEmpty) continue;
      await _cache.put(AppConstants.tagsBox, id, tag);
    }
  }

  // ─── 내부 직렬화 헬퍼 ────────────────────────────────────────────────────
  /// Tag → Hive 저장용 Map 변환
  Map<String, dynamic> _toHiveMap(Tag tag) {
    return {
      'id': tag.id,
      'userId': tag.userId,
      'name': tag.name,
      'colorIndex': tag.colorIndex,
      'createdAt': tag.createdAt.toIso8601String(),
    };
  }

  /// Hive Map → Tag 변환
  Tag _fromHiveMap(Map<String, dynamic> map) {
    return Tag.fromMap(map);
  }
}
