// C0: BackupService — Google Drive 백업 서비스
// 사용자가 명시적으로 "백업" 버튼을 눌렀을 때만 Google Drive에 데이터를 업로드한다.
// 로컬 퍼스트 아키텍처에서 Google Drive는 선택적 클라우드 백업 수단이다.
// 미인증 상태에서는 백업/복원 기능을 사용할 수 없으며, 로그인을 유도한다.
// Google Drive appdata 폴더에 JSON 파일로 백업한다 (앱 전용, 사용자에게 보이지 않음).

import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../cache/hive_cache_service.dart';
import '../constants/app_constants.dart';

/// 백업 결과 상태
enum BackupResultStatus {
  /// 백업 성공
  success,

  /// 인증되지 않은 상태 (로그인 필요)
  unauthenticated,

  /// 백업 중 오류 발생
  error,
}

/// 백업 작업 결과 값 객체
class BackupResult {
  /// 백업 결과 상태
  final BackupResultStatus status;

  /// 오류 메시지 (status가 error일 때만 non-null)
  final String? errorMessage;

  /// 백업 완료 시각 (status가 success일 때만 non-null)
  final DateTime? completedAt;

  const BackupResult({
    required this.status,
    this.errorMessage,
    this.completedAt,
  });

  /// 성공 결과 팩토리
  factory BackupResult.success() {
    return BackupResult(
      status: BackupResultStatus.success,
      completedAt: DateTime.now(),
    );
  }

  /// 미인증 결과 팩토리
  factory BackupResult.unauthenticated() {
    return const BackupResult(status: BackupResultStatus.unauthenticated);
  }

  /// 오류 결과 팩토리
  factory BackupResult.failure(String message) {
    return BackupResult(
      status: BackupResultStatus.error,
      errorMessage: message,
    );
  }

  /// 성공 여부
  bool get isSuccess => status == BackupResultStatus.success;
}

/// Google Drive appdata 백업 파일 이름
const _backupFileName = 'dyl_backup.json';

/// Google Drive 백업 서비스 (C0)
/// 사용자가 명시적으로 "백업" 버튼을 눌렀을 때만 실행된다
/// Google Drive appdata 폴더에 JSON 파일로 백업한다
class BackupService {
  final GoogleSignIn _googleSignIn;
  final HiveCacheService _cache;

  BackupService({
    required GoogleSignIn googleSignIn,
    required HiveCacheService cache,
  })  : _googleSignIn = googleSignIn,
        _cache = cache;

