// 공유 Provider: 태그 시스템 Riverpod Provider
// tagRepositoryProvider: TagRepository 싱글톤
// userTagsProvider: 사용자 태그 목록 (FutureProvider)
// selectedTagFilterProvider: 태그 필터링 상태 (Set<String>)
// tagByIdProvider: 태그 ID로 단건 조회 (family)
// 로컬 퍼스트: Hive를 기본 저장소로 사용하며 인증 없이도 동작한다
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/global_providers.dart';
import '../models/tag.dart';
import '../services/tag_repository.dart';

// ─── Repository Provider ────────────────────────────────────────────────────

/// TagRepository Provider
/// HiveCacheService를 주입받아 로컬 Hive에 태그를 저장한다
/// 로컬 퍼스트: 인증 없이도 동작한다
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return TagRepository(cache: cache);
});

// ─── 태그 목록 Provider ───────────────────────────────────────────────────

/// 현재 사용자의 모든 태그 목록 Provider (FutureProvider)
/// 로컬 퍼스트: 인증 없이도 로컬 Hive에서 태그 목록을 반환한다
final userTagsProvider = FutureProvider<List<Tag>>((ref) async {
  final repository = ref.watch(tagRepositoryProvider);
  return repository.getTags();
});

// ─── 태그 필터 Provider ─────────────────────────────────────────────────────

/// 태그 필터 상태 Provider
/// 투두/일정/목표 목록에서 선택된 태그 ID 집합을 관리한다
/// 빈 Set이면 "전체" (필터 없음) 상태를 의미한다
final selectedTagFilterProvider = StateProvider<Set<String>>((ref) {
  return const {};
});

// ─── 태그 단건 조회 Provider ────────────────────────────────────────────────

/// 태그 ID로 단건 조회 Provider (family)
/// userTagsProvider의 데이터를 파생하여 Map 조회를 제공한다
/// 삭제된 태그 ID가 아이템에 남아 있는 경우 null을 반환하여 안전하게 처리한다
final tagByIdProvider = Provider.family<Tag?, String>((ref, tagId) {
  final tagsAsync = ref.watch(userTagsProvider);
  return tagsAsync.when(
    data: (tags) {
      try {
        return tags.firstWhere((t) => t.id == tagId);
      } catch (_) {
        // 삭제된 태그 참조: null 반환으로 안전하게 처리한다
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ─── 태그 CRUD 액션 Provider ────────────────────────────────────────────────

/// 태그 생성 액션
/// 로컬 퍼스트: 인증 없이도 로컬에 저장한다
final createTagProvider = Provider<Future<void> Function(Tag)>((ref) {
  final repository = ref.watch(tagRepositoryProvider);

  return (Tag tag) async {
    await repository.createTag(tag);
    // 생성 후 태그 목록을 다시 로드한다
    ref.invalidate(userTagsProvider);
  };
});

/// 태그 수정 액션
/// 로컬 퍼스트: 인증 없이도 로컬에서 수정한다
final updateTagProvider = Provider<Future<void> Function(Tag)>((ref) {
  final repository = ref.watch(tagRepositoryProvider);

  return (Tag tag) async {
    await repository.updateTag(tag);
    // 수정 후 태그 목록을 다시 로드한다
    ref.invalidate(userTagsProvider);
  };
});

/// 태그 삭제 액션
/// 로컬 퍼스트: 인증 없이도 로컬에서 삭제한다
final deleteTagProvider = Provider<Future<void> Function(String)>((ref) {
  final repository = ref.watch(tagRepositoryProvider);

  return (String tagId) async {
    await repository.deleteTag(tagId);
    // 삭제 후 태그 목록을 다시 로드한다
    ref.invalidate(userTagsProvider);
  };
});

/// 새 태그 ID 생성 헬퍼
/// 로컬 퍼스트에서 클라이언트가 타임스탬프 기반으로 ID를 생성한다
final generateTagIdProvider = Provider<String Function()>((ref) {
  return () {
    return DateTime.now().millisecondsSinceEpoch.toString();
  };
});
