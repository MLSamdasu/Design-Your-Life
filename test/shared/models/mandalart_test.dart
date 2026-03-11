// MandalartGrid/MandalartCell 모델 단위 테스트
// fromJson/toJson 왕복 변환, 셀 타입, copyWith를 검증한다.
import 'package:design_your_life/shared/enums/mandalart_cell_type.dart';
import 'package:design_your_life/shared/models/mandalart_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MandalartCell', () {
    late MandalartCell cell;

    setUp(() {
      cell = const MandalartCell(
        row: 4,
        col: 4,
        text: '핵심 목표',
        type: MandalartCellType.core,
        isCompleted: false,
        entityId: 'goal-1',
      );
    });

    test('기본값이 올바르게 설정된다', () {
      const emptyCell = MandalartCell(
        row: 0,
        col: 0,
        type: MandalartCellType.empty,
      );
      expect(emptyCell.text, '');
      expect(emptyCell.isCompleted, false);
      expect(emptyCell.entityId, isNull);
    });

    test('toJson이 올바른 Map을 반환한다', () {
      final json = cell.toJson();
      expect(json['row'], 4);
      expect(json['col'], 4);
      expect(json['text'], '핵심 목표');
      expect(json['type'], 'core');
      expect(json['isCompleted'], false);
      expect(json['entityId'], 'goal-1');
    });

    test('fromJson이 올바른 MandalartCell을 생성한다', () {
      final json = <String, dynamic>{
        'row': 4,
        'col': 4,
        'text': '핵심 목표',
        'type': 'core',
        'isCompleted': false,
        'entityId': 'goal-1',
      };
      final parsed = MandalartCell.fromJson(json);
      expect(parsed.row, 4);
      expect(parsed.col, 4);
      expect(parsed.text, '핵심 목표');
      expect(parsed.type, MandalartCellType.core);
      expect(parsed.entityId, 'goal-1');
    });

    test('fromJson/toJson 왕복 변환이 데이터를 보존한다', () {
      final json = cell.toJson();
      final restored = MandalartCell.fromJson(json);
      expect(restored.row, cell.row);
      expect(restored.col, cell.col);
      expect(restored.text, cell.text);
      expect(restored.type, cell.type);
      expect(restored.isCompleted, cell.isCompleted);
      expect(restored.entityId, cell.entityId);
    });

    test('잘못된 type 값이면 empty를 기본값으로 사용한다', () {
      final json = <String, dynamic>{
        'row': 0,
        'col': 0,
        'type': 'invalid',
      };
      final parsed = MandalartCell.fromJson(json);
      expect(parsed.type, MandalartCellType.empty);
    });

    test('copyWith가 지정 필드만 변경한 새 인스턴스를 반환한다', () {
      final updated = cell.copyWith(
        text: '변경된 목표',
        isCompleted: true,
      );
      expect(updated.text, '변경된 목표');
      expect(updated.isCompleted, true);
      expect(updated.row, cell.row);
      expect(updated.col, cell.col);
      expect(updated.type, cell.type);
    });
  });

  group('MandalartGrid', () {
    late MandalartGrid grid;

    setUp(() {
      final cells = List.generate(
        81,
        (i) => MandalartCell(
          row: i ~/ 9,
          col: i % 9,
          text: i == 40 ? '핵심 목표' : '셀 $i',
          type: i == 40
              ? MandalartCellType.core
              : MandalartCellType.task,
        ),
      );
      grid = MandalartGrid(
        coreGoalTitle: '핵심 목표',
        goalId: 'goal-1',
        cells: cells,
      );
    });

    test('그리드가 81개 셀을 포함한다', () {
      expect(grid.cells.length, 81);
    });

    test('toJson이 올바른 구조를 반환한다', () {
      final json = grid.toJson();
      expect(json['coreGoalTitle'], '핵심 목표');
      expect(json['goalId'], 'goal-1');
      expect((json['cells'] as List).length, 81);
    });

    test('fromJson/toJson 왕복 변환이 데이터를 보존한다', () {
      final json = grid.toJson();
      final restored = MandalartGrid.fromJson(json);
      expect(restored.coreGoalTitle, grid.coreGoalTitle);
      expect(restored.goalId, grid.goalId);
      expect(restored.cells.length, grid.cells.length);
      // 중앙 셀 (4,4) 검증
      final center = restored.cells[40];
      expect(center.text, '핵심 목표');
      expect(center.type, MandalartCellType.core);
    });

    test('셀 타입이 올바르게 구분된다', () {
      expect(MandalartCellType.values.length, 4);
      expect(MandalartCellType.core.name, 'core');
      expect(MandalartCellType.subGoal.name, 'subGoal');
      expect(MandalartCellType.task.name, 'task');
      expect(MandalartCellType.empty.name, 'empty');
    });
  });
}
