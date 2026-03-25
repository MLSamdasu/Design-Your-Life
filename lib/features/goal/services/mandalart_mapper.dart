// F5: MandalartMapper (F5.5) - 순수 함수
// Goal(핵심 목표 1개) + List<SubGoal>(8개) + List<List<GoalTask>>(각 8개)를 받아
// MandalartGrid (9x9 셀 데이터)로 변환한다.
// MandalartGrid는 서버에 저장하지 않는 뷰 전용 객체다.
import '../../../core/theme/layout_tokens.dart';
import '../../../shared/models/goal.dart';
import '../../../shared/models/sub_goal.dart';
import '../../../shared/models/goal_task.dart';
import '../../../shared/models/mandalart_grid.dart';
import '../../../shared/enums/mandalart_cell_type.dart';

/// 만다라트 그리드 생성기 (F5.5 MandalartMapper)
/// Goal, SubGoal, GoalTask를 9x9 MandalartGrid로 변환한다
/// 순수 함수로만 구성되어 외부 의존성이 없다
///
/// 만다라트 그리드 레이아웃 (9x9):
/// [T0][T1][T2] [T0][T1][T2] [T0][T1][T2]   <- 서브그리드 행 0 (row 0~2)
/// [T3][SG][T4] [T3][SG][T4] [T3][SG][T4]   <- 서브그리드 행 1 (row 3~5)  SG=세부목표
/// [T5][T6][T7] [T5][T6][T7] [T5][T6][T7]   <- 서브그리드 행 2 (row 6~8)
/// 중앙(row4, col4)이 핵심 목표, 나머지 3x3 서브그리드 중앙이 8개 세부목표
abstract class MandalartMapper {
  /// 세부목표 8개의 행/열 위치 매핑 (orderIndex 0~7)
  /// 9x9 그리드 내 3x3 서브그리드 중앙 셀 위치
  static const List<({int row, int col})> _subGoalPositions = [
    (row: 1, col: 1), // 0: 왼쪽 위 서브그리드 중앙
    (row: 1, col: 4), // 1: 위쪽 중앙 서브그리드 중앙
    (row: 1, col: 7), // 2: 오른쪽 위 서브그리드 중앙
    (row: 4, col: 1), // 3: 왼쪽 중앙 서브그리드 중앙
    (row: 4, col: 7), // 4: 오른쪽 중앙 서브그리드 중앙
    (row: 7, col: 1), // 5: 왼쪽 아래 서브그리드 중앙
    (row: 7, col: 4), // 6: 아래쪽 중앙 서브그리드 중앙
    (row: 7, col: 7), // 7: 오른쪽 아래 서브그리드 중앙
  ];

  /// 각 세부목표 서브그리드의 실천과제 상대적 오프셋 (orderIndex 0~7)
  /// 서브그리드 중앙(세부목표) 제외한 8개 위치
  static const List<({int dr, int dc})> _taskOffsets = [
    (dr: -1, dc: -1), // 0: 왼쪽 위
    (dr: -1, dc: 0),  // 1: 위
    (dr: -1, dc: 1),  // 2: 오른쪽 위
    (dr: 0, dc: -1),  // 3: 왼쪽
    (dr: 0, dc: 1),   // 4: 오른쪽
    (dr: 1, dc: -1),  // 5: 왼쪽 아래
    (dr: 1, dc: 0),   // 6: 아래
    (dr: 1, dc: 1),   // 7: 오른쪽 아래
  ];

  /// Goal + SubGoal 목록 + 전체 GoalTask 목록에서 MandalartGrid를 생성한다
  static MandalartGrid map({
    required Goal goal,
    required List<SubGoal> subGoals,
    required List<GoalTask> tasks,
  }) {
    // 81개 셀 초기화 (모두 빈 셀)
    final cells = List.generate(GoalLayout.mandalartGridSize, (row) {
      return List.generate(GoalLayout.mandalartGridSize, (col) {
        return MandalartCell(
          row: row,
          col: col,
          text: '',
          type: MandalartCellType.empty,
          isCompleted: false,
          entityId: null,
        );
      });
    });

    // 핵심 목표 셀 설정 (중앙: mandalartCenterIndex)
    final center = GoalLayout.mandalartCenterIndex;
    cells[center][center] = MandalartCell(
      row: center,
      col: center,
      text: goal.title,
      type: MandalartCellType.core,
      isCompleted: goal.isCompleted,
      entityId: goal.id,
    );

    // 세부목표 셀 설정 (8개)
    for (final subGoal in subGoals) {
      final idx = subGoal.orderIndex.clamp(0, GoalLayout.mandalartSubGoalCount - 1);
      final pos = _subGoalPositions[idx];

      cells[pos.row][pos.col] = MandalartCell(
        row: pos.row,
        col: pos.col,
        text: subGoal.title,
        type: MandalartCellType.subGoal,
        isCompleted: subGoal.isCompleted,
        entityId: subGoal.id,
      );

      // 해당 세부목표의 실천과제 셀 설정
      final subGoalTasks = tasks
          .where((t) => t.subGoalId == subGoal.id)
          .toList();

      for (final task in subGoalTasks) {
        final taskIdx = task.orderIndex.clamp(0, GoalLayout.mandalartSubGoalCount - 1);
        final offset = _taskOffsets[taskIdx];
        final taskRow = pos.row + offset.dr;
        final taskCol = pos.col + offset.dc;

        // 범위 내 셀에만 배치
        if (taskRow >= 0 && taskRow < GoalLayout.mandalartGridSize && taskCol >= 0 && taskCol < GoalLayout.mandalartGridSize) {
          cells[taskRow][taskCol] = MandalartCell(
            row: taskRow,
            col: taskCol,
            text: task.title,
            type: MandalartCellType.task,
            isCompleted: task.isCompleted,
            entityId: task.id,
          );
        }
      }
    }

    // 2D 배열을 1D List로 변환
    final flatCells = cells.expand((row) => row).toList();

    return MandalartGrid(
      coreGoalTitle: goal.title,
      goalId: goal.id,
      cells: flatCells,
    );
  }
}
