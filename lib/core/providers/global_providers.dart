// C0.9: 공통 Riverpod Provider 정의
// authStateProvider, currentUserIdProvider,
// themeProvider, hiveCacheProvider 등
// 앱 전역 싱글톤 Provider를 정의한다.
// 모든 Feature Provider가 이 파일을 참조한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/hive_cache_service.dart';
import '../constants/app_constants.dart';
import '../theme/layout_tokens.dart';
import '../theme/theme_preset.dart';
import '../theme/theme_preset_data.dart';
import '../theme/theme_preset_registry.dart';

// auth_provider.dart를 재내보내기하지 않는다 (순환 참조 방지).
// Feature에서 인증 Provider 사용 시 auth_provider.dart를 직접 import한다.

// ─── 오늘 날짜 Provider ──────────────────────────────────────────────────
/// 오늘 날짜(시간 제거) StateProvider — 홈 대시보드 전체에서 공유한다
/// 각 Provider가 독립적으로 DateTime.now()를 호출하면 자정 경계에서 불일치가 발생할 수 있다
/// StateProvider로 선언하여 앱이 백그라운드에서 복귀할 때 자정 갱신이 가능하도록 한다
final todayDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// ─── HiveCacheService Provider ───────────────────────────────────────────
/// HiveCacheService 싱글톤 인스턴스
/// _locks 맵이 단일 인스턴스에서만 관리되도록 보장한다
final _hiveCacheServiceInstance = HiveCacheService();

/// Hive 캐시 서비스 Provider
/// Repository 계층에서 Write-Through 캐시 패턴 구현에 사용한다
/// 모듈 수준 싱글톤을 반환하여 동시 쓰기 보호 잠금의 일관성을 보장한다
final hiveCacheServiceProvider = Provider<HiveCacheService>((ref) {
  return _hiveCacheServiceInstance;
});

// ─── 테마 Provider ───────────────────────────────────────────────────────
/// 다크 모드 여부 Provider
/// Hive settingsBox에 저장된 값을 읽어 초기 테마를 결정한다
final isDarkModeProvider = StateProvider<bool>((ref) {
  final cacheService = ref.watch(hiveCacheServiceProvider);
  return cacheService.readSetting<bool>(AppConstants.settingsKeyDarkMode) ?? false;
});

// ─── 테마 프리셋 Provider ──────────────────────────────────────────────────
/// 현재 선택된 테마 프리셋 Provider
/// 기존 6개 프리셋 문자열을 3개 신규 프리셋으로 자동 매핑한다
/// 기본값: ThemePreset.refinedGlass
final themePresetProvider = StateProvider<ThemePreset>((ref) {
  final cacheService = ref.watch(hiveCacheServiceProvider);
  final saved = cacheService.readSetting<String>(AppConstants.settingsKeyThemePreset);
  if (saved == null) return ThemePreset.refinedGlass;
  return _migrateThemePreset(saved);
});

/// Hive에 저장된 기존 테마 프리셋 문자열을 신규 3개 enum으로 매핑한다
ThemePreset _migrateThemePreset(String saved) {
  return switch (saved) {
    'glassmorphism' => ThemePreset.refinedGlass,
    'refinedGlass' => ThemePreset.refinedGlass,
    'minimal' => ThemePreset.cleanMinimal,
    'clean' => ThemePreset.cleanMinimal,
    'cleanMinimal' => ThemePreset.cleanMinimal,
    'neon' => ThemePreset.darkGlass,
    'darkGlass' => ThemePreset.darkGlass,
    _ => ThemePreset.refinedGlass, // retro, soft 등 제거된 프리셋은 기본값
  };
}

/// 현재 테마 프리셋의 시각 데이터 Provider (파생 Provider)
/// themePresetProvider 변경 시 자동으로 ThemePresetData를 갱신한다
final themePresetDataProvider = Provider<ThemePresetData>((ref) {
  final preset = ref.watch(themePresetProvider);
  return ThemePresetRegistry.dataFor(preset);
});

// ─── 네비게이션 바 위치 Provider ───────────────────────────────────────────
/// 네비 바 좌/우 위치 (true: 왼쪽, false: 오른쪽)
/// Hive settingsBox의 'navSide' 키에서 초기값을 읽는다
/// 기본값: false (오른쪽)
final navSideLeftProvider = StateProvider<bool>((ref) {
  final cacheService = ref.watch(hiveCacheServiceProvider);
  final saved = cacheService.readSetting<String>(AppConstants.settingsKeyNavSide);
  return saved == 'left';
});

/// 네비 바 수직 위치 (Alignment.y 값, -1.0=상단 ~ 1.0=하단)
/// Hive settingsBox의 'navVerticalPos' 키에서 초기값을 읽는다
/// 기본값: 0.0 (중앙)
final navVerticalPosProvider = StateProvider<double>((ref) {
  final cacheService = ref.watch(hiveCacheServiceProvider);
  final saved = cacheService.readSetting<double>(AppConstants.settingsKeyNavVerticalPos);
  return saved ?? 0.0;
});

/// 네비 바 크기 (캡슐 너비 px, sideNavWidthMin ~ sideNavWidthMax)
/// Hive settingsBox의 'navSize' 키에서 초기값을 읽는다
/// 기본값: AppLayout.sideNavWidth (56px)
final navSizeProvider = StateProvider<double>((ref) {
  final cacheService = ref.watch(hiveCacheServiceProvider);
  final saved = cacheService.readSetting<double>(AppConstants.settingsKeyNavSize);
  return saved ?? AppLayout.sideNavWidth;
});

// ─── 인증 Provider (재내보내기) ──────────────────────────────────────────
// auth_provider.dart에서 정의된 Provider를 재내보내기하여
// Feature들이 global_providers.dart 하나만 import하면 되도록 한다
// authServiceProvider, authStateProvider, currentUserIdProvider,
// currentAuthStateProvider, isAuthenticatedProvider 사용 가능
