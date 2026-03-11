// C0.9: 공통 Riverpod Provider 정의
// authStateProvider, currentUserIdProvider,
// themeProvider, hiveCacheProvider 등
// 앱 전역 싱글톤 Provider를 정의한다.
// 모든 Feature Provider가 이 파일을 참조한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/hive_cache_service.dart';
import '../theme/theme_preset.dart';
import '../theme/theme_preset_data.dart';
import '../theme/theme_preset_registry.dart';

// auth_provider.dart를 재내보내기하지 않는다 (순환 참조 방지).
// Feature에서 인증 Provider 사용 시 auth_provider.dart를 직접 import한다.

// ─── HiveCacheService Provider ───────────────────────────────────────────
/// Hive 캐시 서비스 Provider
/// Repository 계층에서 Write-Through 캐시 패턴 구현에 사용한다
final hiveCacheServiceProvider = Provider<HiveCacheService>((ref) {
  return HiveCacheService();
});

// ─── 테마 Provider ───────────────────────────────────────────────────────
/// 다크 모드 여부 Provider
/// Hive settingsBox에 저장된 값을 읽어 초기 테마를 결정한다
final isDarkModeProvider = StateProvider<bool>((ref) {
  final cacheService = ref.watch(hiveCacheServiceProvider);
  return cacheService.readSetting<bool>('isDarkMode') ?? false;
});

// ─── 테마 프리셋 Provider ──────────────────────────────────────────────────
/// 현재 선택된 테마 프리셋 Provider
/// Hive settingsBox의 'themePreset' 키에서 초기값을 읽는다
/// 기본값: ThemePreset.glassmorphism (기존 동작 유지, 하위 호환)
final themePresetProvider = StateProvider<ThemePreset>((ref) {
  final cacheService = ref.watch(hiveCacheServiceProvider);
  final saved = cacheService.readSetting<String>('themePreset');
  // 저장된 값이 없으면 glassmorphism(기본값)으로 초기화한다
  if (saved == null) return ThemePreset.glassmorphism;
  // 유효하지 않은 문자열이면 glassmorphism으로 폴백한다
  return ThemePreset.values.firstWhere(
    (e) => e.name == saved,
    orElse: () => ThemePreset.glassmorphism,
  );
});

/// 현재 테마 프리셋의 시각 데이터 Provider (파생 Provider)
/// themePresetProvider 변경 시 자동으로 ThemePresetData를 갱신한다
final themePresetDataProvider = Provider<ThemePresetData>((ref) {
  final preset = ref.watch(themePresetProvider);
  return ThemePresetRegistry.dataFor(preset);
});

// ─── 인증 Provider (재내보내기) ──────────────────────────────────────────
// auth_provider.dart에서 정의된 Provider를 재내보내기하여
// Feature들이 global_providers.dart 하나만 import하면 되도록 한다
// authServiceProvider, authStateProvider, currentUserIdProvider,
// currentAuthStateProvider, isAuthenticatedProvider 사용 가능
