// F8: 업적 그리드 위젯
// AchievementDef.all 전체 업적을 2열 그리드로 표시한다.
// 달성 업적이 상단에, 미달성 업적이 하단에 정렬된다.
import 'package:flutter/material.dart';

import '../../models/achievement_definition.dart';
import 'achievement_card.dart';

/// 업적 전체 목록을 2열 그리드로 표시하는 위젯
/// 달성된 업적이 상단에 먼저 표시된다
/// shrinkWrap 대신 부모 CustomScrollView의 SliverToBoxAdapter 안에서 사용하므로
/// GridView.builder에 NeverScrollableScrollPhysics + shrinkWrap을 유지한다.
/// 대안으로 SliverGrid를 직접 반환하려면 부모 구조 변경이 필요하다.
class AchievementGrid extends StatelessWidget {
  /// 달성된 업적 ID 집합
  final Set<String> unlockedIds;

  const AchievementGrid({
    super.key,
    required this.unlockedIds,
  });

  /// 정렬된 업적 정의 목록을 반환한다 (달성 업적 우선)
  List<AchievementDef> _sortedDefs() {
    return [...AchievementDef.all]
      ..sort((a, b) {
        final aUnlocked = unlockedIds.contains(a.id) ? 0 : 1;
        final bUnlocked = unlockedIds.contains(b.id) ? 0 : 1;
        return aUnlocked.compareTo(bUnlocked);
      });
  }

  @override
  Widget build(BuildContext context) {
    final sortedDefs = _sortedDefs();

    return GridView.builder(
      // 부모 Scroll을 사용하므로 shrinkWrap + NeverScrollableScrollPhysics 설정
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDefs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.90,
      ),
      itemBuilder: (context, index) {
        final def = sortedDefs[index];
        final isUnlocked = unlockedIds.contains(def.id);

        return RepaintBoundary(
          child: AchievementCard(
            key: ValueKey(def.id),
            def: def,
            isUnlocked: isUnlocked,
          ),
        );
      },
    );
  }
}
