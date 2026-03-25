// C0: GitHub 백업 Riverpod Provider
// GitHub 자동 백업 주기, 마지막 백업 시각, 진행 상태 등
// GitHub 백업 기능에 필요한 상태 Provider를 정의한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../auth/github_auth_provider.dart';
import '../constants/app_constants.dart';
import '../providers/global_providers.dart';
import 'backup_service_impl.dart';
import 'github_backup_scheduler.dart';

// ─── 백업 주기 Provider ─────────────────────────────────────────────────────
/// Hive settingsBox에서 저장된 GitHub 백업 주기를 읽는다
final githubBackupIntervalProvider = StateProvider<BackupInterval>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  final saved = cache.readSetting<String>(
    AppConstants.settingsKeyGithubBackupInterval,
  );
  return BackupInterval.fromName(saved);
});

/// UI 호환 별칭
final gitHubBackupIntervalProvider = githubBackupIntervalProvider;

/// 백업 주기를 Hive에 저장하는 콜백 Provider
final saveGitHubBackupIntervalProvider =
    Provider<void Function(BackupInterval)>((ref) {
  return (BackupInterval interval) async {
    ref.read(githubBackupIntervalProvider.notifier).state = interval;
    final cache = ref.read(hiveCacheServiceProvider);
    await cache.saveSetting(
      AppConstants.settingsKeyGithubBackupInterval,
      interval.name,
    );
  };
});

// ─── 마지막 GitHub 백업 시각 Provider ────────────────────────────────────────
/// 마지막 백업 시각 갱신 트리거 카운터
final lastGitHubBackupVersionProvider = StateProvider<int>((ref) => 0);

/// Hive settingsBox에서 마지막 GitHub 백업 시각을 읽는다
final lastGithubBackupTimeProvider = Provider<DateTime?>((ref) {
  ref.watch(githubDataVersionProvider);
  ref.watch(lastGitHubBackupVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  final raw = cache.readSetting<String>(
    AppConstants.settingsKeyLastGithubBackupTime,
  );
  if (raw == null) return null;
  return DateTime.tryParse(raw);
});

/// UI 호환 별칭
final lastGitHubBackupTimeProvider = lastGithubBackupTimeProvider;

// ─── 백업 진행 상태 Provider ──────────────────────────────────────────────
/// GitHub 백업이 현재 진행 중인지 여부
final isGithubBackingUpProvider = StateProvider<bool>((ref) => false);

/// UI 호환 별칭
final isGitHubBackingUpProvider = isGithubBackingUpProvider;

/// GitHub 복원이 현재 진행 중인지 여부
final isGitHubRestoringProvider = StateProvider<bool>((ref) => false);

/// 백업 진행률 (0.0 ~ 1.0)
final gitHubBackupProgressProvider = StateProvider<double>((ref) => 0.0);

// ─── BackupService Provider (GitHub용) ──────────────────────────────────
/// BackupService 인스턴스 (GitHub 메서드 호출용)
final gitHubBackupServiceProvider = Provider<BackupService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  final githubAuth = ref.watch(githubAuthServiceProvider);
  return BackupService(
    googleSignIn: authService.googleSignIn,
    cache: cache,
    githubAuth: githubAuth,
  );
});

// ─── 스케줄러 싱글톤 Provider ────────────────────────────────────────────────
/// GitHubBackupScheduler 싱글톤 인스턴스
final githubBackupSchedulerProvider =
    Provider<GitHubBackupScheduler>((ref) {
  final scheduler = GitHubBackupScheduler();
  ref.onDispose(scheduler.stop);
  return scheduler;
});
