// F5 위젯: MandalartView - 만다라트 뷰 컨테이너
// MandalartGrid(9x9)를 렌더링하고 목표가 없을 때 생성 유도 UI를 표시한다.
// SRP 분리: 빈 상태 → mandalart_empty_state.dart, 헤더 → mandalart_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../providers/goal_provider.dart';
import '../../providers/mandalart_provider.dart';
import 'mandalart_empty_state.dart';
import 'mandalart_grid.dart';
import 'mandalart_header.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 만다라트 뷰 컨테이너
/// 목표 선택 드롭다운 + 9x9 그리드 또는 빈 상태 위젯을 렌더링한다
class MandalartView extends ConsumerWidget {
  const MandalartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsStreamProvider);

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return MandalartEmptyState(
            onCreateTap: () => showMandalartWizard(context),
          );
        }

        // 선택된 목표 ID 동기화: 없으면 첫 번째 목표 자동 선택
        final selectedId = ref.watch(selectedMandalartGoalIdProvider);
        final effectiveId = selectedId ?? goals.first.id;

        // 선택 상태가 없으면 첫 번째 목표로 자동 지정 (빌드 사이클 이후 적용)
        if (selectedId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedMandalartGoalIdProvider.notifier).state =
                effectiveId;
          });
        }

        return Column(
          children: [
            // 상단: 목표 선택 드롭다운 + 새 만다라트 버튼 — 수평 패딩 20px
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: MandalartHeader(
                goals: goals,
                selectedId: effectiveId,
                onCreateTap: () => showMandalartWizard(context),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // 그리드 렌더링 영역 — 수평 패딩 20px
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: _MandalartGridSection(goalId: effectiveId),
              ),
            ),
          ],
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: context.themeColors.textPrimary),
      ),
      error: (_, __) => Center(
        child: Text(
          '만다라트를 불러올 수 없어요',
          style: AppTypography.bodyLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.6),
          ),
        ),
      ),
    );
  }
}

/// 선택된 목표의 만다라트 그리드를 표시하는 섹션
class _MandalartGridSection extends ConsumerWidget {
  final String goalId;

  const _MandalartGridSection({required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gridAsync = ref.watch(mandalartGridProvider(goalId));

    return gridAsync.when(
      data: (grid) {
        if (grid == null) {
          return MandalartEmptyState(
            onCreateTap: () => showMandalartWizard(context),
            message: '이 목표에 만다라트가 없어요',
          );
        }
        // 그리드 렌더링 (InteractiveViewer 포함)
        return MandalartGridWidget(grid: grid, goalId: goalId);
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: context.themeColors.textPrimary),
      ),
      error: (_, __) => Center(
        child: Text(
          '만다라트를 불러올 수 없어요',
          style: AppTypography.bodyLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.6),
          ),
        ),
      ),
    );
  }
}
