// F16: 태그 관리 화면
// 사용자 태그 목록 표시, 새 태그 생성, 태그 편집, 태그 삭제를 제공한다.
// 최대 20개 태그 한도를 화면에서 명시적으로 표시한다.
// SRP 분리: 태그 아이템 → TagListItem / 태그 폼 → TagFormSheet
//          색상 선택 → TagColorPicker / 이름 입력 → TagNameField
//          태그 목록 → TagListView / 삭제 다이얼로그 → showTagDeleteDialog
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/tag.dart';
import '../../../../shared/providers/tag_provider.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'tag_form_sheet.dart';
import 'tag_list_view.dart';
import 'tag_delete_dialog.dart';

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
              child: TagListView(
                tags: tags,
                onEdit: (tag) => _showTagFormSheet(context, ref, tag: tag),
                onDelete: (tag) => showTagDeleteDialog(context, ref, tag),
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
      AppSnackBar.showInfo(
        context,
        '태그는 최대 ${Tag.maxTagsPerUser}개까지 생성할 수 있습니다',
      );
      return;
    }

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorTokens.transparent,
      barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.4),
      builder: (ctx) => TagFormSheet(editTag: tag),
    );
  }
}

// ─── 헤더 위젯 ──────────────────────────────────────────────────────────────

/// 태그 관리 화면 상단 헤더 (뒤로가기 + 제목 + 추가 버튼)
class _TagManagementHeader extends StatelessWidget {
  final VoidCallback onAddTap;

  const _TagManagementHeader({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.pageVertical,
        AppSpacing.pageHorizontal,
        0,
      ),
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
              style: AppTypography.headingSm.copyWith(
                color: context.themeColors.textPrimary,
              ),
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
