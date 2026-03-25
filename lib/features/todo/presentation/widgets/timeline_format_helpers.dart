// 타임라인 포맷팅 헬퍼 함수
// TimeOfDay 포맷, 소요시간 계산, 유형 판별 등 공통 유틸리티
import 'package:flutter/material.dart';
import '../../../../shared/models/todo.dart';

/// TimeOfDay를 "HH:MM" 형식으로 변환한다
String? formatTimeOfDay(TimeOfDay? time) {
  if (time == null) return null;
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// 시작~종료 시간의 소요시간을 한글 문자열로 반환한다
/// 예: "1시간 30분", "45분"
String? formatDuration(TimeOfDay? start, TimeOfDay? end) {
  if (start == null || end == null) return null;
  final startMinutes = start.hour * 60 + start.minute;
  final endMinutes = end.hour * 60 + end.minute;
  final diff = endMinutes - startMinutes;
  if (diff <= 0) return null;
  final hours = diff ~/ 60;
  final minutes = diff % 60;
  if (hours > 0 && minutes > 0) return '$hours시간 $minutes분';
  if (hours > 0) return '$hours시간';
  return '$minutes분';
}

/// 투두의 유형 라벨을 반환한다 (투두/캘린더/루틴/타이머)
String getTypeLabel(Todo todo) {
  if (todo.id.startsWith('cal_')) return '캘린더';
  if (todo.id.startsWith('routine_')) return '루틴';
  if (todo.id.startsWith('timer_')) return '타이머';
  return '투두';
}

/// 항목 유형에 따른 아이콘을 반환한다 (일반 투두는 null)
IconData? getTypeIcon(Todo todo) {
  if (todo.id.startsWith('cal_')) return Icons.event_rounded;
  if (todo.id.startsWith('routine_')) return Icons.repeat_rounded;
  if (todo.id.startsWith('timer_')) return Icons.timer_rounded;
  return null;
}
