// C0: BackupService GitHub 확장
// BackupService에 GitHub 백업/복원 메서드를 추가한다.
// backup_service_impl.dart의 크기 제한(200줄)을 준수하기 위해 분리한다.
// BackupService의 내부 헬퍼(_collectBoxData, _serializeBackup)를 재사용한다.

import 'dart:developer' as developer;

import '../auth/github_auth_service.dart';
import '../cache/hive_cache_service.dart';
import '../constants/app_constants.dart';
import 'backup_restore_helper.dart';
import 'backup_result.dart';
import 'github_api_helper.dart';

/// GitHub 백업/복원 오케스트레이터 (C0)
/// BackupService와 동일한 데이터 수집/직렬화 로직을 사용하되
/// GitHub API를 통해 비공개 레포지토리에 백업한다
class GitHubBackupService {
  final HiveCacheService _cache;
  final GitHubAuthService _githubAuth;
  final BackupRestoreHelper _restoreHelper;

  /// JSON 직렬화 함수 (BackupService에서 주입)
  final String Function(Map<String, List<Map<String, dynamic>>>) _serialize;

  /// 박스 데이터 수집 함수 (BackupService에서 주입)
  final Map<String, List<Map<String, dynamic>>> Function(
      void Function(double)?) _collectData;

  GitHubBackupService({
    required HiveCacheService cache,
    required GitHubAuthService githubAuth,
    required List<String> boxNames,
    required String Function(Map<String, List<Map<String, dynamic>>>)
        serializeFn,
    required Map<String, List<Map<String, dynamic>>> Function(
            void Function(double)?)
        collectDataFn,
  })  : _cache = cache,
        _githubAuth = githubAuth,
        _serialize = serializeFn,
        _collectData = collectDataFn,
        _restoreHelper = BackupRestoreHelper(cache: cache);

  /// 모든 로컬 데이터를 GitHub 비공개 레포지토리에 백업한다
  Future<BackupResult> backup({
    String? token,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final pat = token ?? await _githubAuth.getToken();
      if (pat == null) return BackupResult.unauthenticated();
      onProgress?.call(0.1);

      // Hive 박스 데이터 수집
      final backupData = _collectData(onProgress);
      onProgress?.call(0.4);

      // JSON 직렬화 + SHA-256 무결성 해시
      final jsonString = _serialize(backupData);
      onProgress?.call(0.6);

      // GitHub API로 업로드
      final helper = GitHubApiHelper(token: pat);
      final repoFullName = await helper.createOrGetRepo();
      onProgress?.call(0.7);

      await helper.uploadBackup(repoFullName, jsonString);
      onProgress?.call(0.95);

      // 마지막 GitHub 백업 시각 기록
      await _cache.saveSetting(
        HiveKeys.lastGithubBackupTime,
        DateTime.now().toIso8601String(),
      );

      onProgress?.call(1.0);
      return BackupResult.success();
    } catch (e, st) {
      developer.log('[GitHubBackupService] 백업 실패: $e',
          name: 'backup', error: e, stackTrace: st);
      return BackupResult.failure(
          'GitHub 백업 중 오류가 발생했습니다. 네트워크 연결을 확인해주세요.');
    }
  }

  /// GitHub 레포지토리에서 데이터를 복원한다
  Future<BackupResult> restore({
    String? token,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final pat = token ?? await _githubAuth.getToken();
      if (pat == null) return BackupResult.unauthenticated();
      onProgress?.call(0.1);

      // GitHub에서 백업 JSON 다운로드
      final helper = GitHubApiHelper(token: pat);
      final repoFullName = await helper.createOrGetRepo();
      final jsonString = await helper.downloadBackup(repoFullName);
      if (jsonString == null) {
        return BackupResult.failure('GitHub에 백업 파일이 없습니다');
      }
      onProgress?.call(0.3);

      // JSON 파싱 및 무결성 검증
      final parseResult = _restoreHelper.parseAndVerifyBackup(jsonString);
      if (parseResult.error != null) {
        return BackupResult.failure(parseResult.error!);
      }
      onProgress?.call(0.5);

      // 데이터 파싱 및 유효성 검증
      final parsedData = _restoreHelper.parseBoxItems(parseResult.data!);
      onProgress?.call(0.6);

      // 원자적 교체
      final failedBoxes =
          await _restoreHelper.atomicReplace(parsedData, onProgress);
      if (failedBoxes.isNotEmpty) {
        return BackupResult.failure(
          '일부 데이터 복원에 실패했습니다: ${failedBoxes.join(', ')}',
        );
      }

      onProgress?.call(1.0);
      return BackupResult.success();
    } catch (e, st) {
      developer.log('[GitHubBackupService] 복원 실패: $e',
          name: 'backup', error: e, stackTrace: st);
      return BackupResult.failure(
          'GitHub 복원 중 오류가 발생했습니다. 네트워크 연결을 확인해주세요.');
    }
  }
}
