// F-Memo: 메모 리스트 패널 — 헤더, 검색, 생성 버튼, 고정/일반 메모 리스트
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../models/memo.dart';
import '../../providers/memo_provider.dart';
import 'memo_create_button.dart';
import 'memo_list_item.dart';
import 'memo_search_bar.dart';

// 하위 호환을 위한 배럴 re-export
export 'memo_create_button.dart';
export 'memo_search_bar.dart';

/// 메모 리스트 패널 (좌측 패널 또는 모바일 전체 화면)
class MemoListPanel extends ConsumerStatefulWidget {
  final ValueChanged<String> onMemoSelected;
  final String? selectedMemoId;

  const MemoListPanel({
    super.key,
    required this.onMemoSelected,
    this.selectedMemoId,
  });

  @override
  ConsumerState<MemoListPanel> createState() => _MemoListPanelState();
}

class _MemoListPanelState extends ConsumerState<MemoListPanel> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;
    final memos = ref.watch(memosProvider);
    final filtered = _filterMemos(memos);
    final pinned = filtered.where((m) => m.isPinned).toList();
    final unpinned = filtered.where((m) => !m.isPinned).toList();

    return Column(
      children: [
        _buildHeader(tc),
        const SizedBox(height: AppSpacing.md),
        if (_isSearching)
          MemoSearchBar(
            controller: _searchController,
            onChanged: () => setState(() {}),
          ),
        MemoCreateButton(onTap: _createNewMemo),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(tc)
              : _buildMemoList(pinned, unpinned, tc),
        ),
      ],
    );
  }

  /// "메모" 타이틀 + 검색 토글 아이콘
  Widget _buildHeader(ResolvedThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.xl, AppSpacing.md, 0,
      ),
      child: Row(
        children: [
          Text('메모',
              style: AppTypography.headingSm.copyWith(color: tc.textPrimary)),
          const Spacer(),
          IconButton(
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchController.clear();
            }),
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: tc.textPrimaryWithAlpha(0.65),
              size: AppLayout.iconXl,
            ),
          ),
        ],
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState(ResolvedThemeColors tc) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_alt_outlined,
              size: AppLayout.iconEmpty,
              color: tc.textPrimaryWithAlpha(0.30)),
          const SizedBox(height: AppSpacing.lg),
          Text('메모가 없습니다',
              style: AppTypography.bodyLg
                  .copyWith(color: tc.textPrimaryWithAlpha(0.45))),
          const SizedBox(height: AppSpacing.xs),
          Text('새 메모를 추가해보세요',
              style: AppTypography.captionMd
                  .copyWith(color: tc.textPrimaryWithAlpha(0.35))),
        ],
      ),
    );
  }

  /// 메모 리스트 (고정 + 일반)
  Widget _buildMemoList(
      List<Memo> pinned, List<Memo> unpinned, ResolvedThemeColors tc) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.bottomScrollPadding),
      children: [
        if (pinned.isNotEmpty) ...[
          _buildSectionLabel('고정됨', tc),
          ...pinned.map(_buildItem),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl, vertical: AppSpacing.xs),
            child: Divider(
                color: tc.dividerColor, height: AppLayout.dividerHeight),
          ),
        ],
        if (unpinned.isNotEmpty) ...[
          if (pinned.isNotEmpty) _buildSectionLabel('기타', tc),
          ...unpinned.map(_buildItem),
        ],
      ],
    );
  }

  /// 섹션 레이블
  Widget _buildSectionLabel(String label, ResolvedThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.xs),
      child: Text(label,
          style: AppTypography.captionLg
              .copyWith(color: tc.textPrimaryWithAlpha(0.50))),
    );
  }

  /// 개별 메모 아이템
  Widget _buildItem(Memo memo) {
    return MemoListItem(
      memo: memo,
      isSelected: widget.selectedMemoId == memo.id,
      onTap: () => widget.onMemoSelected(memo.id),
    );
  }

  /// 검색어 기반 메모 필터링
  List<Memo> _filterMemos(List<Memo> memos) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return memos;
    return memos.where((m) {
      return m.title.toLowerCase().contains(query) ||
          m.content.toLowerCase().contains(query);
    }).toList();
  }

  /// 새 메모를 생성하고 선택한다
  Future<void> _createNewMemo() async {
    final create = ref.read(createMemoProvider);
    final now = DateTime.now();
    final newId = 'memo_${now.millisecondsSinceEpoch}';
    final newMemo = Memo(
      id: newId,
      title: '새 메모',
      createdAt: now,
      updatedAt: now,
    );
    final id = await create(newMemo);
    widget.onMemoSelected(id);
  }
}
