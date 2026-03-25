// C0: Google Drive API 헬퍼
// Drive API 클라이언트 생성, 파일 업로드, 다운로드, 삭제 등
// Google Drive appdata 폴더에 대한 저수준 조작을 담당한다.
// BackupService가 이 헬퍼를 통해 Drive 파일을 조작한다.

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// Google Drive appdata 백업 파일 이름
const backupFileName = 'dyl_backup.json';

/// Google Drive appdata 폴더에 대한 저수준 API 조작을 담당한다
class DriveApiHelper {
  final GoogleSignIn _googleSignIn;

  DriveApiHelper({required GoogleSignIn googleSignIn})
      : _googleSignIn = googleSignIn;

  /// 인증된 HTTP 클라이언트를 통해 Drive API 인스턴스를 생성한다
  Future<drive.DriveApi?> getDriveApi() async {
    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient == null) return null;
    return drive.DriveApi(httpClient);
  }

  /// 백업 JSON 데이터를 appdata 폴더에 업로드한다
  /// 업로드-우선 전략: 새 파일을 먼저 올린 뒤 기존 파일을 삭제하여
  /// 업로드 실패 시 백업 소실을 방지한다
  Future<void> uploadBackupFile(
    drive.DriveApi driveApi,
    String jsonString,
  ) async {
    final fileMetadata = drive.File()
      ..name = backupFileName
      ..parents = ['appDataFolder'];

    // UTF-8 인코딩을 한 번만 수행하여 메모리 이중 할당을 방지한다
    final bytes = utf8.encode(jsonString);
    final mediaStream = Stream.value(bytes);
    final media = drive.Media(mediaStream, bytes.length);

    await driveApi.files.create(
      fileMetadata,
      uploadMedia: media,
    );
  }

  /// appdata 폴더에서 백업 파일을 검색하여 다운로드한다
  /// 파일이 없으면 null을 반환한다
  /// 다운로드 실패 시 오류 메시지 문자열을 반환한다
  Future<DriveDownloadResult> downloadBackupFile(
    drive.DriveApi driveApi,
  ) async {
    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$backupFileName'",
      $fields: 'files(id, name, modifiedTime)',
    );

    final files = fileList.files;
    if (files == null || files.isEmpty) {
      return DriveDownloadResult.failure('백업 파일이 없습니다');
    }

    // Drive API가 id를 누락할 수 있으므로 방어 처리한다
    final fileId = files.first.id;
    if (fileId == null) {
      return DriveDownloadResult.failure('백업 파일 ID를 가져올 수 없습니다');
    }

    // Drive API 응답을 안전하게 타입 검사한다 (as 캐스트 대신 is 검사)
    final rawResponse = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );
    if (rawResponse is! drive.Media) {
      return DriveDownloadResult.failure('백업 파일을 다운로드할 수 없습니다');
    }

    final bytes = <int>[];
    await for (final chunk in rawResponse.stream) {
      bytes.addAll(chunk);
    }
    final jsonString = utf8.decode(bytes);

    return DriveDownloadResult.success(jsonString);
  }

  /// 새 백업 업로드 성공 후 기존(이전) 백업 파일들을 삭제한다
  /// 최신 파일 1개를 남기고 나머지를 정리한다
  /// 삭제 실패 시에도 새 백업은 이미 업로드되었으므로 데이터 소실이 없다
  Future<void> deleteOldBackups(drive.DriveApi driveApi) async {
    try {
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$backupFileName'",
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
        '[DriveApiHelper] 기존 백업 삭제 실패 (무시): $e',
        name: 'backup',
        error: e,
        stackTrace: st,
      );
    }
  }
}

/// Drive 파일 다운로드 결과
class DriveDownloadResult {
  /// 다운로드된 JSON 문자열 (성공 시 non-null)
  final String? jsonString;

  /// 오류 메시지 (실패 시 non-null)
  final String? errorMessage;

  /// 성공 여부
  bool get isSuccess => jsonString != null;

  const DriveDownloadResult._({this.jsonString, this.errorMessage});

  /// 성공 결과 팩토리
  factory DriveDownloadResult.success(String json) {
    return DriveDownloadResult._(jsonString: json);
  }

  /// 실패 결과 팩토리
  factory DriveDownloadResult.failure(String message) {
    return DriveDownloadResult._(errorMessage: message);
  }
}
