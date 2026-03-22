// 공유 Provider: 태그 시스템 Riverpod Provider (Single Source of Truth 아키텍처)
// allTagsRawProvider에서 파생하여 CRUD 시 자동 동기화된다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/data_store_providers.dart';
import '../../core/providers/global_providers.dart';
import '../models/tag.dart';
import '../services/tag_repository.dart';

// ─── Repository Provider ────────────────────────────────────────────────────

/// TagRepository Provider
/// HiveCacheService를 주입받아 로컬 Hive에 태그를 저장한다
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return TagRepository(cache: cache);
});

// ─── 태그 목록 Provider (Single Source of Truth에서 파생) ──────────────────

/// 현재 사용자의 모든 태그 목록 Provider (동기 Provider)
/// allTagsRawProvider(Single Source of Truth)에서 파생하여 CRUD 시 자동 갱신된다
/// Hive 조회는 모두 동기 연산이므로 FutureProvider가 불필요하다.
final userTagsProvider = Provider<List<Tag>>((ref) {
  final allTags = ref.watch(allTagsRawProvider);
  return allTags.map((m) => Tag.fromMap(m)).toList();
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
/// userTagsProvider가 동기 Provider이므로 AsyncValue 래핑이 불필요하다
final tagByIdProvider = Provider.family<Tag?, String>((ref, tagId) {
  final tags = ref.watch(userTagsProvider);
  // firstOrNull: 매칭 실패 시 null 반환 (Dart 3.0+ 컬렉션 확장)
  return tags.where((t) => t.id == tagId).firstOrNull;
});

// ─── 태그 CRUD 액션 Provider ────────────────────────────────────────────────

/// 태그 생성 액션
final createTagProvider = Provider<Future<void> Function(Tag)>((ref) {
  final repository = ref.watch(tagRepositoryProvider);

  return (Tag tag) async {
    await repository.createTag(tag);
    // 버전 카운터 증가 → 모든 파생 Provider 자동 갱신
    ref.read(tagDataVersionProvider.notifier).state++;
  };
});

/// 태그 수정 액션
final updateTagProvider = Provider<Future<void> Function(Tag)>((ref) {
  final repository = ref.watch(tagRepositoryProvider);

  return (Tag tag) async {
    await repository.updateTag(tag);
    // 버전 카운터 증가 → 모든 파생 Provider 자동 갱신
    ref.read(tagDataVersionProvider.notifier).state++;
  };
});

/// 태그 삭제 액션
/// 삭제 시 todosBox/goalsBox에서 해당 태그를 참조하는 orphan tagId를 정리한다
final deleteTagProvider = Provider<Future<void> Function(String)>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  final cache = ref.watch(hiveCacheServiceProvider);

  return (String tagId) async {
    // 1. tagsBox에서 태그 삭제
    await repository.deleteTag(tagId);

    // 2. todosBox에서 orphan tagId 정리
    final allTodos = cache.getAll(AppConstants.todosBox);
    for (final todo in allTodos) {
      final tags = todo['tags'];
      if (tags is! List || tags.isEmpty) continue;

      final originalLength = tags.length;
      final cleaned = tags.where((t) {
        if (t is Map) return t['id']?.toString() != tagId;
        return true;
      }).toList();

      if (cleaned.length < originalLength) {
        final todoId = todo['id']?.toString();
        if (todoId == null) continue;
        todo['tags'] = cleaned;
        await cache.put(AppConstants.todosBox, todoId, todo);
      }
    }

    // 3. goalsBox에서 orphan tagId 정리
    final allGoals = cache.getAll(AppConstants.goalsBox);
    for (final goal in allGoals) {
      final tagIds = goal['tag_ids'];
      if (tagIds is! List || tagIds.isEmpty) continue;

      final originalLen = tagIds.length;
      final cleanedTagIds = tagIds
          .where((id) => id?.toString() != tagId)
          .toList();

      if (cleanedTagIds.length < originalLen) {
        final goalId = goal['id']?.toString();
        if (goalId == null) continue;
        goal['tag_ids'] = cleanedTagIds;
        await cache.put(AppConstants.goalsBox, goalId, goal);
      }
    }

    // 4. 삭제된 태그가 활성 필터에 남아 있으면 제거한다
    final currentFilter = ref.read(selectedTagFilterProvider);
    if (currentFilter.contains(tagId)) {
      ref.read(selectedTagFilterProvider.notifier).state =
          currentFilter.difference({tagId});
    }

    // 5. 버전 카운터 증가 → 태그/투두/목표 관련 Provider 모두 자동 갱신
    ref.read(tagDataVersionProvider.notifier).state++;
    // todosBox/goalsBox도 변경했으므로 해당 버전도 증가시킨다
    ref.read(todoDataVersionProvider.notifier).state++;
    ref.read(goalDataVersionProvider.notifier).state++;
  };
});

/// 새 태그 ID 생성 헬퍼
final generateTagIdProvider = Provider<String Function()>((ref) {
  return () {
    return const Uuid().v4();
  };
});
