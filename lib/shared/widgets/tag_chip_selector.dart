// 태그 다중 선택 칩 위젯 — 투두/일정/목표 생성 다이얼로그 공용
// "+" 버튼으로 인라인 태그 생성, colorIndex 색상은 eventColor 팔레트 재사용
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/global_providers.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';
import '../models/tag.dart';
import '../providers/tag_provider.dart';
import 'app_snack_bar.dart';
import 'tag_add_button.dart';
import 'tag_chip.dart';
import 'tag_create_inline_form.dart';

/// 태그 다중 선택 칩 위젯
class TagChipSelector extends ConsumerStatefulWidget {
  /// 현재 선택된 태그 ID 집합
  final Set<String> selectedTagIds;

  /// 선택 변경 콜백
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
  bool _isCreating = false; // 새 태그 인라인 생성 모드 여부
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
    if (name.isEmpty || name.length > Tag.nameMaxLength) return;

    // 로컬 퍼스트: 인증 없이도 태그를 생성할 수 있다
    final userId =
        ref.read(currentUserIdProvider) ?? AppConstants.localUserId;

    // 사용자 태그 수 한도 확인
    final currentTags = ref.read(userTagsProvider);
    if (currentTags.length >= Tag.maxTagsPerUser) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          '태그는 최대 ${Tag.maxTagsPerUser}개까지 생성할 수 있습니다',
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
        final updated =
            Set<String>.from(widget.selectedTagIds)..add(newTag.id);
        widget.onChanged(updated);
      }

      _resetCreatingState();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '태그 생성에 실패했습니다');
      }
    }
  }

  void _resetCreatingState() {
    setState(() {
      _isCreating = false;
      _newTagController.clear();
      _newTagColorIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(userTagsProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 섹션 레이블
        _buildLabel(context),
        const SizedBox(height: AppSpacing.mdLg),

        // 태그 칩 목록 + "+" 버튼
        _buildChips(tags, isDark),

        // 새 태그 인라인 생성 폼
        if (_isCreating) ...[
          const SizedBox(height: AppSpacing.lg),
          TagCreateInlineForm(
            controller: _newTagController,
            selectedColorIndex: _newTagColorIndex,
            onColorChanged: (i) =>
                setState(() => _newTagColorIndex = i),
            onConfirm: _createAndSelectTag,
            onCancel: _resetCreatingState,
          ),
        ],
      ],
    );
  }

  /// 섹션 레이블 (태그 + 최대 개수 힌트)
  Widget _buildLabel(BuildContext context) {
    return Row(
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
    );
  }

  /// 태그 칩 목록 빌드
  Widget _buildChips(List<Tag> tags, bool isDark) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        // 기존 태그들
        ...tags.map((tag) {
          final tagColor =
              ColorTokens.eventColor(tag.colorIndex, isDark: isDark);
          return TagChip(
            name: tag.name,
            tagColor: tagColor,
            isSelected: widget.selectedTagIds.contains(tag.id),
            onTap: () => _toggleTag(tag.id),
          );
        }),

        // "+" 새 태그 추가 버튼
        if (!_isCreating)
          TagAddButton(
            onTap: () => setState(() => _isCreating = true),
          ),
      ],
    );
  }
}
