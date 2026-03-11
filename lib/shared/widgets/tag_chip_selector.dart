// 공용 위젯: TagChipSelector (태그 다중 선택 칩 위젯)
// 사용자의 태그 목록을 FilterChip으로 표시하고 다중 선택을 지원한다.
// "+" 버튼으로 새 태그를 인라인 생성할 수 있다.
// colorIndex별 색상은 ColorTokens.eventColor 팔레트를 재사용한다.
// 투두/일정/목표 생성 다이얼로그에서 공통으로 사용한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
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

/// 태그 다중 선택 칩 위젯
/// selectedTagIds: 현재 선택된 태그 ID Set
/// onChanged: 선택 변경 시 전체 Set을 전달하는 콜백
class TagChipSelector extends ConsumerStatefulWidget {
  /// 현재 선택된 태그 ID 집합
  final Set<String> selectedTagIds;

  /// 선택 변경 콜백 (변경된 전체 Set을 전달)
  final ValueChanged<Set<String>> onChanged;

  const TagChipSelector({
    super.key,
    required this.selectedTagIds,
    required this.onChanged,
  });

  @override
  ConsumerState<TagChipSelector> createState() => _TagChipSelectorState();
}

class _TagChipSelectorState extends ConsumerState<TagChipSelector> {
  /// 새 태그 인라인 생성 모드 여부
  bool _isCreating = false;
  final _newTagController = TextEditingController();
  int _newTagColorIndex = 0;

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  /// 태그 선택/해제 토글
  void _toggleTag(String tagId) {
    final updated = Set<String>.from(widget.selectedTagIds);
    if (updated.contains(tagId)) {
      updated.remove(tagId);
    } else {
      // 아이템당 최대 5개 제한 확인
      if (updated.length >= Tag.maxTagsPerItem) return;
      updated.add(tagId);
    }
    widget.onChanged(updated);
  }

