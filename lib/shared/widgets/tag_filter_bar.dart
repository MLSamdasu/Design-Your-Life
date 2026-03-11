// 공용 위젯: TagFilterBar (태그 필터 바)
// 수평 스크롤 가능한 태그 칩 행으로 투두/일정/목표 목록 상단에 배치된다.
// "전체" 칩 탭 시 필터를 초기화한다.
// selectedTagFilterProvider를 통해 전역 필터 상태를 관리한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/global_providers.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';
import '../models/tag.dart';
import '../providers/tag_provider.dart';

/// 태그 필터 바 위젯
/// 수평 스크롤 행으로 "전체" + 사용자 태그 칩을 표시한다
class TagFilterBar extends ConsumerWidget {
  const TagFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(userTagsProvider);
    final selectedTagIds = ref.watch(selectedTagFilterProvider);

    return tagsAsync.when(
      data: (tags) {
        // 태그가 없으면 표시하지 않는다
        if (tags.isEmpty) return const SizedBox.shrink();

        return _buildFilterBar(context, ref, tags, selectedTagIds);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// 필터 바 본체 빌드
  Widget _buildFilterBar(
    BuildContext context,
    WidgetRef ref,
    List<Tag> tags,
    Set<String> selectedTagIds,
  ) {
    final isDark = ref.watch(isDarkModeProvider);

    return SizedBox(
      height: AppLayout.filterBarHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
        children: [
          // "전체" 칩 (필터 초기화)
          _FilterChipItem(
            label: '전체',
            isSelected: selectedTagIds.isEmpty,
            color: context.themeColors.accent,
            onTap: () {
              // 필터 초기화
              ref.read(selectedTagFilterProvider.notifier).state = const {};
            },
          ),
          const SizedBox(width: AppSpacing.md),

          // 사용자 태그 칩 목록
          ...tags.map((tag) {
            final isSelected = selectedTagIds.contains(tag.id);
            final tagColor = ColorTokens.eventColor(tag.colorIndex, isDark: isDark);

            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _FilterChipItem(
                label: tag.name,
                isSelected: isSelected,
                color: tagColor,
                onTap: () => _toggleTagFilter(ref, tag.id, selectedTagIds),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 태그 필터 토글
  void _toggleTagFilter(
    WidgetRef ref,
    String tagId,
    Set<String> currentSelected,
  ) {
    final updated = Set<String>.from(currentSelected);
    if (updated.contains(tagId)) {
      updated.remove(tagId);
    } else {
      updated.add(tagId);
    }
    ref.read(selectedTagFilterProvider.notifier).state = updated;
  }
}

// ─── 필터 칩 아이템 ──────────────────────────────────────────────────────────

/// 개별 태그 필터 칩 위젯 (SRP 분리)
class _FilterChipItem extends StatelessWidget {
  /// 칩 레이블 텍스트
  final String label;

  /// 선택 여부
  final bool isSelected;

  /// 칩 테마 색상
  final Color color;

  /// 탭 콜백
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.normal,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lgXl, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          // 선택 시 태그 색상 채우기, 미선택 시 테마 인식 반투명 배경
          color: isSelected
              ? color.withValues(alpha: 0.85)
              : context.themeColors.overlayLight,
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(
            color: isSelected
                ? color
                : context.themeColors.borderMedium,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.captionLg.copyWith(
            // 선택 시: 흰색(컬러 배경 위 대비), 미선택 시: 테마 텍스트
            color: isSelected
                ? Colors.white
                : context.themeColors.textPrimaryWithAlpha(0.75),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
