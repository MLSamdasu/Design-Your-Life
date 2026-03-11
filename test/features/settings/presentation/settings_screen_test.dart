// SettingsScreen 위젯 테스트
// 설정 화면의 렌더링, 계정 정보 표시, 다크 모드 토글, 로그아웃/삭제 버튼을 검증한다.
// API/Hive 의존성은 Provider override로 격리한다.
import 'package:design_your_life/core/auth/auth_service.dart';
import 'package:design_your_life/core/cache/hive_cache_service.dart';
import 'package:design_your_life/core/calendar_sync/calendar_sync_provider.dart';
import 'package:design_your_life/core/calendar_sync/google_calendar_service.dart';
import 'package:design_your_life/core/auth/auth_provider.dart';
import 'package:design_your_life/core/providers/global_providers.dart';
import 'package:design_your_life/core/theme/theme_preset.dart';
import 'package:design_your_life/core/theme/theme_preset_registry.dart';
import 'package:design_your_life/features/settings/presentation/settings_screen.dart';
import 'package:design_your_life/features/settings/presentation/settings_cards.dart';
import 'package:design_your_life/features/settings/presentation/settings_actions.dart';
import 'package:design_your_life/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// HiveCacheService Mock: Hive 의존성 없이 테스트를 수행하기 위한 목 구현체
class MockHiveCacheService extends HiveCacheService {
  final Map<String, Object> _settings = {};

  @override
  Future<void> saveSetting(String key, Object value) async {
    _settings[key] = value;
  }

  @override
  T? readSetting<T>(String key) {
    final value = _settings[key];
    if (value is T) return value;
    return null;
  }
}

