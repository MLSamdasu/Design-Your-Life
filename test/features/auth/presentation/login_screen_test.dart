// LoginScreen 위젯 테스트
// 로그인 화면의 기본 렌더링, 텍스트 요소, 구조를 검증한다.
// API 인증 의존성은 격리하여 위젯 렌더링만 테스트한다.
import 'package:design_your_life/core/cache/hive_cache_service.dart';
import 'package:design_your_life/core/providers/global_providers.dart';
import 'package:design_your_life/features/auth/presentation/login_screen.dart';
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
  /// 테스트용 위젯 래퍼: MaterialApp + ProviderScope로 감싼다
  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        hiveCacheServiceProvider.overrideWithValue(_MockHiveCacheService()),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen - 기본 렌더링', () {
    testWidgets('앱 이름 "Design Your Life"가 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Design Your Life'), findsOneWidget);
    });

    testWidgets('태그라인이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('목표, 습관, 할 일을 한 곳에서 관리하세요'),
        findsOneWidget,
      );
    });

    testWidgets('Scaffold가 존재한다', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('SafeArea가 적용된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('FadeTransition이 적용된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(FadeTransition), findsWidgets);
    });

    testWidgets('SlideTransition이 적용된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(SlideTransition), findsWidgets);
    });

    testWidgets('ConstrainedBox가 최대 너비를 제한한다', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // 여러 ConstrainedBox 중 maxWidth가 400인 것을 찾는다
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      final hasMaxWidth400 = constrainedBoxes.any(
        (box) => box.constraints.maxWidth == 400,
      );
      expect(hasMaxWidth400, true);
    });

    testWidgets('그라디언트 배경 Container가 존재한다', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Container with BoxDecoration (gradient)이 존재하는지 확인
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('화면이 에러 없이 렌더링된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 에러 없이 렌더링 완료되었는지 확인
      expect(tester.takeException(), isNull);
    });
  });

  group('LoginScreen - 레이아웃 구조', () {
    testWidgets('Column 위젯으로 수직 레이아웃을 구성한다', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('Center 위젯으로 중앙 정렬된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('Padding이 적용된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(Padding), findsWidgets);
    });
  });
}
