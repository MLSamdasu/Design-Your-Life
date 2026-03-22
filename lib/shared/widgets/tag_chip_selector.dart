// 공용 위젯: TagChipSelector (태그 다중 선택 칩 위젯)
// 사용자의 태그 목록을 FilterChip으로 표시하고 다중 선택을 지원한다.
// "+" 버튼으로 새 태그를 인라인 생성할 수 있다.
// colorIndex별 색상은 ColorTokens.eventColor 팔레트를 재사용한다.
// 투두/일정/목표 생성 다이얼로그에서 공통으로 사용한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/constants/app_constants.dart';
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
import 'app_snack_bar.dart';

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
    if (name.isEmpty || name.length > Tag.nameMaxLength) return;

    // 로컬 퍼스트: 인증 없이도 태그를 생성할 수 있다
    final userId = ref.read(currentUserIdProvider) ?? AppConstants.localUserId;

    // 사용자 태그 수 한도 확인
    // userTagsProvider는 동기 Provider이므로 직접 사용한다
    final currentTags = ref.read(userTagsProvider);
    if (currentTags.length >= Tag.maxTagsPerUser) {
      if (mounted) {
        AppSnackBar.showError(context, '태그는 최대 ${Tag.maxTagsPerUser}개까지 생성할 수 있습니다');
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
        AppSnackBar.showError(context, '태그 생성에 실패했습니다');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // userTagsProvider는 동기 Provider이므로 직접 사용한다
    final tags = ref.watch(userTagsProvider);

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

        // 태그 칩 목록 + "+" 버튼 — 동기 Provider이므로 직접 렌더링
        _buildChips(tags),

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
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: AppAnimation.normal,
              curve: Curves.easeOutCubic,
              // WCAG 2.1 터치 타겟 44px 이상 확보 (vertical 16px + text ~14px + 16px = 46px)
              constraints: const BoxConstraints(minHeight: AppLayout.minTouchTarget),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
                  width: isSelected ? AppLayout.borderMedium : AppLayout.borderThin,
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
                          ? ColorTokens.white
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
                            ? ColorTokens.white
                            : context.themeColors.textPrimaryWithAlpha(0.8),
                        fontWeight: isSelected
                            ? AppTypography.weightBold
                            : AppTypography.weightMedium,
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
            behavior: HitTestBehavior.opaque,
            child: Container(
              // WCAG 2.1 터치 타겟 44px 이상 확보
              constraints: const BoxConstraints(minHeight: AppLayout.minTouchTarget),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              // 새 태그 버튼: 테마 인식 텍스트 색상으로 배경과 충분한 대비를 확보한다
              decoration: BoxDecoration(
                color: context.themeColors.overlayLight,
                borderRadius: BorderRadius.circular(AppRadius.huge),
                border: Border.all(
                  color: context.themeColors.borderMedium,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: AppLayout.iconSm,
                    color: context.themeColors.textPrimaryWithAlpha(0.8),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '새 태그',
                    style: AppTypography.captionLg.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
            maxLength: Tag.nameMaxLength,
            style: AppTypography.bodyLg.copyWith(color: tc.textPrimary),
            cursorColor: tc.textPrimary,
            decoration: InputDecoration(
              hintText: '태그 이름 (최대 ${Tag.nameMaxLength}자)',
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
              // WCAG 2.1 터치 타겟 44px 이상 확보
              GestureDetector(
                onTap: onCancel,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: AppLayout.minTouchTarget,
                    minHeight: AppLayout.minTouchTarget,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '취소',
                    style: AppTypography.captionLg.copyWith(
                      color: tc.textPrimaryWithAlpha(0.55),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              GestureDetector(
                onTap: onConfirm,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: AppLayout.minTouchTarget,
                    minHeight: AppLayout.minTouchTarget,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '추가',
                    style: AppTypography.captionLg.copyWith(
                      // WCAG 대비: 글래스 배경 위에서 테마 텍스트 색상으로 고대비 확보
                      color: context.themeColors.textPrimaryWithAlpha(0.85),
                      fontWeight: AppTypography.weightBold,
                    ),
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
    // Wrap으로 변경하여 좁은 화면에서도 오버플로우를 방지한다
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: List.generate(8, (i) {
        final color = ColorTokens.eventColor(i);
        final isSelected = i == selectedIndex;
        // WCAG 2.1 터치 타겟 44px 이상 확보: GestureDetector 영역을 확장한다
        return GestureDetector(
          onTap: () => onSelected(i),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: AppLayout.minTouchTarget,
            height: AppLayout.minTouchTarget,
            child: Center(
              child: AnimatedContainer(
                duration: AppAnimation.fast,
                curve: Curves.easeOutCubic,
                width: isSelected ? AppLayout.iconXxl : AppLayout.iconXl,
                height: isSelected ? AppLayout.iconXxl : AppLayout.iconXl,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: context.themeColors.textPrimary, width: AppLayout.borderThick)
                      : null,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