void main() {
  late MockHiveCacheService mockHiveCache;

  setUp(() {
    mockHiveCache = MockHiveCacheService();
  });

  /// 인증된 사용자 상태의 테스트 위젯을 생성한다
  /// GlassCard가 ConsumerWidget으로 변경되어 themePreset 관련 Provider override가 필수다
  Widget buildTestWidget({
    String displayName = '테스트 유저',
    String email = 'test@test.com',
    bool isDark = false,
  }) {
    return ProviderScope(
      overrides: [
        currentAuthStateProvider.overrideWithValue(
          AuthState(
            userId: 'test-user',
            displayName: displayName,
            email: email,
          ),
        ),
        currentUserIdProvider.overrideWithValue('test-user'),
        isAuthenticatedProvider.overrideWithValue(true),
        isDarkModeProvider.overrideWith((ref) => isDark),
        hiveCacheServiceProvider.overrideWithValue(mockHiveCache),
        themePresetProvider.overrideWith((ref) => ThemePreset.glassmorphism),
        themePresetDataProvider.overrideWith(
          (ref) => ThemePresetRegistry.dataFor(ThemePreset.glassmorphism),
        ),
        // F17: Google Calendar 연동은 테스트에서 비활성화한다 (네트워크/Hive 의존성 격리)
        googleCalendarSyncEnabledProvider.overrideWith((ref) => false),
        calendarSyncStatusProvider.overrideWith(
          (ref) => CalendarSyncStatus.notConnected,
        ),
      ],
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  // ─── 기본 렌더링 테스트 ───────────────────────────────────────────────────
  group('SettingsScreen - 기본 렌더링', () {
    testWidgets('Scaffold가 존재한다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('"설정" 헤더 텍스트가 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('설정'), findsOneWidget);
    });

    testWidgets('닫기 버튼 아이콘이 존재한다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('SingleChildScrollView가 사용된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('GlassCard가 5개 존재한다 (계정정보, 앱설정, 테마선택, 데이터관리, 계정관리)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GlassCard), findsNWidgets(5));
    });

    testWidgets('화면이 에러 없이 렌더링된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });

  // ─── 계정 정보 표시 테스트 ─────────────────────────────────────────────────
  group('SettingsScreen - 계정 정보 카드', () {
    testWidgets('사용자 이름이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(displayName: '김테스트'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('김테스트'), findsOneWidget);
    });

    testWidgets('이메일이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(email: 'kim@test.com'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('kim@test.com'), findsOneWidget);
    });

    testWidgets('displayName이 null이면 "사용자"로 표시된다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAuthStateProvider.overrideWithValue(
              const AuthState(userId: 'test-user'),
            ),
            currentUserIdProvider.overrideWithValue('test-user'),
            isAuthenticatedProvider.overrideWithValue(true),
            isDarkModeProvider.overrideWith((ref) => false),
            hiveCacheServiceProvider.overrideWithValue(mockHiveCache),
            themePresetProvider.overrideWith((ref) => ThemePreset.glassmorphism),
            themePresetDataProvider.overrideWith(
              (ref) => ThemePresetRegistry.dataFor(ThemePreset.glassmorphism),
            ),
            // F17: Google Calendar 연동은 테스트에서 비활성화한다
            googleCalendarSyncEnabledProvider.overrideWith((ref) => false),
            calendarSyncStatusProvider.overrideWith(
              (ref) => CalendarSyncStatus.notConnected,
            ),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('사용자'), findsOneWidget);
    });

    testWidgets('프로필 아이콘이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('SettingsAccountInfoCard 위젯이 존재한다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SettingsAccountInfoCard), findsOneWidget);
    });
  });

  // ─── 다크 모드 토글 테스트 ─────────────────────────────────────────────────
  group('SettingsScreen - 다크 모드 토글', () {
    testWidgets('"다크 모드" 텍스트가 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('다크 모드'), findsOneWidget);
    });

    testWidgets('"앱 설정" 섹션 타이틀이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('앱 설정'), findsOneWidget);
    });

    testWidgets('Switch 위젯이 존재한다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 다크 모드 스위치 + Google Calendar 연동 스위치 = 2개 이상 존재한다
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('isDark=false일 때 Switch가 꺼져 있다', (tester) async {
      await tester.pumpWidget(buildTestWidget(isDark: false));
      await tester.pump(const Duration(milliseconds: 100));

      // 첫 번째 Switch가 다크 모드 토글이다 (두 번째는 Google Calendar 연동 토글)
      final switchWidget = tester.widget<Switch>(find.byType(Switch).first);
      expect(switchWidget.value, false);
    });

    testWidgets('isDark=true일 때 Switch가 켜져 있다', (tester) async {
      await tester.pumpWidget(buildTestWidget(isDark: true));
      await tester.pump(const Duration(milliseconds: 100));

      // 첫 번째 Switch가 다크 모드 토글이다 (두 번째는 Google Calendar 연동 토글)
      final switchWidget = tester.widget<Switch>(find.byType(Switch).first);
      expect(switchWidget.value, true);
    });

    testWidgets('isDark=false일 때 light_mode 아이콘이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(isDark: false));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    });

    testWidgets('isDark=true일 때 dark_mode 아이콘이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(isDark: true));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    });

    testWidgets('Switch 탭으로 다크 모드를 토글할 수 있다', (tester) async {
      await tester.pumpWidget(buildTestWidget(isDark: false));
      await tester.pump(const Duration(milliseconds: 100));

      // 첫 번째 Switch(다크 모드 토글)를 탭하여 토글한다
      await tester.tap(find.byType(Switch).first);
      await tester.pump(const Duration(milliseconds: 100));

      // 에러 없이 동작한다
      expect(tester.takeException(), isNull);
    });

    testWidgets('SettingsAppCard 위젯이 존재한다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SettingsAppCard), findsOneWidget);
    });
  });

  // ─── 계정 관리 (로그아웃/삭제) 테스트 ─────────────────────────────────────
  group('SettingsScreen - 계정 관리 카드', () {
    testWidgets('"계정 관리" 섹션 타이틀이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('계정 관리'), findsOneWidget);
    });

    testWidgets('"로그아웃" 텍스트가 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('로그아웃'), findsOneWidget);
    });

    testWidgets('"계정 삭제" 텍스트가 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('계정 삭제'), findsOneWidget);
    });

    testWidgets('로그아웃 아이콘이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('계정 삭제 아이콘이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.delete_forever_rounded), findsOneWidget);
    });

    testWidgets('SettingsAccountActionsCard 위젯이 존재한다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SettingsAccountActionsCard), findsOneWidget);
    });

    testWidgets('SettingsActionTile이 2개 존재한다 (로그아웃, 삭제)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SettingsActionTile), findsNWidgets(2));
    });

    testWidgets('chevron_right 아이콘이 액션 타일에 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 로그아웃 타일(1) + 계정 삭제 타일(1) = 2개
      // 참고: 데이터 관리 카드(_DataSettingsTile)에도 chevron이 1개 더 있으나
      // 계정 관리 카드 테스트이므로 최소 2개 이상임을 확인한다
      expect(find.byIcon(Icons.chevron_right_rounded), findsAtLeast(2));
    });
  });

  // ─── 레이아웃 테스트 ───────────────────────────────────────────────────────
  group('SettingsScreen - 레이아웃', () {
    testWidgets('SafeArea가 적용된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('Column이 사용된다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('스크롤이 가능하다', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 아래로 드래그한다
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  // ─── SettingsActionTile 단위 테스트 ────────────────────────────────────────
  group('SettingsActionTile - 위젯 테스트', () {
    testWidgets('일반 액션 타일이 올바르게 렌더링된다', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveCacheServiceProvider.overrideWithValue(mockHiveCache),
            themePresetProvider.overrideWith((ref) => ThemePreset.glassmorphism),
            themePresetDataProvider.overrideWith(
              (ref) => ThemePresetRegistry.dataFor(ThemePreset.glassmorphism),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SettingsActionTile(
                icon: Icons.settings,
                label: '테스트 설정',
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('테스트 설정'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      await tester.tap(find.text('테스트 설정'));
      expect(tapped, true);
    });

    testWidgets('파괴적 액션 타일이 올바르게 렌더링된다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveCacheServiceProvider.overrideWithValue(mockHiveCache),
            themePresetProvider.overrideWith((ref) => ThemePreset.glassmorphism),
            themePresetDataProvider.overrideWith(
              (ref) => ThemePresetRegistry.dataFor(ThemePreset.glassmorphism),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SettingsActionTile(
                icon: Icons.delete,
                label: '삭제',
                isDestructive: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('삭제'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });
  });

  // ─── SettingsAccountInfoCard 단위 테스트 ──────────────────────────────────
  // SettingsAccountInfoCard는 내부에 GlassCard(ConsumerWidget)를 포함하므로
  // 단위 테스트에도 ProviderScope와 themePreset Provider override가 필수다
  group('SettingsAccountInfoCard - 단위 테스트', () {
    testWidgets('이름과 이메일이 모두 표시된다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveCacheServiceProvider.overrideWithValue(mockHiveCache),
            themePresetProvider.overrideWith((ref) => ThemePreset.glassmorphism),
            themePresetDataProvider.overrideWith(
              (ref) => ThemePresetRegistry.dataFor(ThemePreset.glassmorphism),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SettingsAccountInfoCard(
                authState: AuthState(
                  userId: 'u1',
                  displayName: '홍길동',
                  email: 'hong@test.com',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('hong@test.com'), findsOneWidget);
    });

    testWidgets('이메일이 빈 문자열이면 표시되지 않는다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hiveCacheServiceProvider.overrideWithValue(mockHiveCache),
            themePresetProvider.overrideWith((ref) => ThemePreset.glassmorphism),
            themePresetDataProvider.overrideWith(
              (ref) => ThemePresetRegistry.dataFor(ThemePreset.glassmorphism),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SettingsAccountInfoCard(
                authState: AuthState(
                  userId: 'u1',
                  displayName: '홍길동',
                  email: '',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('홍길동'), findsOneWidget);
      // 빈 이메일 텍스트가 표시되지 않는다
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final emailTexts = textWidgets.where((t) => t.data == '');
      expect(emailTexts.isEmpty, true);
    });
  });

  // ─── isDarkModeProvider 상태 관리 테스트 ──────────────────────────────────
  group('isDarkModeProvider - 상태 관리', () {
    test('초기값은 HiveCacheService에서 읽어온다', () {
      final container = ProviderContainer(
        overrides: [
          hiveCacheServiceProvider.overrideWithValue(mockHiveCache),
        ],
      );
      addTearDown(container.dispose);

      // MockHiveCacheService 초기값은 null이므로 기본값 false가 된다
      expect(container.read(isDarkModeProvider), false);
    });

    test('true로 변경하면 Provider 상태가 갱신된다', () {
      final container = ProviderContainer(
        overrides: [
          hiveCacheServiceProvider.overrideWithValue(mockHiveCache),
        ],
      );
      addTearDown(container.dispose);

      container.read(isDarkModeProvider.notifier).state = true;
      expect(container.read(isDarkModeProvider), true);
    });

    test('토글 후 다시 원래 값으로 돌아올 수 있다', () {
      final container = ProviderContainer(
        overrides: [
          hiveCacheServiceProvider.overrideWithValue(mockHiveCache),
        ],
      );
      addTearDown(container.dispose);

      container.read(isDarkModeProvider.notifier).state = true;
      expect(container.read(isDarkModeProvider), true);

      container.read(isDarkModeProvider.notifier).state = false;
      expect(container.read(isDarkModeProvider), false);
    });
  });

  // ─── MockHiveCacheService 동작 테스트 ─────────────────────────────────────
  group('MockHiveCacheService - 동작 검증', () {
    test('saveSetting 후 readSetting으로 값을 읽을 수 있다', () async {
      await mockHiveCache.saveSetting('testKey', 'testValue');
      expect(mockHiveCache.readSetting<String>('testKey'), 'testValue');
    });

    test('bool 타입 설정을 저장하고 읽을 수 있다', () async {
      await mockHiveCache.saveSetting('isDarkMode', true);
      expect(mockHiveCache.readSetting<bool>('isDarkMode'), true);
    });

    test('존재하지 않는 키는 null을 반환한다', () {
      expect(mockHiveCache.readSetting<String>('nonexistent'), isNull);
    });

    test('타입이 다르면 null을 반환한다', () async {
      await mockHiveCache.saveSetting('key', 'string');
      expect(mockHiveCache.readSetting<int>('key'), isNull);
    });
  });
}
