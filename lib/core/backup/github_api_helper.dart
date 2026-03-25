// C0: GitHub API 헬퍼
// GitHub REST API를 통해 비공개 레포지토리 생성, 백업 파일 업로드/다운로드를 처리한다.
// BackupService가 이 헬퍼를 통해 GitHub 레포지토리를 조작한다.
// DriveApiHelper와 동일한 패턴으로 설계하여 일관성을 유지한다.

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

/// GitHub 백업용 레포지토리 이름
const githubBackupRepoName = 'dyl-backup';

/// GitHub 백업 파일 경로
const githubBackupFilePath = 'backup.json';

/// GitHub REST API 저수준 조작을 담당한다
class GitHubApiHelper {
  /// GitHub Personal Access Token
  final String _token;

  /// GitHub API 기본 URL
  static const _baseUrl = 'https://api.github.com';

  GitHubApiHelper({required String token}) : _token = token;

  /// 공통 HTTP 헤더를 생성한다
  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      };

  /// 백업용 비공개 레포지토리를 생성하거나 기존 레포를 반환한다
  ///
  /// 1. GET /user/repos로 기존 레포 검색
  /// 2. 존재하면 full_name 반환
  /// 3. 없으면 POST /user/repos로 비공개 레포 생성
  Future<String> createOrGetRepo() async {
    // 기존 레포지토리 검색
    final existingRepo = await _findExistingRepo();
    if (existingRepo != null) return existingRepo;

    // 새 비공개 레포지토리 생성
    return _createPrivateRepo();
  }

  /// 백업 JSON 데이터를 레포지토리에 업로드한다
  ///
  /// 기존 파일이 있으면 SHA를 포함하여 업데이트한다
  /// 없으면 새로 생성한다
  Future<void> uploadBackup(
    String repoFullName,
    String jsonContent,
  ) async {
    // 기존 파일의 SHA 조회 (업데이트 시 필수)
    final existingSha = await _getFileSha(repoFullName);

    // Base64 인코딩
    final base64Content = base64Encode(utf8.encode(jsonContent));

    // 커밋 메시지에 타임스탬프 포함
    final timestamp = DateTime.now().toIso8601String();
    final body = <String, dynamic>{
      'message': 'backup: 자동 백업 $timestamp',
      'content': base64Content,
    };
    if (existingSha != null) {
      body['sha'] = existingSha;
    }

    final uri = Uri.parse(
      '$_baseUrl/repos/$repoFullName/contents/$githubBackupFilePath',
    );
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('백업 업로드 실패: ${response.statusCode}');
    }

    developer.log('[GitHubApiHelper] 백업 업로드 완료', name: 'backup');
  }

  /// 레포지토리에서 백업 JSON을 다운로드한다
  /// 파일이 없으면 null을 반환한다
  Future<String?> downloadBackup(String repoFullName) async {
    final uri = Uri.parse(
      '$_baseUrl/repos/$repoFullName/contents/$githubBackupFilePath',
    );
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 404) {
      developer.log('[GitHubApiHelper] 백업 파일 없음', name: 'backup');
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('백업 다운로드 실패: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = body['content'] as String?;
    if (content == null) return null;

    // GitHub API는 Base64 콘텐츠에 줄바꿈을 포함한다 — 제거 후 디코딩
    final cleanBase64 = content.replaceAll('\n', '');
    return utf8.decode(base64Decode(cleanBase64));
  }

  // ─── 내부 헬퍼 ──────────────────────────────────────────────────────────────

  /// 사용자의 레포 목록에서 dyl-backup 레포를 검색한다
  Future<String?> _findExistingRepo() async {
    final uri = Uri.parse(
      '$_baseUrl/user/repos?type=owner&per_page=100',
    );
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('레포 목록 조회 실패: ${response.statusCode}');
    }

    final repos = jsonDecode(response.body) as List<dynamic>;
    for (final repo in repos) {
      if (repo is Map<String, dynamic> &&
          repo['name'] == githubBackupRepoName) {
        final fullName = repo['full_name'] as String?;
        developer.log(
          '[GitHubApiHelper] 기존 레포 발견: $fullName',
          name: 'backup',
        );
        return fullName;
      }
    }
    return null;
  }

  /// 비공개 백업 레포지토리를 생성한다
  Future<String> _createPrivateRepo() async {
    final uri = Uri.parse('$_baseUrl/user/repos');
    final body = jsonEncode({
      'name': githubBackupRepoName,
      'private': true,
      'description': 'Design Your Life 앱 자동 백업',
      'auto_init': true,
    });

    final response = await http.post(uri, headers: _headers, body: body);

    if (response.statusCode != 201) {
      throw Exception('레포 생성 실패: ${response.statusCode}');
    }

    final repoData = jsonDecode(response.body) as Map<String, dynamic>;
    final fullName = repoData['full_name'] as String;
    developer.log(
      '[GitHubApiHelper] 새 레포 생성 완료: $fullName',
      name: 'backup',
    );
    return fullName;
  }

  /// 기존 백업 파일의 SHA를 조회한다 (업데이트 시 필수)
  /// 파일이 없으면 null을 반환한다
  Future<String?> _getFileSha(String repoFullName) async {
    final uri = Uri.parse(
      '$_baseUrl/repos/$repoFullName/contents/$githubBackupFilePath',
    );
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['sha'] as String?;
  }
}
