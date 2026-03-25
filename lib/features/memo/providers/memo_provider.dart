// F-Memo: 메모 Provider
// Repository 초기화, 목록 조회, 선택 상태, CRUD 액션을 담당한다.
// CRUD 후 memoDataVersionProvider를 증가시켜 전체 파생 체인이 자동 갱신된다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../models/memo.dart';
import '../services/memo_repository.dart';

// ─── Repository Provider ────────────────────────────────────────────────────

/// MemoRepository Provider (로컬 퍼스트)
/// HiveCacheService를 주입받아 로컬 Hive 저장소에 접근한다
final memoRepositoryProvider = Provider<MemoRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return MemoRepository(cache: cache);
});

// ─── 메모 목록 Provider (SSOT에서 파생) ──────────────────────────────────────

/// 전체 메모 목록 Provider (고정 메모 우선, 최신 수정순 정렬)
/// allMemosRawProvider를 Single Source of Truth로 사용한다
final memosProvider = Provider<List<Memo>>((ref) {
  final rawList = ref.watch(allMemosRawProvider);
  final memos = rawList.map((m) => Memo.fromMap(m)).toList();

  // 고정 메모 우선 → 수정 시각 최신순 정렬
  memos.sort((a, b) {
    if (a.isPinned != b.isPinned) {
      return a.isPinned ? -1 : 1;
    }
    return b.updatedAt.compareTo(a.updatedAt);
  });

  return memos;
});

// ─── 선택 상태 Provider ─────────────────────────────────────────────────────

/// 현재 선택된 메모 ID
final selectedMemoIdProvider = StateProvider<String?>((ref) => null);

/// 현재 선택된 메모 객체 (파생 Provider)
/// memosProvider + selectedMemoIdProvider로부터 파생한다
final selectedMemoProvider = Provider<Memo?>((ref) {
  final selectedId = ref.watch(selectedMemoIdProvider);
  if (selectedId == null) return null;

  final memos = ref.watch(memosProvider);
  try {
    return memos.firstWhere((m) => m.id == selectedId);
  } catch (_) {
    // 해당 ID의 메모가 없으면 null 반환
    return null;
  }
});

// ─── 메모 CRUD 액션 Provider ────────────────────────────────────────────────

/// 메모 생성 액션
/// 로컬 Hive에 저장하고 버전 카운터를 증가시킨다
/// 생성된 메모 ID를 반환한다
final createMemoProvider = Provider<Future<String> Function(Memo)>((ref) {
  final repository = ref.watch(memoRepositoryProvider);

  return (Memo memo) async {
    final id = await repository.createMemo(memo);
    // 버전 카운터 증가 → allMemosRawProvider 재평가 → 메모 목록 자동 갱신
    ref.read(memoDataVersionProvider.notifier).state++;
    return id;
  };
});

/// 메모 수정 액션
/// 기존 메모의 필드를 업데이트하고 버전 카운터를 증가시킨다
final updateMemoProvider =
    Provider<Future<void> Function(String, Memo)>((ref) {
  final repository = ref.watch(memoRepositoryProvider);

  return (String memoId, Memo memo) async {
    await repository.updateMemo(memoId, memo);
    // 버전 카운터 증가 → 모든 파생 Provider 자동 갱신
    ref.read(memoDataVersionProvider.notifier).state++;
  };
});

/// 메모 삭제 액션
/// 삭제 후 선택 상태가 해당 메모를 가리키면 선택을 해제한다
final deleteMemoProvider = Provider<Future<void> Function(String)>((ref) {
  final repository = ref.watch(memoRepositoryProvider);

  return (String memoId) async {
    await repository.deleteMemo(memoId);

    // 삭제된 메모가 현재 선택된 메모이면 선택 해제한다
    if (ref.read(selectedMemoIdProvider) == memoId) {
      ref.read(selectedMemoIdProvider.notifier).state = null;
    }

    // 버전 카운터 증가 → 모든 파생 Provider 자동 갱신
    ref.read(memoDataVersionProvider.notifier).state++;
  };
});
