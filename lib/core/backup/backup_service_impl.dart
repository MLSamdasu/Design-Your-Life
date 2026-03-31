// C0: BackupService — Google Drive + GitHub 백업 오케스트레이션
// DriveApiHelper에 Drive API, GitHubBackupService에 GitHub API 조작을 위임한다.

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../auth/auth_service.dart';
import '../auth/github_auth_service.dart';
import '../cache/hive_cache_service.dart';
import '../constants/app_constants.dart';
import 'backup_restore_helper.dart';
import 'backup_result.dart';
import 'backup_service_github.dart';
import 'drive_api_helper.dart';

/// Google Drive + GitHub 백업 서비스 (C0)
class BackupService {
  final GoogleSignIn _googleSignIn;
  final HiveCacheService _cache;
  final DriveApiHelper _driveHelper;
  final BackupRestoreHelper _restoreHelper;
  final GitHubAuthService _githubAuth;

  /// 백업 대상 Hive 박스 이름 목록 (settingsBox 제외)
  static const _boxNames = [
    AppConstants.userProfileBox,
    AppConstants.eventsBox,
    AppConstants.todosBox,
    AppConstants.habitsBox,
    AppConstants.habitLogsBox,
    AppConstants.goalsBox,
    AppConstants.subGoalsBox,
    AppConstants.goalTasksBox,
    AppConstants.timerLogsBox,
    AppConstants.achievementsBox,
    AppConstants.tagsBox,
    AppConstants.routinesBox,
    AppConstants.routineLogsBox,
    AppConstants.dailyRitualBox,
    AppConstants.dailyThreeBox,
    AppConstants.memosBox,
    AppConstants.booksBox,
    AppConstants.readingPlansBox,
  ];

  BackupService({
    required GoogleSignIn googleSignIn,
    required HiveCacheService cache,
    GitHubAuthService? githubAuth,
  })  : _googleSignIn = googleSignIn,
        _cache = cache,
        _driveHelper = DriveApiHelper(googleSignIn: googleSignIn),
        _restoreHelper = BackupRestoreHelper(cache: cache),
        _githubAuth = githubAuth ?? GitHubAuthService();

  /// 마지막 Google Drive 백업 시각 (없으면 null)
  DateTime? get lastBackupTime {
    final raw =
        _cache.readSetting<String>(AppConstants.settingsKeyLastBackupTime);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// 모든 로컬 데이터를 Google Drive appdata 폴더에 백업한다
  Future<BackupResult> backupAll({
    void Function(double progress)? onProgress,
  }) async {
    if (!AuthService.isAuthSupported) return BackupResult.unauthenticated();

    final currentUser = _googleSignIn.currentUser;
    if (currentUser == null) return BackupResult.unauthenticated();

    try {
      onProgress?.call(0.1);
      final backupData = _collectBoxData(onProgress);
      onProgress?.call(0.6);
      final jsonString = _serializeBackup(backupData);
      onProgress?.call(0.7);
      final driveApi = await _driveHelper.getDriveApi();
      if (driveApi == null) return BackupResult.unauthenticated();
      onProgress?.call(0.8);
      await _driveHelper.uploadBackupFile(driveApi, jsonString);
      onProgress?.call(0.9);
      await _driveHelper.deleteOldBackups(driveApi);
      onProgress?.call(0.95);
      await _cache.saveSetting(
        AppConstants.settingsKeyLastBackupTime,
        DateTime.now().toIso8601String(),
      );

      onProgress?.call(1.0);
      return BackupResult.success();
    } catch (e, st) {
      developer.log('[BackupService] 백업 실패: $e',
          name: 'backup', error: e, stackTrace: st);
      return BackupResult.failure('백업 중 오류가 발생했습니다. 네트워크 연결을 확인해주세요.');
    }
  }

  /// Google Drive에서 데이터를 복원한다
  Future<BackupResult> restoreFromCloud({
    void Function(double progress)? onProgress,
  }) async {
    if (!AuthService.isAuthSupported) return BackupResult.unauthenticated();

    final currentUser = _googleSignIn.currentUser;
    if (currentUser == null) return BackupResult.unauthenticated();

    try {
      onProgress?.call(0.1);
      final driveApi = await _driveHelper.getDriveApi();
      if (driveApi == null) return BackupResult.unauthenticated();
      final downloadResult = await _driveHelper.downloadBackupFile(driveApi);
      if (!downloadResult.isSuccess) {
        return BackupResult.failure(downloadResult.errorMessage!);
      }
      onProgress?.call(0.3);
      final parseResult =
          _restoreHelper.parseAndVerifyBackup(downloadResult.jsonString!);
      if (parseResult.error != null) {
        return BackupResult.failure(parseResult.error!);
      }
      onProgress?.call(0.5);
      final parsedData = _restoreHelper.parseBoxItems(parseResult.data!);
      onProgress?.call(0.6);
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
      developer.log('[BackupService] 복원 실패: $e',
          name: 'backup', error: e, stackTrace: st);
      return BackupResult.failure('복원 중 오류가 발생했습니다. 네트워크 연결을 확인해주세요.');
    }
  }

  /// GitHubBackupService 인스턴스를 지연 생성한다
  GitHubBackupService get _githubBackup => GitHubBackupService(
        cache: _cache,
        githubAuth: _githubAuth,
        boxNames: _boxNames,
        serializeFn: _serializeBackup,
        collectDataFn: _collectBoxData,
      );

  /// 모든 로컬 데이터를 GitHub 비공개 레포지토리에 백업한다
  Future<BackupResult> backupToGitHub({
    String? token,
    void Function(double progress)? onProgress,
  }) {
    return _githubBackup.backup(token: token, onProgress: onProgress);
  }

  /// GitHub 레포지토리에서 데이터를 복원한다
  Future<BackupResult> restoreFromGitHub({
    String? token,
    void Function(double progress)? onProgress,
  }) {
    return _githubBackup.restore(token: token, onProgress: onProgress);
  }

  /// 모든 Hive 박스의 데이터를 Map으로 수집한다
  Map<String, List<Map<String, dynamic>>> _collectBoxData(
    void Function(double progress)? onProgress,
  ) {
    final backupData = <String, List<Map<String, dynamic>>>{};
    for (int i = 0; i < _boxNames.length; i++) {
      backupData[_boxNames[i]] = _cache.getAll(_boxNames[i]);
      onProgress?.call(0.1 + (0.5 * (i + 1) / _boxNames.length));
    }
    return backupData;
  }

  /// 백업 데이터를 JSON 문자열로 직렬화한다 (SHA-256 체크섬 포함)
  String _serializeBackup(Map<String, List<Map<String, dynamic>>> data) {
    final dataJsonString = jsonEncode(data);
    final dataHash = sha256.convert(utf8.encode(dataJsonString)).toString();
    return jsonEncode({
      'version': 2,
      'app_version': '1.0.0',
      'createdAt': DateTime.now().toIso8601String(),
      'checksum': dataHash,
      'data': data,
    });
  }
}
