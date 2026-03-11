// EmptyState 위젯 테스트
// 메인 텍스트, 서브 텍스트, CTA 버튼 렌더링을 검증한다.
// EmptyState가 context.themeColors를 사용하므로 ProviderScope 래핑이 필수다.
import 'package:design_your_life/core/cache/hive_cache_service.dart';
import 'package:design_your_life/core/providers/global_providers.dart';
import 'package:design_your_life/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hive 의존성 없이 테스트를 위한 MockHiveCacheService
class _MockHiveCacheService extends HiveCacheService {
  @override
  Future<void> saveSetting(String key, Object value) async {}

  @override
  T? readSetting<T>(String key) => null;
}

void main() {
  // GoogleFonts 설정은 test/flutter_test_config.dart에서 전역 처리

  group('EmptyState 위젯', () {
    Widget buildTestWidget(EmptyState widget) {
      return ProviderScope(
        overrides: [
          hiveCacheServiceProvider.overrideWithValue(_MockHiveCacheService()),
        ],
        child: MaterialApp(
          home: Scaffold(body: widget),
        ),
      );
    }

    testWidgets('메인 텍스트를 표시한다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const EmptyState(
          icon: Icons.inbox,
          mainText: '아직 항목이 없습니다',
        ),
      ));
      await tester.pump();
      expect(find.text('아직 항목이 없습니다'), findsOneWidget);
    });

    testWidgets('아이콘이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const EmptyState(
          icon: Icons.inbox,
          mainText: '테스트',
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('서브 텍스트가 설정되면 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const EmptyState(
          icon: Icons.inbox,
          mainText: '메인 텍스트',
          subText: '서브 텍스트입니다',
        ),
      ));
      await tester.pump();
      expect(find.text('서브 텍스트입니다'), findsOneWidget);
    });

    testWidgets('서브 텍스트가 없으면 표시하지 않는다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const EmptyState(
          icon: Icons.inbox,
          mainText: '메인만',
        ),
      ));
      await tester.pump();
      // 서브 텍스트 위젯이 없어야 함
      final texts = tester.widgetList<Text>(find.byType(Text));
      // 메인 텍스트만 존재
      expect(texts.where((t) => t.data == '메인만').length, 1);
    });

    testWidgets('CTA 버튼이 설정되면 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        EmptyState(
          icon: Icons.add,
          mainText: '항목이 없습니다',
          ctaLabel: '추가하기',
          onCtaTap: () {},
        ),
      ));
      await tester.pump();
      expect(find.text('추가하기'), findsOneWidget);
    });

    testWidgets('CTA 버튼 탭 시 콜백이 실행된다', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildTestWidget(
        EmptyState(
          icon: Icons.add,
          mainText: '항목이 없습니다',
          ctaLabel: '추가하기',
          onCtaTap: () => tapped = true,
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('추가하기'));
      expect(tapped, true);
    });

    testWidgets('CTA 미설정 시 버튼이 표시되지 않는다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const EmptyState(
          icon: Icons.inbox,
          mainText: 'CTA 없음',
        ),
      ));
      await tester.pump();
      // CTA 버튼의 GestureDetector가 없어야 함
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('minHeight가 적용된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const EmptyState(
          icon: Icons.inbox,
          mainText: '높이 테스트',
          minHeight: 200,
        ),
      ));
      await tester.pump();
      // Container가 minHeight 제약을 가짐
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(container.constraints?.minHeight, 200);
    });
  });
}
