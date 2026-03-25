// F-Ritual: 리추얼 TOP 5 → Goal 연동 Provider
// TOP 5로 선택된 목표 텍스트가 기존 Goal과 일치하는지 확인한다.
// 일치하지 않는 항목은 UI에서 "목표 생성" 옵션을 제공할 수 있도록
// 미연결 목표 목록을 반환한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../shared/models/goal.dart';
import '../models/daily_ritual.dart';

/// TOP 5 중 기존 Goal과 제목이 일치하지 않는 목표 텍스트 목록
/// UI에서 "이 목표를 생성하시겠습니까?" 프롬프트에 사용한다
final unmatchedTop5GoalsProvider = Provider.family<List<String>,
    DailyRitual?>((ref, ritual) {
  if (ritual == null) return [];

  final allGoalsRaw = ref.watch(allGoalsRawProvider);
  // 기존 Goal의 제목 집합 (소문자로 정규화하여 비교)
  final existingTitles = allGoalsRaw
      .map((m) => (m['title'] as String?)?.toLowerCase().trim() ?? '')
      .where((t) => t.isNotEmpty)
      .toSet();

  // TOP 5 인덱스에 해당하는 목표 텍스트 중 기존 Goal과 매칭되지 않는 것만 반환
  final unmatched = <String>[];
  for (final idx in ritual.top5Indices) {
    if (idx < 0 || idx >= ritual.goals.length) continue;
    final goalText = ritual.goals[idx].trim();
    if (goalText.isEmpty) continue;
    if (!existingTitles.contains(goalText.toLowerCase())) {
      unmatched.add(goalText);
    }
  }
  return unmatched;
});

/// TOP 5 중 기존 Goal과 제목이 일치하는 Goal 객체 목록
/// UI에서 연결된 목표의 진행률 표시 등에 사용한다
final matchedTop5GoalsProvider = Provider.family<List<Goal>,
    DailyRitual?>((ref, ritual) {
  if (ritual == null) return [];

  final allGoalsRaw = ref.watch(allGoalsRawProvider);
  final allGoals = allGoalsRaw.map((m) => Goal.fromMap(m)).toList();

  // 제목 → Goal 매핑 (소문자 정규화)
  final titleMap = <String, Goal>{};
  for (final goal in allGoals) {
    titleMap[goal.title.toLowerCase().trim()] = goal;
  }

  // TOP 5 인덱스의 목표 텍스트와 매칭되는 Goal 반환
  final matched = <Goal>[];
  for (final idx in ritual.top5Indices) {
    if (idx < 0 || idx >= ritual.goals.length) continue;
    final goalText = ritual.goals[idx].trim().toLowerCase();
    if (goalText.isEmpty) continue;
    final goal = titleMap[goalText];
    if (goal != null) matched.add(goal);
  }
  return matched;
});
