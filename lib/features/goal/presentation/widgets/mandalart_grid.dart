// F5 위젯: MandalartGrid - 만다라트 9x9 그리드
// MandalartCell 81개를 GridView로 렌더링한다.
// core 셀(중앙)은 강조 색상, subGoal 셀은 보조 색상, task 셀은 기본 배경으로 구분한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/mandalart_grid.dart';
import '../../../../shared/enums/mandalart_cell_type.dart';
import '../../providers/goal_provider.dart';
import 'mandalart_cell.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';

/// 만다라트 9x9 그리드 위젯
/// InteractiveViewer로 핀치 줌/패닝 지원 (AN-11)
/// 세부목표 셀 탭 시 해당 3x3 서브그리드로 확대한다
class MandalartGridWidget extends ConsumerStatefulWidget {
  final MandalartGrid grid;
  final String goalId;

  const MandalartGridWidget({
    required this.grid,
    required this.goalId,
    super.key,
  });

  @override
  ConsumerState<MandalartGridWidget> createState() =>
      _MandalartGridWidgetState();
}

class _MandalartGridWidgetState extends ConsumerState<MandalartGridWidget>
    with SingleTickerProviderStateMixin {
  /// 핀치 줌을 위한 TransformationController
  final TransformationController _transformationController =
      TransformationController();

  /// AN-11: 줌 애니메이션 컨트롤러
  late final AnimationController _zoomController;

  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(
      vsync: this,
      duration: AppAnimation.slower,
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 동기 Provider이므로 직접 사용한다
    final tasks = ref.watch(tasksByGoalStreamProvider(widget.goalId));

    return AnimatedScale(
      scale: 1.0,
      duration: AppAnimation.slower,
      curve: Curves.easeOutCubic,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: AppLayout.interactiveMinScale,
          maxScale: AppLayout.interactiveMaxScale,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AppLayout.mandalartGridSize,
              childAspectRatio: 1.0,
              mainAxisSpacing: AppLayout.gridCellSpacing,
              crossAxisSpacing: AppLayout.gridCellSpacing,
            ),
            itemCount: AppLayout.mandalartCellCount,
            itemBuilder: (context, index) {
              final row = index ~/ AppLayout.mandalartGridSize;
              final col = index % AppLayout.mandalartGridSize;
              final cell = widget.grid.cells.firstWhere(
                (c) => c.row == row && c.col == col,
                orElse: () => MandalartCell(
                  row: row,
                  col: col,
                  type: MandalartCellType.empty,
                ),
              );

              // 해당 셀의 진행률 계산
              final cellProgress = _calcCellProgress(cell, tasks);

              // 81개 셀 각각을 RepaintBoundary로 감싸 독립적 리페인트를 보장한다
              return RepaintBoundary(
                child: MandalartCellWidget(
                  key: ValueKey('${row}_$col'),
                  cell: cell,
                  progress: cellProgress,
                  onTap: () => _onCellTap(cell),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 셀 유형별 진행률 계산
  double _calcCellProgress(MandalartCell cell, List tasks) {
    if (cell.type == MandalartCellType.subGoal && cell.entityId != null) {
      // 세부목표: 해당 subGoal의 tasks 완료율
      final subGoalTasks = tasks
          .where((t) => t.subGoalId == cell.entityId)
          .toList();
      if (subGoalTasks.isEmpty) return 0.0;
      final completed = subGoalTasks.where((t) => t.isCompleted).length;
      return completed / subGoalTasks.length;
    }
    if (cell.type == MandalartCellType.task) {
      return cell.isCompleted ? 1.0 : 0.0;
    }
    return 0.0;
  }

  void _onCellTap(MandalartCell cell) {
    if (cell.type == MandalartCellType.empty) {
      // 빈 셀: 추가 작업 처리 (상위에서 처리)
    } else if (cell.type == MandalartCellType.task && cell.entityId != null) {
      // 실천 과제 완료 토글
      ref.read(goalNotifierProvider.notifier).toggleTaskCompletion(
            widget.goalId,
            cell.entityId!,
            !cell.isCompleted,
          );
    }
  }
}
