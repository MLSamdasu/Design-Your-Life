// 데일리 리추얼: 화면 상태 관리 헬퍼
// DailyRitualScreen에서 사용하는 로컬 상태(컨트롤러, 선택 인덱스 등)를 분리한다.
// 위젯 트리와 독립적인 순수 상태 클래스이다.

import 'package:flutter/material.dart';

/// 리추얼 화면의 로컬 상태를 보유한다
/// PageController, TextEditingController 25+3개, 선택 Set을 관리한다
class RitualStateHolder {
  /// 전체 페이지 수 (인트로 + 목표5p + top5 + rule3 + daily3 + 완료)
  static const int totalPages = 10;

  /// 25개 목표 텍스트 컨트롤러
  final List<TextEditingController> goalControllers;

  /// 3개 오늘의 할 일 텍스트 컨트롤러
  final List<TextEditingController> dailyThreeControllers;

  /// Top 5 선택된 목표 인덱스
  final Set<int> selectedTop5 = {};

  /// 기존 저장된 목표가 로드되었는지 여부 (재방문 사용자 판별)
  bool hasExistingGoals = false;

  /// 25개 목표 텍스트 리스트 (컨트롤러에서 추출)
  List<String> get goals =>
      goalControllers.map((c) => c.text).toList();

  /// 선택된 Top 5 목표 수
  int get selectedCount => selectedTop5.length;

  /// 입력된 오늘의 할 일 수 (빈 값 제외)
  int get dailyThreeCount =>
      dailyThreeControllers.where((c) => c.text.trim().isNotEmpty).length;

  RitualStateHolder()
      : goalControllers = List.generate(
            25, (_) => TextEditingController()),
        dailyThreeControllers = List.generate(
            3, (_) => TextEditingController());

  /// 기존 목표 데이터로 텍스트 필드를 초기화한다
  /// 비어있지 않은 목표가 하나라도 있으면 재방문 사용자로 간주한다
  void prefillGoals(List<String> existingGoals) {
    for (var i = 0; i < existingGoals.length && i < 25; i++) {
      goalControllers[i].text = existingGoals[i];
    }
    // 하나라도 입력된 목표가 있으면 재방문 사용자 플래그 설정
    hasExistingGoals =
        existingGoals.any((g) => g.trim().isNotEmpty);
  }

  /// 기존 Top 5 인덱스로 선택 상태를 초기화한다
  void prefillTop5(List<int> indices) {
    selectedTop5.addAll(indices.take(5));
  }

  /// 기존 오늘의 할 일로 텍스트 필드를 초기화한다
  void prefillDailyThree(List<String> tasks) {
    for (var i = 0; i < tasks.length && i < 3; i++) {
      dailyThreeControllers[i].text = tasks[i];
    }
  }

  /// Top 5 선택을 모두 초기화한다
  void resetTop5() {
    selectedTop5.clear();
  }

  /// Top 5 선택/해제를 토글한다
  /// 이미 5개 선택된 상태에서 새 항목 추가는 무시한다
  bool toggleTop5(int index) {
    if (selectedTop5.contains(index)) {
      selectedTop5.remove(index);
      return true;
    }
    if (selectedTop5.length >= 5) return false;
    selectedTop5.add(index);
    return true;
  }

  /// 특정 페이지 그룹(0~4)에 해당하는 5개 컨트롤러를 반환한다
  List<TextEditingController> controllersForPage(int pageIndex) {
    final start = pageIndex * 5;
    return goalControllers.sublist(start, start + 5);
  }

  /// 모든 컨트롤러를 해제한다
  void dispose() {
    for (final c in goalControllers) {
      c.dispose();
    }
    for (final c in dailyThreeControllers) {
      c.dispose();
    }
  }
}
