// F4 모델: RoutineCreateResult - 루틴 생성/수정 폼 결과 데이터 클래스
// 이름, 반복 요일, 시작/종료 시간, 색상 인덱스를 담는다.
import 'package:flutter/material.dart';

/// 루틴 생성 결과 데이터 클래스
class RoutineCreateResult {
  final String name;
  final List<int> repeatDays;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int colorIndex;

  const RoutineCreateResult({
    required this.name,
    required this.repeatDays,
    required this.startTime,
    required this.endTime,
    required this.colorIndex,
  });
}
