// C0: GitHub 인증 Riverpod Provider
// GitHubAuthService 싱글톤, 토큰 존재 여부, 사용자 이름 등
// GitHub 백업 기능에 필요한 인증 상태 Provider를 정의한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'github_auth_service.dart';

// ─── GitHubAuthService 싱글톤 ─────────────────────────────────────────────
/// GitHubAuthService 싱글톤 Provider
final githubAuthServiceProvider = Provider<GitHubAuthService>((ref) {
  return GitHubAuthService();
});

/// UI 호환 별칭 (camelCase GitHub)
final gitHubAuthServiceProvider = githubAuthServiceProvider;

// ─── 데이터 버전 (반응성 트리거) ──────────────────────────────────────────
/// 토큰 저장/삭제 시 증가시켜 관련 Provider를 갱신하는 카운터
final githubDataVersionProvider = StateProvider<int>((ref) => 0);

/// UI 호환 별칭
final gitHubAuthVersionProvider = githubDataVersionProvider;

// ─── 저장된 토큰 FutureProvider ─────────────────────────────────────────────
/// 시큐어 스토리지에서 GitHub PAT를 비동기로 읽는다
final githubTokenProvider = FutureProvider<String?>((ref) {
  ref.watch(githubDataVersionProvider);
  final service = ref.watch(githubAuthServiceProvider);
  return service.getToken();
});

// ─── 연결 여부 (파생 Provider) ────────────────────────────────────────────
/// 토큰이 저장되어 있으면 연결된 것으로 판단한다
final isGithubConnectedProvider = Provider<bool>((ref) {
  final tokenAsync = ref.watch(githubTokenProvider);
  return tokenAsync.valueOrNull != null;
});

/// UI 호환 별칭
final isGitHubConnectedProvider = isGithubConnectedProvider;

// ─── 사용자 이름 ──────────────────────────────────────────────────────────
/// 토큰 검증 성공 시 설정되는 GitHub 사용자 이름
final githubUsernameProvider = StateProvider<String?>((ref) => null);

/// UI 호환 별칭
final gitHubUsernameProvider = githubUsernameProvider;

// ─── 토큰 검증 진행 중 상태 ────────────────────────────────────────────────
/// UI에서 토큰 검증 로딩 표시에 사용한다
final isGitHubValidatingProvider = StateProvider<bool>((ref) => false);
