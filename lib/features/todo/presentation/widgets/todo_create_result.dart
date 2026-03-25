// F3 데이터: TodoCreateResult - 투두 생성 결과
// 투두 생성/수정 다이얼로그에서 반환되는 결과 데이터 클래스이다.
// todo_create_dialog.dart에서 분리된 데이터 모델이다.
import 'package:flutter/material.dart';

/// 투두 생성 결과 데이터 클래스
class TodoCreateResult {
  final String title;

  /// 예정 날짜 (P1-16: 다이얼로그에서 선택한 날짜)
  final DateTime? date;

  /// 시작 시간 (시간 지정 시)
  final TimeOfDay? startTime;

  /// 종료 시간 (시간 지정 시, null이면 기본 30분 지속)
  final TimeOfDay? endTime;

  final int colorIndex;
  final String? memo;

  /// 선택된 태그 ID 목록 (F16: 태그 시스템)
  final List<String> tagIds;

  /// 하위 호환: 기존 time 필드 접근을 startTime으로 위임한다
  TimeOfDay? get time => startTime;

  const TodoCreateResult({
    required this.title,
    this.date,
    this.startTime,
    this.endTime,
    required this.colorIndex,
    this.memo,
    this.tagIds = const [],
  });
}
