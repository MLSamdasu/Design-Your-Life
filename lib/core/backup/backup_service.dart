// C0: BackupService — Google Drive 백업 서비스
// 사용자가 명시적으로 "백업" 버튼을 눌렀을 때만 Google Drive에 데이터를 업로드한다.
// 로컬 퍼스트 아키텍처에서 Google Drive는 선택적 클라우드 백업 수단이다.
// 미인증 상태에서는 백업/복원 기능을 사용할 수 없으며, 로그인을 유도한다.
// Google Drive appdata 폴더에 JSON 파일로 백업한다 (앱 전용, 사용자에게 보이지 않음).

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../auth/auth_service.dart';
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
    // 인증 미지원 플랫폼(Windows, macOS 미설정)에서는 즉시 미인증 반환
    if (!AuthService.isAuthSupported) return BackupResult.unauthenticated();

    // 1단계: 인증 상태 확인
    final currentUser = _googleSignIn.currentUser;
    if (currentUser == null) {
      return BackupResult.unauthenticated();
    }

    try {
      onProgress?.call(0.1);

      // 2단계: 모든 Hive 박스의 데이터를 JSON으로 수집한다
      final backupData = <String, List<Map<String, dynamic>>>{};

      // settingsBox 제외: 테마, 다크모드 등 사용자 설정은 디바이스 환경에 종속되므로
      // 백업/복원 대상에서 제외한다. 복원 시 현재 디바이스 설정이 덮어쓰이는 문제를 방지한다.
      final boxNames = [
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
      ];

      for (int i = 0; i < boxNames.length; i++) {
        final boxName = boxNames[i];
        backupData[boxName] = _cache.getAll(boxName);
        // 진행률: 10% ~ 60% (데이터 수집 구간)
        onProgress?.call(0.1 + (0.5 * (i + 1) / boxNames.length));
      }

      // 3단계: JSON 직렬화 + SHA-256 무결성 해시
      // 데이터 JSON을 먼저 직렬화한 후 해시를 계산하여 최종 백업 JSON에 포함한다
      final dataJsonString = jsonEncode(backupData);
      final dataHash = sha256.convert(utf8.encode(dataJsonString)).toString();
      final jsonString = jsonEncode({
        'version': 2,
        'app_version': '1.0.0',
        'createdAt': DateTime.now().toIso8601String(),
        'checksum': dataHash,
        'data': backupData,
      });

      onProgress?.call(0.7);

      // 4단계: Google Drive appdata 폴더에 업로드
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        return BackupResult.unauthenticated();
      }

      onProgress?.call(0.8);

      // 새 백업 파일을 먼저 업로드한다 (업로드-우선 전략)
      // 기존 파일을 먼저 삭제하면 업로드 실패 시 백업이 모두 소실되므로,
      // 새 파일을 먼저 올린 뒤 기존 파일을 삭제한다.
      // Drive API는 동일 이름 파일 복수 허용 → 복원 시 files.first로 최신 파일을 찾는다.
      final fileMetadata = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder'];

      // UTF-8 인코딩을 한 번만 수행하여 메모리 이중 할당을 방지한다
      final bytes = utf8.encode(jsonString);
      final mediaStream = Stream.value(bytes);
      final media = drive.Media(mediaStream, bytes.length);

      await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      onProgress?.call(0.9);

      // 업로드 성공 후 기존 백업 파일을 삭제한다
      // 삭제 실패 시 중복 파일이 남지만 데이터 소실보다 안전하다
      await _deleteOldBackups(driveApi);

      onProgress?.call(0.95);

      // 5단계: 마지막 백업 시각 기록
      await _cache.saveSetting(
        AppConstants.settingsKeyLastBackupTime,
        DateTime.now().toIso8601String(),
      );

      onProgress?.call(1.0);
      return BackupResult.success();
    } catch (e, st) {
      // 내부 예외 상세를 사용자에게 노출하지 않는다 (보안)
      developer.log('[BackupService] 백업 실패: $e',
          name: 'backup', error: e, stackTrace: st);
      return BackupResult.failure('백업 중 오류가 발생했습니다. 네트워크 연결을 확인해주세요.');
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
    // 인증 미지원 플랫폼(Windows, macOS 미설정)에서는 즉시 미인증 반환
    if (!AuthService.isAuthSupported) return BackupResult.unauthenticated();

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

      // 백업 파일 다운로드 — Drive API가 id를 누락할 수 있으므로 방어 처리한다
      final fileId = files.first.id;
      if (fileId == null) {
        return BackupResult.failure('백업 파일 ID를 가져올 수 없습니다');
      }
      // Drive API 응답을 안전하게 타입 검사한다 (as 캐스트 대신 is 검사)
      final rawResponse = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      if (rawResponse is! drive.Media) {
        return BackupResult.failure('백업 파일을 다운로드할 수 없습니다');
      }
      final response = rawResponse;

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

      // 무결성 검증: version 2 이상이면 SHA-256 체크섬을 확인한다
      final version = backupJson['version'] as int? ?? 1;
      if (version >= 2) {
        final storedChecksum = backupJson['checksum'] as String?;
        if (storedChecksum == null) {
          return BackupResult.failure('백업 파일의 무결성 정보가 없습니다');
        }
        final computedChecksum =
            sha256.convert(utf8.encode(jsonEncode(data))).toString();
        if (storedChecksum != computedChecksum) {
          developer.log(
            '[BackupService] 체크섬 불일치: stored=$storedChecksum, computed=$computedChecksum',
            name: 'backup',
          );
          return BackupResult.failure('백업 파일이 손상되었습니다. 다시 백업해주세요.');
        }
      }

      // 허용된 박스 이름 목록 — 알 수 없는 박스 이름의 데이터 주입을 방지한다
      const allowedBoxes = {
        AppConstants.userProfileBox,
        AppConstants.eventsBox,
        AppConstants.todosBox,
        AppConstants.habitsBox,
        AppConstants.habitLogsBox,
        AppConstants.routinesBox,
        AppConstants.routineLogsBox,
        AppConstants.goalsBox,
        AppConstants.subGoalsBox,
        AppConstants.goalTasksBox,
        AppConstants.timerLogsBox,
        AppConstants.achievementsBox,
        AppConstants.tagsBox,
      };
      // 각 박스의 데이터를 Hive에 복원한다
      // settingsBox는 복원 대상에서 제외한다: 이전 백업 파일에 settingsBox가 포함되어 있어도
      // 현재 디바이스의 테마, 다크모드 등 사용자 설정을 보존하기 위해 건너뛴다.
      final boxNames = data.keys
          .where((name) => allowedBoxes.contains(name))
          .toList();

      // 1단계: 모든 데이터를 먼저 파싱하여 유효성을 검증한다
      // 로컬 데이터를 지우기 전에 파싱을 완료해야 실패 시 데이터 손실을 방지할 수 있다
      final parsedData =
          <String, List<MapEntry<String, Map<String, dynamic>>>>{};
      for (final boxName in boxNames) {
        final items = data[boxName] as List<dynamic>?;
        if (items == null) continue;
        final parsed = <MapEntry<String, Map<String, dynamic>>>[];
        for (final item in items) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);
          final id = map['id']?.toString();
          if (id == null || id.isEmpty) continue;
          parsed.add(MapEntry(id, map));
        }
        if (parsed.isNotEmpty) parsedData[boxName] = parsed;
      }

      onProgress?.call(0.6);

      // 2단계: 파싱 성공 후 로컬 데이터를 교체한다
      // 박스별로 try-catch하여 일부 실패해도 나머지 박스는 복원을 계속한다
      final failedBoxes = <String>[];
      // parsedData가 비어있을 때 0으로 나누는 것을 방지한다
      final totalBoxes = parsedData.isEmpty ? 1 : parsedData.length;
      var processedBoxes = 0;
      for (final entry in parsedData.entries) {
        try {
          await _cache.clearBox(entry.key);
          for (final item in entry.value) {
            await _cache.put(entry.key, item.key, item.value);
          }
        } catch (e) {
          developer.log(
            '[BackupService] 복원 중 박스 쓰기 실패: ${entry.key} - $e',
            name: 'backup',
          );
          failedBoxes.add(entry.key);
        }
        processedBoxes++;
        // 진행률: 60% ~ 95% (데이터 복원 구간)
        onProgress
            ?.call(0.6 + (0.35 * processedBoxes / totalBoxes));
      }

      if (failedBoxes.isNotEmpty) {
        return BackupResult.failure(
          '일부 데이터 복원에 실패했습니다: ${failedBoxes.join(', ')}',
        );
      }

      onProgress?.call(1.0);
      return BackupResult.success();
    } catch (e, st) {
      // 내부 예외 상세를 사용자에게 노출하지 않는다 (보안)
      developer.log('[BackupService] 복원 실패: $e',
          name: 'backup', error: e, stackTrace: st);
      return BackupResult.failure('복원 중 오류가 발생했습니다. 네트워크 연결을 확인해주세요.');
    }
  }

  // ─── 내부 헬퍼 ───────────────────────────────────────────────────────────
  /// 새 백업 업로드 성공 후 기존(이전) 백업 파일들을 삭제한다
  /// 최신 파일 1개를 남기고 나머지를 정리한다
  /// 삭제 실패 시에도 새 백업은 이미 업로드되었으므로 데이터 소실이 없다
  Future<void> _deleteOldBackups(drive.DriveApi driveApi) async {
    try {
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        orderBy: 'modifiedTime desc',
        $fields: 'files(id)',
      );

      final files = fileList.files;
      if (files != null && files.length > 1) {
        // 최신 파일(인덱스 0)을 제외하고 나머지 기존 파일을 삭제한다
        for (int i = 1; i < files.length; i++) {
          final fileId = files[i].id;
          if (fileId != null) {
            await driveApi.files.delete(fileId);
          }
        }
      }
    } catch (e, st) {
      // 기존 파일 삭제 실패는 새 백업에 영향을 주지 않는다 (중복 파일만 남음)
      developer.log(
        '[BackupService] 기존 백업 삭제 실패 (무시): $e',
        name: 'backup',
        error: e,
        stackTrace: st,
      );
    }
  }
}
