// SegmentedControl 위젯 테스트
// 탭 렌더링, 선택 상태, onChanged 콜백을 검증한다.
// context.themeColors를 사용하므로 ProviderScope + 테마 Provider override가 필수다.
import 'package:design_your_life/core/cache/hive_cache_service.dart';
import 'package:design_your_life/core/providers/global_providers.dart';
import 'package:design_your_life/core/theme/theme_preset.dart';
import 'package:design_your_life/core/theme/theme_preset_registry.dart';
import 'package:design_your_life/shared/widgets/segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 테스트용 탭 열거형
enum TestTab { a, b, c }

/// HiveCacheService Mock: Hive 박스 초기화 없이 테스트를 수행하기 위한 목 구현체
class _MockHiveCacheService extends HiveCacheService {
  @override
  Future<void> saveSetting(String key, Object value) async {}

  @override
  T? readSetting<T>(String key) => null;
}

void main() {
  /// ProviderScope로 감싼 테스트 위젯 빌더
  Widget buildTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        hiveCacheServiceProvider.overrideWithValue(_MockHiveCacheService()),
        isDarkModeProvider.overrideWith((ref) => false),
        themePresetProvider.overrideWith((ref) => ThemePreset.refinedGlass),
        themePresetDataProvider.overrideWith(
          (ref) => ThemePresetRegistry.dataFor(ThemePreset.refinedGlass),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('3개 탭을 렌더링한다', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        SegmentedControl<TestTab>(
          values: TestTab.values,
          selected: TestTab.a,
          labelBuilder: (t) => t.name.toUpperCase(),
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('탭 클릭 시 onChanged가 호출된다', (tester) async {
    TestTab? tapped;
    await tester.pumpWidget(
      buildTestWidget(
        SegmentedControl<TestTab>(
          values: TestTab.values,
          selected: TestTab.a,
          labelBuilder: (t) => t.name.toUpperCase(),
          onChanged: (t) => tapped = t,
        ),
      ),
    );
    await tester.tap(find.text('B'));
    expect(tapped, TestTab.b);
  });
}
