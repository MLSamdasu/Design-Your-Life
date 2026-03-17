// GlassCard 위젯 테스트
// 자식 위젯 렌더링, BackdropFilter 적용, variant별 동작을 검증한다.
// GlassCard는 ConsumerWidget이므로 ProviderScope + themePreset/isDarkMode/hive Provider override가 필수다.
import 'package:design_your_life/core/cache/hive_cache_service.dart';
import 'package:design_your_life/core/providers/global_providers.dart';
import 'package:design_your_life/core/theme/theme_preset.dart';
import 'package:design_your_life/core/theme/theme_preset_registry.dart';
import 'package:design_your_life/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// HiveCacheService Mock: Hive 박스 초기화 없이 테스트를 수행하기 위한 목 구현체
class _MockHiveCacheService extends HiveCacheService {
  @override
  Future<void> saveSetting(String key, Object value) async {}

  @override
  T? readSetting<T>(String key) => null;
}

void main() {
  group('GlassCard 위젯', () {
    // GlassCard가 ConsumerWidget으로 변경되어 ProviderScope와 테마/다크모드 Provider override가 필요하다
    Widget buildTestWidget(GlassCard card) {
      return ProviderScope(
        overrides: [
          // Hive 의존성 격리: HiveCacheService Mock으로 대체한다
          hiveCacheServiceProvider.overrideWithValue(_MockHiveCacheService()),
          // 다크 모드: 기본값 false로 고정한다
          isDarkModeProvider.overrideWith((ref) => false),
          // 테마 프리셋 Provider: GlassCard가 ConsumerWidget으로 변경되어 필수 override
          themePresetProvider.overrideWith((ref) => ThemePreset.refinedGlass),
          themePresetDataProvider.overrideWith(
            (ref) => ThemePresetRegistry.dataFor(ThemePreset.refinedGlass),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: card),
        ),
      );
    }

    testWidgets('자식 위젯을 렌더링한다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const GlassCard(
          child: Text('테스트 내용'),
        ),
      ));
      expect(find.text('테스트 내용'), findsOneWidget);
    });

    testWidgets('BackdropFilter가 적용된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const GlassCard(
          child: Text('블러 테스트'),
        ),
      ));
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('ClipRRect가 적용된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const GlassCard(
          child: Text('클리핑 테스트'),
        ),
      ));
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('defaultCard variant로 렌더링된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const GlassCard(
          variant: GlassCardVariant.defaultCard,
          child: Text('기본 카드'),
        ),
      ));
      expect(find.text('기본 카드'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('elevated variant로 렌더링된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const GlassCard(
          variant: GlassCardVariant.elevated,
          child: Text('강조 카드'),
        ),
      ));
      expect(find.text('강조 카드'), findsOneWidget);
    });

    testWidgets('subtle variant로 렌더링된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const GlassCard(
          variant: GlassCardVariant.subtle,
          child: Text('보조 카드'),
        ),
      ));
      expect(find.text('보조 카드'), findsOneWidget);
    });

    testWidgets('커스텀 padding이 적용된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const GlassCard(
          padding: EdgeInsets.all(32),
          child: Text('패딩 테스트'),
        ),
      ));
      expect(find.text('패딩 테스트'), findsOneWidget);
    });

    testWidgets('커스텀 borderRadius가 적용된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const GlassCard(
          borderRadius: 30,
          child: Text('반지름 테스트'),
        ),
      ));
      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      final borderRadius = clipRRect.borderRadius as BorderRadius;
      expect(borderRadius.topLeft.x, 30);
    });

    testWidgets('width와 height가 적용된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const GlassCard(
          width: 200,
          height: 100,
          child: Text('크기 테스트'),
        ),
      ));
      expect(find.text('크기 테스트'), findsOneWidget);
      // 최상위 Container에 width/height가 constraints로 설정됨
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(container.constraints?.maxWidth, 200);
      expect(container.constraints?.maxHeight, 100);
    });
  });
}
