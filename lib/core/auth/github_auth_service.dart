// C0: GitHub Personal Access Token 인증 서비스
// flutter_secure_storage를 사용하여 GitHub PAT를 안전하게 저장/조회/삭제한다.
// GitHub API /user 엔드포인트로 토큰 유효성을 검증한다.
// 입력: GitHub PAT 문자열
// 출력: 토큰 유효성 + 사용자 정보 (username, avatarUrl)

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// GitHub 토큰 검증 결과 값 객체
class GitHubValidationResult {
  /// 토큰 유효 여부 (UI 호환 별칭: isSuccess)
  final bool isValid;

  /// GitHub 사용자 이름 (유효한 경우 non-null)
  final String? username;

  /// GitHub 프로필 이미지 URL (유효한 경우 non-null)
  final String? avatarUrl;

  /// 오류 메시지 (실패 시 non-null)
  final String? errorMessage;

  /// UI 호환 별칭 — isValid와 동일
  bool get isSuccess => isValid;

  const GitHubValidationResult({
    required this.isValid,
    this.username,
    this.avatarUrl,
    this.errorMessage,
  });

  /// 유효하지 않은 토큰 결과
  const GitHubValidationResult.invalid({String? message})
      : isValid = false,
        username = null,
        avatarUrl = null,
        errorMessage = message ?? '유효하지 않은 토큰입니다';
}

/// GitHub PAT 기반 인증 서비스 (C0)
/// flutter_secure_storage로 토큰을 암호화 저장하고
/// GitHub API로 토큰 유효성을 검증한다
class GitHubAuthService {
  /// 시큐어 스토리지 인스턴스
  final FlutterSecureStorage _storage;

  /// 시큐어 스토리지 내 토큰 저장 키
  static const _tokenKey = 'github_backup_token';

  /// GitHub API 기본 URL
  static const _apiBase = 'https://api.github.com';

  GitHubAuthService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// GitHub PAT를 시큐어 스토리지에 암호화 저장한다
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    developer.log('[GitHubAuth] 토큰 저장 완료', name: 'github');
  }

  /// 저장된 GitHub PAT를 조회한다 (없으면 null)
  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  /// 저장된 GitHub PAT를 삭제한다
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    developer.log('[GitHubAuth] 토큰 삭제 완료', name: 'github');
  }

  /// GitHub API로 토큰 유효성을 검증한다
  /// GET /user 엔드포인트를 호출하여 사용자 정보를 반환한다
  /// 401 → invalid, 네트워크 오류 → throw
  Future<GitHubValidationResult> validateToken(String token) async {
    final uri = Uri.parse('$_apiBase/user');
    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode == 401 || response.statusCode == 403) {
      developer.log('[GitHubAuth] 토큰 검증 실패: ${response.statusCode}',
          name: 'github');
      return const GitHubValidationResult.invalid();
    }

    if (response.statusCode != 200) {
      throw Exception('GitHub API 오류: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return GitHubValidationResult(
      isValid: true,
      username: body['login'] as String?,
      avatarUrl: body['avatar_url'] as String?,
    );
  }

  /// 토큰을 검증하고 유효하면 시큐어 스토리지에 저장한다
  /// UI에서 연결 버튼 클릭 시 호출하는 편의 메서드
  Future<GitHubValidationResult> validateAndSaveToken(String token) async {
    try {
      final result = await validateToken(token);
      if (result.isValid) {
        await saveToken(token);
      }
      return result;
    } catch (e) {
      developer.log('[GitHubAuth] validateAndSaveToken 실패: $e',
          name: 'github');
      return GitHubValidationResult.invalid(
          message: '네트워크 오류가 발생했습니다. 다시 시도해주세요.');
    }
  }

  /// GitHub API 공통 헤더를 생성한다
  static Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    };
  }
}
