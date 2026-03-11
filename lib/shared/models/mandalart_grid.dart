// 만다라트 그리드 뷰 모델
// 서버에 직접 저장하지 않는 뷰 전용 모델이다
// MandalartMapper가 Goal + SubGoal + GoalTask로부터 이 모델을 생성한다
import '../enums/mandalart_cell_type.dart';

/// 만다라트 전체 그리드 (뷰 전용)
/// 9x9 = 81개 셀로 구성되며 서버에는 저장하지 않는다
/// MandalartMapper.map()으로 생성한다
class MandalartGrid {
  /// 핵심 목표 제목 (9x9 그리드 정중앙에 표시)
  final String coreGoalTitle;

  /// 목표 ID (연결된 Goal 식별용)
  final String goalId;

  /// 81개 셀 데이터 (9x9, row/col 순서)
  final List<MandalartCell> cells;

  const MandalartGrid({
    required this.coreGoalTitle,
    required this.goalId,
    required this.cells,
  });

  /// JSON에서 MandalartGrid 생성 (뷰 상태 복원용)
  factory MandalartGrid.fromJson(Map<String, dynamic> json) {
    return MandalartGrid(
      coreGoalTitle: json['coreGoalTitle'] as String,
      goalId: json['goalId'] as String,
      cells: (json['cells'] as List)
          .map((e) => MandalartCell.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// JSON 직렬화 (뷰 상태 저장용)
  Map<String, dynamic> toJson() {
    return {
      'coreGoalTitle': coreGoalTitle,
      'goalId': goalId,
      'cells': cells.map((c) => c.toJson()).toList(),
    };
  }
}

/// 만다라트 개별 셀 (뷰 전용)
/// 9x9 그리드의 한 칸을 표현한다
class MandalartCell {
  /// 행 인덱스 (0~8)
  final int row;

  /// 열 인덱스 (0~8)
  final int col;

  /// 셀에 표시할 텍스트 (빈 셀은 빈 문자열)
  final String text;

  /// 셀 유형 (핵심 목표/세부 목표/실천 과제/빈 셀)
  final MandalartCellType type;

  /// 완료 여부 (실천 과제 체크박스 상태)
  final bool isCompleted;

  /// 연결된 엔티티 ID (SubGoal 또는 GoalTask ID, 빈 셀은 null)
  final String? entityId;

  const MandalartCell({
    required this.row,
    required this.col,
    this.text = '',
    required this.type,
    this.isCompleted = false,
    this.entityId,
  });

  /// JSON에서 MandalartCell 생성
  factory MandalartCell.fromJson(Map<String, dynamic> json) {
    return MandalartCell(
      row: json['row'] as int,
      col: json['col'] as int,
      text: json['text'] as String? ?? '',
      type: MandalartCellType.values.firstWhere(
        (e) => e.name == (json['type'] as String),
        orElse: () => MandalartCellType.empty,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      entityId: json['entityId'] as String?,
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
      'text': text,
      'type': type.name,
      'isCompleted': isCompleted,
      'entityId': entityId,
    };
  }

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  MandalartCell copyWith({
    int? row,
    int? col,
    String? text,
    MandalartCellType? type,
    bool? isCompleted,
    String? entityId,
  }) {
    return MandalartCell(
      row: row ?? this.row,
      col: col ?? this.col,
      text: text ?? this.text,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      entityId: entityId ?? this.entityId,
    );
  }
}