  // ─── Google Drive API 클라이언트 생성 ──────────────────────────────────────
  /// 인증된 HTTP 클라이언트를 통해 Drive API 인스턴스를 생성한다
  Future<drive.DriveApi?> _getDriveApi() async {
    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient == null) return null;
    return drive.DriveApi(httpClient);
  }

  // ─── 마지막 백업 시각 ──────────────────────────────────────────────────────
  /// 마지막 백업 시각을 반환한다 (없으면 null)
  DateTime? get lastBackupTime {
    final raw =
        _cache.readSetting<String>(AppConstants.settingsKeyLastBackupTime);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ─── 전체 백업 ────────────────────────────────────────────────────────────
  /// 모든 로컬 데이터를 Google Drive appdata 폴더에 백업한다
  ///
  /// 1. 인증 상태 확인 (미인증이면 unauthenticated 반환)
  /// 2. 각 Hive 박스의 데이터를 JSON으로 직렬화
  /// 3. Google Drive appdata 폴더에 단일 JSON 파일로 업로드
  /// 4. 마지막 백업 시간 기록
  ///
  /// [onProgress]: 진행률 콜백 (0.0 ~ 1.0)
  Future<BackupResult> backupAll({
    void Function(double progress)? onProgress,
  }) async {
    // 1단계: 인증 상태 확인
    final currentUser = _googleSignIn.currentUser;
    if (currentUser == null) {
      return BackupResult.unauthenticated();
    }

    try {
      onProgress?.call(0.1);

      // 2단계: 모든 Hive 박스의 데이터를 JSON으로 수집한다
      final backupData = <String, List<Map<String, dynamic>>>{};

      final boxNames = [
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
      ];

      for (int i = 0; i < boxNames.length; i++) {
        final boxName = boxNames[i];
        backupData[boxName] = _cache.getAll(boxName);
        // 진행률: 10% ~ 60% (데이터 수집 구간)
        onProgress?.call(0.1 + (0.5 * (i + 1) / boxNames.length));
      }

      // 3단계: JSON 직렬화
      final jsonString = jsonEncode({
        'version': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'data': backupData,
      });

      onProgress?.call(0.7);

      // 4단계: Google Drive appdata 폴더에 업로드
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return BackupResult.unauthenticated();
      }

      // 기존 백업 파일이 있으면 삭제한다 (덮어쓰기)
      await _deleteExistingBackup(driveApi);

      onProgress?.call(0.8);

      // 새 백업 파일 업로드
      final fileMetadata = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder'];

      final mediaStream = Stream.value(utf8.encode(jsonString));
      final media = drive.Media(mediaStream, utf8.encode(jsonString).length);

      await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      onProgress?.call(0.95);

      // 5단계: 마지막 백업 시각 기록
      await _cache.saveSetting(
        AppConstants.settingsKeyLastBackupTime,
        DateTime.now().toIso8601String(),
      );

      onProgress?.call(1.0);
      return BackupResult.success();
    } catch (e) {
      return BackupResult.failure('백업 중 오류가 발생했습니다: $e');
    }
  }

  // ─── 클라우드 복원 ────────────────────────────────────────────────────────
  /// Google Drive에서 데이터를 복원한다 (로그인 후 첫 사용 시 또는 수동 복원 시)
  /// 기존 로컬 데이터에 클라우드 데이터를 덮어쓴다
  ///
  /// [onProgress]: 진행률 콜백 (0.0 ~ 1.0)
  Future<BackupResult> restoreFromCloud({
    void Function(double progress)? onProgress,
  }) async {
    // 인증 상태 확인
    final currentUser = _googleSignIn.currentUser;
    if (currentUser == null) {
      return BackupResult.unauthenticated();
    }

    try {
      onProgress?.call(0.1);

      // Drive API 클라이언트 생성
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return BackupResult.unauthenticated();
      }

      // appdata 폴더에서 백업 파일을 검색한다
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        $fields: 'files(id, name, modifiedTime)',
      );

      final files = fileList.files;
      if (files == null || files.isEmpty) {
        return BackupResult.failure('백업 파일이 없습니다');
      }

      onProgress?.call(0.3);

      // 백업 파일 다운로드
      final fileId = files.first.id!;
      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }
      final jsonString = utf8.decode(bytes);

      onProgress?.call(0.5);

      // JSON 파싱
      final backupJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final data = backupJson['data'] as Map<String, dynamic>?;
      if (data == null) {
        return BackupResult.failure('백업 파일 형식이 올바르지 않습니다');
      }

      // 각 박스의 데이터를 Hive에 복원한다
      final boxNames = data.keys.toList();
      for (int i = 0; i < boxNames.length; i++) {
        final boxName = boxNames[i];
        final items = data[boxName] as List<dynamic>?;
        if (items == null) continue;

        // 기존 박스 데이터 초기화 후 클라우드 데이터로 덮어쓴다
        await _cache.clearBox(boxName);

        for (final item in items) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);
          final id = map['id']?.toString();
          if (id == null || id.isEmpty) continue;
          await _cache.put(boxName, id, map);
        }

        // 진행률: 50% ~ 95% (데이터 복원 구간)
        onProgress?.call(0.5 + (0.45 * (i + 1) / boxNames.length));
      }

      onProgress?.call(1.0);
      return BackupResult.success();
    } catch (e) {
      return BackupResult.failure('복원 중 오류가 발생했습니다: $e');
    }
  }

  // ─── 내부 헬퍼 ───────────────────────────────────────────────────────────
  /// 기존 백업 파일을 삭제한다 (새 백업 전 정리)
  Future<void> _deleteExistingBackup(drive.DriveApi driveApi) async {
    try {
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        $fields: 'files(id)',
      );

      final files = fileList.files;
      if (files != null) {
        for (final file in files) {
          if (file.id != null) {
            await driveApi.files.delete(file.id!);
          }
        }
      }
    } catch (_) {
      // 기존 파일 삭제 실패는 무시한다 (새 파일 업로드에는 영향 없음)
    }
  }
}
