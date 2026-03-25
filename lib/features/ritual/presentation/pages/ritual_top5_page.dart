// 데일리 리추얼 Page 7: Top 5 선택 페이지
// 25개 목표를 스크롤 가능한 리스트로 표시하고, 정확히 5개를 선택하게 한다.
// 선택되지 않은 20개는 취소선과 함께 "Avoid List"로 표시된다.

import 'package:flutter/material.dart';

import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../widgets/goal_check_item.dart';
import '../widgets/ritual_glass_container.dart';

/// Top 5 선택 페이지 (Page 7)
/// [goals]: 25개 목표 텍스트 리스트
/// [selectedIndices]: 선택된 목표 인덱스 Set
/// [onToggle]: 목표 선택/해제 콜백
/// [onResetSelection]: 선택 초기화 콜백
/// [isPreSelected]: true이면 기존 선택이 로드된 상태 (안내 문구 표시)
class RitualTop5Page extends StatelessWidget {
  final List<String> goals;
  final Set<int> selectedIndices;
  final ValueChanged<int> onToggle;
  final VoidCallback? onResetSelection;
  final bool isPreSelected;

  const RitualTop5Page({
    super.key,
    required this.goals,
    required this.selectedIndices,
    required this.onToggle,
    this.onResetSelection,
    this.isPreSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;
    final selectedCount = selectedIndices.length;

    // 부모(DailyRitualScreen)에서 SafeArea + 상하 패딩을 이미 적용한다
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          _buildHeader(tc, selectedCount),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: RitualGlassContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: _buildGoalList(tc, selectedCount),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  /// 헤더: 제목 + 선택 카운터 + 초기화 버튼 + 프리셀렉트 안내
  Widget _buildHeader(ResolvedThemeColors tc, int count) {
    final isComplete = count == 5;
    final completeColor = tc.isOnDarkBackground
        ? const Color(0xFF4ADE80)
        : const Color(0xFF22C55E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top 5를 선택하세요',
          style: AppTypography.headingLg.copyWith(
            color: tc.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Icon(
              isComplete
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              // 어두운 배경에서도 아이콘이 잘 보이도록 다크 모드 대응
              color: isComplete ? completeColor : tc.accent,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '5개 중 $count개 선택됨',
              style: AppTypography.bodyMd.copyWith(
                color: isComplete
                    ? completeColor
                    : tc.textPrimaryWithAlpha(0.70),
              ),
            ),
            const Spacer(),
            // 1개 이상 선택 시 초기화 버튼 표시
            if (count > 0)
              _buildResetButton(tc),
          ],
        ),
        // 프리셀렉트 안내 문구 (재방문 사용자만)
        if (isPreSelected) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            '이전 선택을 확인하고, '
            '변경이 필요하면 수정하세요.',
            style: AppTypography.captionMd.copyWith(
              color: tc.accent.withValues(alpha: 0.70),
            ),
          ),
        ],
      ],
    );
  }

  /// 선택 초기화 버튼 — 선택된 모든 항목을 한 번에 해제한다
  Widget _buildResetButton(ResolvedThemeColors tc) {
    return GestureDetector(
      onTap: onResetSelection,
      child: Text(
        '선택 초기화',
        style: AppTypography.captionMd.copyWith(
          color: tc.textPrimaryWithAlpha(0.50),
          decoration: TextDecoration.underline,
          decorationColor: tc.textPrimaryWithAlpha(0.30),
        ),
      ),
    );
  }

  /// 목표 선택 리스트 (스크롤 가능)
  Widget _buildGoalList(ResolvedThemeColors tc, int count) {
    return ListView.builder(
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goalText = goals[index];
        if (goalText.trim().isEmpty) return const SizedBox.shrink();

        final isSelected = selectedIndices.contains(index);
        return GoalCheckItem(
          index: index,
          text: goalText,
          isSelected: isSelected,
          canSelect: count < 5 || isSelected,
          onToggle: () => onToggle(index),
        );
      },
    );
  }
}
