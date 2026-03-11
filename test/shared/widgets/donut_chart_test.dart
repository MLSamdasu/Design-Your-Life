// DonutChart 위젯 테스트
// 주어진 퍼센트로 렌더링, 퍼센트 텍스트 표시, mini 변형 텍스트 숨김을 검증한다.
// DonutChart가 context.themeColors를 사용하므로 ProviderScope 래핑이 필수다.
import 'package:design_your_life/core/cache/hive_cache_service.dart';
import 'package:design_your_life/core/providers/global_providers.dart';
import 'package:design_your_life/shared/widgets/donut_chart.dart';
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

  group('DonutChart 위젯', () {
    Widget buildTestWidget(DonutChart chart) {
      return ProviderScope(
        overrides: [
          hiveCacheServiceProvider.overrideWithValue(_MockHiveCacheService()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(child: chart),
          ),
        ),
      );
    }

    testWidgets('주어진 퍼센트로 렌더링된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const DonutChart(
          percentage: 75,
          size: DonutChartSize.medium,
        ),
      ));
      // 애니메이션 완료 대기
      await tester.pumpAndSettle();
      // SizedBox가 medium 크기(90px)로 렌더링
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 90);
      expect(sizedBox.height, 90);
    });

    testWidgets('퍼센트 텍스트를 표시한다 (medium 크기)', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const DonutChart(
          percentage: 50,
          size: DonutChartSize.medium,
        ),
      ));
      await tester.pumpAndSettle();
      // 50% 텍스트가 표시됨
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('large 크기에서 퍼센트 텍스트를 표시한다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const DonutChart(
          percentage: 80,
          size: DonutChartSize.large,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('mini 크기에서 중앙 텍스트를 숨긴다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const DonutChart(
          percentage: 60,
          size: DonutChartSize.mini,
        ),
      ));
      await tester.pumpAndSettle();
      // mini에서는 퍼센트 텍스트 미표시
      expect(find.text('60%'), findsNothing);
    });

    testWidgets('centerLabel이 설정되면 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const DonutChart(
          percentage: 70,
          size: DonutChartSize.medium,
          centerLabel: '완료율',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('완료율'), findsOneWidget);
    });

    testWidgets('0% 퍼센트가 정상 렌더링된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const DonutChart(
          percentage: 0,
          size: DonutChartSize.medium,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('100% 퍼센트가 정상 렌더링된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const DonutChart(
          percentage: 100,
          size: DonutChartSize.medium,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
    });
  });
}
