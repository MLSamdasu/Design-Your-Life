// F16: 태그 관리 화면
// 사용자 태그 목록 표시, 새 태그 생성, 태그 편집, 태그 삭제를 제공한다.
// 최대 20개 태그 한도를 화면에서 명시적으로 표시한다.
// SRP 분리: 태그 아이템 → _TagListItem / 태그 폼 → _TagFormSheet
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/global_providers.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/tag.dart';
import '../../../../shared/providers/tag_provider.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 태그 관리 화면 (F16)
/// 설정 화면에서 진입하는 독립 라우트 (하단 탭 없음)
class TagManagementScreen extends ConsumerWidget {
  const TagManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // userTagsProvider는 동기 Provider이므로 직접 사용한다
    final tags = ref.watch(userTagsProvider);

    return Scaffold(
      backgroundColor: ColorTokens.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 헤더
            _TagManagementHeader(
              onAddTap: () => _showTagFormSheet(context, ref, tag: null),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 태그 목록 콘텐츠 — 동기 Provider이므로 직접 렌더링한다
            Expanded(
              child: _TagListContent(
                tags: tags,
                onEdit: (tag) => _showTagFormSheet(context, ref, tag: tag),
                onDelete: (tag) => _confirmDelete(context, ref, tag),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 태그 생성/편집 Bottom Sheet 표시
  Future<void> _showTagFormSheet(
    BuildContext context,
    WidgetRef ref, {
    required Tag? tag,
  }) async {
    // async gap 이전에 태그 수 확인
    // userTagsProvider는 동기 Provider이므로 직접 사용한다
    final currentTags = ref.read(userTagsProvider);

    // 새 태그 생성 시 최대 한도 확인
    if (tag == null && currentTags.length >= Tag.maxTagsPerUser) {
      if (!context.mounted) return;
      AppSnackBar.showInfo(context, '태그는 최대 ${Tag.maxTagsPerUser}개까지 생성할 수 있습니다');
      return;
    }

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorTokens.transparent,
      barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.4),
      builder: (ctx) => _TagFormSheet(editTag: tag),
    );
  }

  /// 태그 삭제 확인 다이얼로그
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.5),
      // 테마 인식 다이얼로그 배경: 모든 테마에서 텍스트 가독성 보장
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeColors.dialogSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.huge),
        ),
        title: Text(
          '태그 삭제',
          style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary),
        ),
        content: Text(
          '"${tag.name}" 태그를 삭제합니다.\n이미 태그가 부착된 아이템에서는 해당 태그가 표시되지 않게 됩니다.',
          style: AppTypography.bodyLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(
              '취소',
              style: AppTypography.titleMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '삭제',
              style: AppTypography.titleMd.copyWith(
                color: ColorTokens.errorLight,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deleteTag = ref.read(deleteTagProvider);
    try {
      await deleteTag(tag.id);
      // 태그 삭제 시 deleteTagProvider가 버전 카운터를 증가시켜 모든 파생 Provider가 자동 갱신된다
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.showError(context, '태그 삭제에 실패했습니다');
    }
  }
}

// ─── 헤더 위젯 ──────────────────────────────────────────────────────────────

/// 태그 관리 화면 상단 헤더
class _TagManagementHeader extends StatelessWidget {
  final VoidCallback onAddTap;

  const _TagManagementHeader({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.pageVertical, AppSpacing.pageHorizontal, 0),
      child: Row(
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: AppLayout.minTouchTarget,
              height: AppLayout.minTouchTarget,
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: context.themeColors.textPrimaryWithAlpha(0.8),
                  size: AppLayout.iconXl,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '태그 관리',
              style: AppTypography.headingSm.copyWith(color: context.themeColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          // 새 태그 추가 버튼
          GestureDetector(
            onTap: onAddTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: AppLayout.minTouchTarget,
              height: AppLayout.minTouchTarget,
              child: Center(
                child: Container(
                  width: AppLayout.containerMd,
                  height: AppLayout.containerMd,
                  // 추가 아이콘 배경: 배경 테마에 맞는 악센트 색상을 사용한다
                  decoration: BoxDecoration(
                    color: context.themeColors.accentWithAlpha(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: context.themeColors.textPrimary,
                    size: AppLayout.iconXl,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 태그 목록 콘텐츠 ────────────────────────────────────────────────────────

/// 태그 목록 + 빈 상태 위젯
class _TagListContent extends StatelessWidget {
  final List<Tag> tags;
  final ValueChanged<Tag> onEdit;
  final ValueChanged<Tag> onDelete;

  const _TagListContent({
    required this.tags,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return _TagEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, 0, AppSpacing.pageHorizontal, AppSpacing.bottomScrollPadding),
      children: [
        // 태그 수 표시 (한도 안내)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Text(
            '${tags.length} / ${Tag.maxTagsPerUser}개',
            style: AppTypography.captionMd.copyWith(
              // WCAG: 태그 수 텍스트 알파 0.55 이상으로 가독성 보장
              color: context.themeColors.textPrimaryWithAlpha(0.55),
            ),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: tags.asMap().entries.map((entry) {
              final i = entry.key;
              final tag = entry.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TagListItem(
                    tag: tag,
                    onEdit: () => onEdit(tag),
                    onDelete: () => onDelete(tag),
                  ),
                  // 마지막 항목 아래는 디바이더 미표시
                  if (i < tags.length - 1)
                    Divider(
                      color: context.themeColors.textPrimaryWithAlpha(0.08),
                      height: 1,
                      indent: AppLayout.tagDividerIndent,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── 태그 목록 아이템 ────────────────────────────────────────────────────────

/// 단일 태그 아이템 위젯 (색상 도트 + 이름 + 편집/삭제)
class _TagListItem extends ConsumerWidget {
  final Tag tag;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TagListItem({
    required this.tag,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final tagColor = ColorTokens.eventColor(tag.colorIndex, isDark: isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Row(
        children: [
          // 색상 도트
          Container(
            width: AppLayout.iconSm,
            height: AppLayout.iconSm,
            decoration: BoxDecoration(
              color: tagColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.lgXl),
          // 태그 이름
          Expanded(
            child: Text(
              tag.name,
              style: AppTypography.bodyLg.copyWith(color: context.themeColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 편집 버튼
          GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: AppLayout.containerLg,
              height: AppLayout.containerLg,
              child: Center(
                child: Icon(
                  // WCAG: 편집 아이콘 알파 0.50 이상으로 가독성 보장
                  Icons.edit_outlined,
                  color: context.themeColors.textPrimaryWithAlpha(0.50),
                  size: AppLayout.iconLg,
                ),
              ),
            ),
          ),
          // 삭제 버튼
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: AppLayout.containerLg,
              height: AppLayout.containerLg,
              child: Center(
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: ColorTokens.errorLight.withValues(alpha: 0.7),
                  size: AppLayout.iconLg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 빈 상태 위젯 ───────────────────────────────────────────────────────────

/// 태그가 없을 때 표시하는 빈 상태 위젯
class _TagEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.label_outline_rounded,
            size: AppLayout.iconEmptyXl,
            // WCAG: 빈 상태 아이콘 알파 0.50 이상으로 가독성 보장
            color: context.themeColors.textPrimaryWithAlpha(0.50),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '아직 태그가 없습니다',
            // WCAG: 빈 상태 제목 알파 0.55 이상으로 가독성 보장
            style: AppTypography.titleMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.55),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '+ 버튼을 눌러 첫 번째 태그를 만들어 보세요',
            // WCAG: 빈 상태 설명 알파 0.55 이상으로 가독성 보장
            style: AppTypography.bodySm.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 태그 생성/편집 Bottom Sheet ────────────────────────────────────────────

/// 태그 이름 + 색상 입력 Bottom Sheet (생성/편집 공용)
class _TagFormSheet extends ConsumerStatefulWidget {
  /// 편집 모드 시 기존 태그, null이면 생성 모드
  final Tag? editTag;

  const _TagFormSheet({this.editTag});

  @override
  ConsumerState<_TagFormSheet> createState() => _TagFormSheetState();
}

class _TagFormSheetState extends ConsumerState<_TagFormSheet> {
  late final TextEditingController _nameController;
  late int _selectedColorIndex;
  bool _isSaving = false;
  String? _nameError;

  bool get _isEditMode => widget.editTag != null;

  @override
  void initState() {
    super.initState();
    // 편집 모드: 기존 값으로 초기화, 생성 모드: 기본값
    _nameController = TextEditingController(
      text: widget.editTag?.name ?? '',
    );
    _selectedColorIndex = widget.editTag?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    setState(() {
      if (name.isEmpty) {
        _nameError = '태그 이름을 입력해주세요';
      } else if (name.length > 20) {
        _nameError = '20자 이내로 입력해주세요';
      } else {
        _nameError = null;
      }
    });
    return _nameError == null;
  }

  /// 저장 처리 (생성 또는 수정)
  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);

    // 로컬 퍼스트: 인증 없이도 태그를 생성/수정할 수 있다
    final userId = ref.read(currentUserIdProvider) ?? AppConstants.localUserId;

    final name = _nameController.text.trim();

    try {
      if (_isEditMode) {
        // 수정 모드: 이름과 색상만 변경한다
        final updateTag = ref.read(updateTagProvider);
        await updateTag(widget.editTag!.copyWith(
          name: name,
          colorIndex: _selectedColorIndex,
        ));
      } else {
        // 생성 모드: 새 태그 ID 생성 후 저장한다
        final generateId = ref.read(generateTagIdProvider);
        final createTag = ref.read(createTagProvider);
        final now = DateTime.now();
        await createTag(Tag(
          id: generateId(),
          userId: userId,
          name: name,
          colorIndex: _selectedColorIndex,
          createdAt: now,
        ));
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.showError(context, _isEditMode ? '태그 수정에 실패했습니다' : '태그 생성에 실패했습니다');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.pill)),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassDecoration.elevatedBlurSigma,
          sigmaY: GlassDecoration.elevatedBlurSigma,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
          decoration: GlassDecoration.modal(),
          padding: EdgeInsets.fromLTRB(AppSpacing.dialogPadding, AppSpacing.dialogPadding, AppSpacing.dialogPadding, AppSpacing.dialogPadding + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 핸들 바
              Center(
                child: Container(
                  width: AppLayout.handleBarWidth,
                  height: AppLayout.handleBarHeight,
                  decoration: BoxDecoration(
                    color: context.themeColors.textPrimaryWithAlpha(0.3),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 제목
              Text(
                _isEditMode ? '태그 수정' : '새 태그 추가',
                style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 이름 입력 필드
              _buildNameField(),
              const SizedBox(height: AppSpacing.xl),

              // 색상 선택 섹션
              _buildColorSection(),
              const SizedBox(height: AppSpacing.xxxl),

              // 저장 버튼
              _buildSaveButton(),
            ],
          ),
        ),
        ),
      ),
    );
  }

  /// 태그 이름 입력 필드
  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '태그 이름',
          style: AppTypography.captionLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedContainer(
          duration: AppAnimation.normal,
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.10),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: _nameError != null
                  ? ColorTokens.error.withValues(alpha: 0.6)
                  : context.themeColors.textPrimaryWithAlpha(0.20),
            ),
          ),
          child: TextField(
            controller: _nameController,
            autofocus: true,
            maxLength: 20,
            style: AppTypography.bodyLg.copyWith(color: context.themeColors.textPrimary),
            cursorColor: context.themeColors.textPrimary,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            decoration: InputDecoration(
              hintText: '태그 이름 (최대 20자)',
              // WCAG: 힌트 텍스트 알파 0.55 이상으로 가독성 보장
              hintStyle: AppTypography.bodyLg.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.55),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lgXl,
              ),
              counterText: '',
            ),
          ),
        ),
        if (_nameError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _nameError!,
            style: AppTypography.captionMd.copyWith(
              color: ColorTokens.error.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );
  }

  /// 색상 선택 섹션
  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '색상',
          style: AppTypography.captionLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.mdLg),
        // Wrap 사용으로 좁은 화면에서도 오버플로우 없이 색상 원을 배치한다
        Wrap(
          spacing: AppSpacing.mdLg,
          runSpacing: AppSpacing.md,
          children: List.generate(8, (i) {
            final color = ColorTokens.eventColor(i);
            final isSelected = i == _selectedColorIndex;
            // WCAG 2.1: 터치 타겟 최소 44px 보장 (시각적 크기는 유지)
            return GestureDetector(
              onTap: () => setState(() => _selectedColorIndex = i),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: AppLayout.minTouchTarget,
                height: AppLayout.minTouchTarget,
                child: Center(
                  child: AnimatedContainer(
                    duration: AppAnimation.fast,
                    curve: Curves.easeOutCubic,
                    width: isSelected ? AppLayout.colorPickerSize : AppLayout.checkboxLg,
                    height: isSelected ? AppLayout.colorPickerSize : AppLayout.checkboxLg,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: context.themeColors.textPrimary, width: AppLayout.borderAccent)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: AppLayout.colorPickerShadowBlur,
                              )
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// 저장 버튼
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _save,
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lgXl),
        decoration: BoxDecoration(
          color: _isSaving
              ? ColorTokens.main.withValues(alpha: 0.5)
              : ColorTokens.main,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: _isSaving
              ? null
              : [
                  BoxShadow(
                    color: ColorTokens.main.withValues(alpha: 0.3),
                    blurRadius: AppLayout.ctaShadowBlur,
                    offset: const Offset(0, AppLayout.ctaShadowOffsetY),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            _isSaving ? '저장 중...' : (_isEditMode ? '수정 완료' : '태그 추가'),
            // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
            style: AppTypography.titleMd.copyWith(color: ColorTokens.white),
          ),
        ),
      ),
    );
  }
}