  /// 새 태그 생성 후 자동 선택
  Future<void> _createAndSelectTag() async {
    final name = _newTagController.text.trim();
    if (name.isEmpty || name.length > 20) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    // 사용자 태그 수 한도 확인
    final currentTags = ref.read(userTagsProvider).value ?? [];
    if (currentTags.length >= Tag.maxTagsPerUser) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('태그는 최대 ${Tag.maxTagsPerUser}개까지 생성할 수 있습니다'),
            backgroundColor: ColorTokens.error,
          ),
        );
      }
      return;
    }

    final generateId = ref.read(generateTagIdProvider);
    final createTag = ref.read(createTagProvider);
    final now = DateTime.now();

    final newTag = Tag(
      id: generateId(),
      userId: userId,
      name: name,
      colorIndex: _newTagColorIndex,
      createdAt: now,
    );

    try {
      await createTag(newTag);

      // 생성된 태그 자동 선택 (아이템당 최대 개수 미초과 시)
      if (widget.selectedTagIds.length < Tag.maxTagsPerItem) {
        final updated = Set<String>.from(widget.selectedTagIds)..add(newTag.id);
        widget.onChanged(updated);
      }

      // 입력 필드 초기화
      setState(() {
        _isCreating = false;
        _newTagController.clear();
        _newTagColorIndex = 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('태그 생성에 실패했습니다'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(userTagsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 섹션 레이블
        Row(
          children: [
            Text(
              '태그',
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.8),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '(최대 ${Tag.maxTagsPerItem}개)',
              style: AppTypography.captionMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.mdLg),

        // 태그 칩 목록 + "+" 버튼
        tagsAsync.when(
          data: (tags) => _buildChips(tags),
          loading: () => _buildLoadingChips(),
          error: (_, __) => _buildErrorText(),
        ),

        // 새 태그 인라인 생성 폼
        if (_isCreating) ...[
          const SizedBox(height: AppSpacing.lg),
          _TagCreateInlineForm(
            controller: _newTagController,
            selectedColorIndex: _newTagColorIndex,
            onColorChanged: (i) => setState(() => _newTagColorIndex = i),
            onConfirm: _createAndSelectTag,
            onCancel: () => setState(() {
              _isCreating = false;
              _newTagController.clear();
              _newTagColorIndex = 0;
            }),
          ),
        ],
      ],
    );
  }

  /// 태그 칩 목록 빌드
  Widget _buildChips(List<Tag> tags) {
    final isDark = ref.watch(isDarkModeProvider);

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        // 기존 태그들
        ...tags.map((tag) {
          final isSelected = widget.selectedTagIds.contains(tag.id);
          final tagColor = ColorTokens.eventColor(tag.colorIndex, isDark: isDark);

          return GestureDetector(
            onTap: () => _toggleTag(tag.id),
            child: AnimatedContainer(
              duration: AppAnimation.normal,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                // 선택 시 태그 색상 배경, 미선택 시 테마 인식 반투명 배경
                color: isSelected
                    ? tagColor.withValues(alpha: 0.85)
                    : context.themeColors.overlayLight,
                borderRadius: BorderRadius.circular(AppRadius.huge),
                border: Border.all(
                  color: isSelected
                      ? tagColor
                      : context.themeColors.borderMedium,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 태그 색상 도트 인디케이터
                  Container(
                    width: AppSpacing.md,
                    height: AppSpacing.md,
                    decoration: BoxDecoration(
                      // 선택 시: 흰색(컬러 배경 위 대비), 미선택 시: 태그 색상
                      color: isSelected
                          ? Colors.white
                          : tagColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // 긴 태그명이 칩을 넘지 않도록 제한한다
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppLayout.donutLarge),
                    child: Text(
                      tag.name,
                      style: AppTypography.captionLg.copyWith(
                        // 선택 시: 흰색(컬러 배경 위 대비), 미선택 시: 테마 텍스트
                        color: isSelected
                            ? Colors.white
                            : context.themeColors.textPrimaryWithAlpha(0.8),
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        // "+" 새 태그 추가 버튼
        if (!_isCreating)
          GestureDetector(
            onTap: () => setState(() => _isCreating = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              // 새 태그 버튼: 배경 테마에 맞는 악센트 색상으로 표시한다
              decoration: BoxDecoration(
                color: context.themeColors.accentWithAlpha(0.15),
                borderRadius: BorderRadius.circular(AppRadius.huge),
                border: Border.all(
                  color: context.themeColors.accentWithAlpha(0.40),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: AppLayout.iconSm,
                    color: context.themeColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '새 태그',
                    style: AppTypography.captionLg.copyWith(
                      color: context.themeColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// 로딩 상태 스켈레톤 칩
  Widget _buildLoadingChips() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: List.generate(3, (i) {
        return Container(
          width: 60 + (i * 10.0),
          height: 30,
          decoration: BoxDecoration(
            color: context.themeColors.overlayLight,
            borderRadius: BorderRadius.circular(AppRadius.huge),
          ),
        );
      }),
    );
  }

  /// 에러 상태 텍스트
  Widget _buildErrorText() {
    return Text(
      '태그를 불러오지 못했습니다',
      style: AppTypography.captionMd.copyWith(
        color: ColorTokens.error.withValues(alpha: 0.7),
      ),
    );
  }
}

// ─── 인라인 태그 생성 폼 ────────────────────────────────────────────────────

/// 태그 이름 입력 + 색상 선택 인라인 폼 (SRP 분리)
class _TagCreateInlineForm extends StatelessWidget {
  final TextEditingController controller;
  final int selectedColorIndex;
  final ValueChanged<int> onColorChanged;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _TagCreateInlineForm({
    required this.controller,
    required this.selectedColorIndex,
    required this.onColorChanged,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tc.overlayLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: tc.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 태그 이름 입력 필드
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            style: AppTypography.bodyLg.copyWith(color: tc.textPrimary),
            cursorColor: tc.textPrimary,
            decoration: InputDecoration(
              hintText: '태그 이름 (최대 20자)',
              hintStyle: AppTypography.bodyLg.copyWith(
                color: tc.hintColor,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.mdLg),

          // 색상 선택 (8색 도트)
          _TagColorPicker(
            selectedIndex: selectedColorIndex,
            onSelected: onColorChanged,
          ),
          const SizedBox(height: AppSpacing.mdLg),

          // 확인/취소 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onCancel,
                child: Text(
                  '취소',
                  style: AppTypography.captionLg.copyWith(
                    color: tc.textPrimaryWithAlpha(0.55),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              GestureDetector(
                onTap: onConfirm,
                child: Text(
                  '추가',
                  style: AppTypography.captionLg.copyWith(
                    // 배경 테마에 맞는 악센트 텍스트 색상을 사용한다
                    color: context.themeColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 태그 색상 피커 ─────────────────────────────────────────────────────────

/// 태그 생성용 8색 색상 도트 피커
class _TagColorPicker extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _TagColorPicker({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(8, (i) {
        final color = ColorTokens.eventColor(i);
        final isSelected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onSelected(i),
          child: AnimatedContainer(
            duration: AppAnimation.fast,
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(right: AppSpacing.md),
            width: isSelected ? AppLayout.iconXxl : AppLayout.iconXl,
            height: isSelected ? AppLayout.iconXxl : AppLayout.iconXl,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: context.themeColors.textPrimary, width: 2)
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
