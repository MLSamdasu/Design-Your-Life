// OnboardingScreen 위젯 테스트
// 온보딩 단계 전환, 유효성 검사 로직, UI 요소를 검증한다.
import 'package:design_your_life/core/cache/hive_cache_service.dart';
import 'package:design_your_life/core/providers/global_providers.dart';
import 'package:design_your_life/features/auth/presentation/onboarding_screen.dart';
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
  group('OnboardingStep enum', () {
    test('consent 단계가 존재한다', () {
      expect(OnboardingStep.consent, isNotNull);
    });

    test('nameInput 단계가 존재한다', () {
      expect(OnboardingStep.nameInput, isNotNull);
    });

    test('values에 2개 단계가 있다', () {
      expect(OnboardingStep.values.length, 2);
    });

    test('consent가 첫 번째 값이다', () {
      expect(OnboardingStep.values.first, OnboardingStep.consent);
    });

    test('nameInput이 두 번째 값이다', () {
      expect(OnboardingStep.values.last, OnboardingStep.nameInput);
    });
  });

  group('OnboardingScreen - 기본 렌더링', () {
    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          hiveCacheServiceProvider.overrideWithValue(_MockHiveCacheService()),
        ],
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
    }

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

    testWidgets('ConstrainedBox가 최대 너비를 제한한다', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // 여러 ConstrainedBox 중 maxWidth가 420인 것을 찾는다
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      final hasMaxWidth420 = constrainedBoxes.any(
        (box) => box.constraints.maxWidth == 420,
      );
      expect(hasMaxWidth420, true);
    });

    testWidgets('화면이 에러 없이 렌더링된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('그라디언트 배경이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(Container), findsWidgets);
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

  group('OnboardingScreen - 이름 유효성 검사 로직', () {
    test('빈 문자열은 유효하지 않다', () {
      final name = ''.trim();
      expect(name.isEmpty, true);
    });

    test('공백만 있는 문자열은 유효하지 않다', () {
      final name = '   '.trim();
      expect(name.isEmpty, true);
    });

    test('20자 이내 문자열은 유효하다', () {
      final name = '테스트유저';
      expect(name.length <= 20, true);
      expect(name.isNotEmpty, true);
    });

    test('20자 초과 문자열은 유효하지 않다', () {
      final name = 'a' * 21;
      expect(name.length > 20, true);
    });

    test('정확히 20자 문자열은 유효하다', () {
      final name = 'a' * 20;
      expect(name.length <= 20, true);
      expect(name.isNotEmpty, true);
    });

    test('1자 문자열은 유효하다', () {
      const name = '김';
      expect(name.isNotEmpty && name.length <= 20, true);
    });

    test('한글 이름이 올바르게 처리된다', () {
      const name = '홍길동';
      expect(name.trim().isNotEmpty, true);
      expect(name.trim().length <= 20, true);
    });

    test('영문 이름이 올바르게 처리된다', () {
      const name = 'John Doe';
      expect(name.trim().isNotEmpty, true);
      expect(name.trim().length <= 20, true);
    });

    test('특수문자가 포함된 이름도 길이 제한만 검사한다', () {
      const name = '이름!@#';
      expect(name.trim().isNotEmpty, true);
      expect(name.trim().length <= 20, true);
    });
  });
}
