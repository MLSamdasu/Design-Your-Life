// C0.NLP: 자연어 파싱 결과 데이터 클래스
// NlpTodoParser의 OUT으로 UI에서 미리보기 표시에 사용한다.
// 날짜/시간이 파싱되지 않으면 null을 반환한다.
import 'package:flutter/material.dart';

/// 자연어 파싱 결과
/// NlpTodoParser.parse()의 반환값이다
class ParsedTodo {
  /// 추출된 투두 제목 (날짜/시간 표현을 제거한 나머지 텍스트)
  final String title;

  /// 파싱된 날짜 (null이면 날짜 표현 미감지)
  final DateTime? date;

  /// 파싱된 시간 (null이면 시간 표현 미감지)
  final TimeOfDay? time;

  /// 원본 입력 텍스트 (디버깅/표시용)
  final String originalText;

  /// 파싱 성공 여부 (제목이 비어있지 않으면 성공)
  bool get isValid => title.trim().isNotEmpty;

  /// 날짜가 파싱되었는지 여부
  bool get hasDate => date != null;

  /// 시간이 파싱되었는지 여부
  bool get hasTime => time != null;

  /// 날짜와 시간 모두 파싱되지 않았고 제목도 없으면 비어있다고 간주한다
  bool get isEmpty => title.trim().isEmpty && !hasDate && !hasTime;

  const ParsedTodo({
    required this.title,
    this.date,
    this.time,
    required this.originalText,
  });
}
