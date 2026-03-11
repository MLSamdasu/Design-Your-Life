// C0: 백업 Riverpod Provider
// BackupService 싱글톤, 마지막 백업 시각, 백업 진행 상태를 제공한다.
// backupServiceProvider는 GoogleSignIn과 HiveCacheService를 주입받아 생성한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../providers/global_providers.dart';
import 'backup_service.dart';

// ─── BackupService Provider ──────────────────────────────────────────────
/// BackupService 싱글톤 Provider
/// AuthService의 GoogleSignIn과 HiveCacheService를 주입받아 생성한다
final backupServiceProvider = Provider<BackupService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return BackupService(
    googleSignIn: authService.googleSignIn,
    cache: cache,
  );
});

// ─── 마지막 백업 시각 Provider ─────────────────────────────────────────────
/// 마지막 백업 시각 Provider
/// BackupService의 lastBackupTime을 반환한다 (없으면 null)
final lastBackupTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(backupServiceProvider).lastBackupTime;
});

// ─── 백업 진행 상태 Provider ──────────────────────────────────────────────
/// 백업 진행 중 여부 Provider
/// UI에서 로딩 인디케이터 표시에 사용한다
final isBackingUpProvider = StateProvider<bool>((ref) => false);

// ─── 백업 진행률 Provider ─────────────────────────────────────────────────
/// 백업 진행률 Provider (0.0 ~ 1.0)
/// 백업 중 프로그레스 바 표시에 사용한다
final backupProgressProvider = StateProvider<double>((ref) => 0.0);

// ─── 복원 진행 상태 Provider ──────────────────────────────────────────────
/// 복원 진행 중 여부 Provider
/// UI에서 로딩 인디케이터 표시에 사용한다
final isRestoringProvider = StateProvider<bool>((ref) => false);
