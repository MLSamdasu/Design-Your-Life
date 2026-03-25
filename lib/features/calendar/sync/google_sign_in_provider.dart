// C0.CalSync: Google Sign-In 및 Calendar 서비스 인스턴스 Provider
// AuthService의 GoogleSignIn 인스턴스를 공유하여 토큰/스코프 불일치를 방지한다.
// GoogleCalendarService에 GoogleSignIn을 주입하여 생성한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/auth/auth_provider.dart';
import 'google_calendar_service.dart';

// ─── GoogleSignIn Provider ─────────────────────────────────────────────────

/// GoogleSignIn 인스턴스 Provider (AuthService 인스턴스를 공유)
/// 별도 인스턴스를 생성하면 토큰/스코프 불일치가 발생할 수 있으므로
/// AuthService가 관리하는 단일 GoogleSignIn 인스턴스를 재사용한다
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.googleSignIn;
});

// ─── GoogleCalendarService Provider ────────────────────────────────────────

/// Google Calendar 서비스 Provider
/// googleSignInProvider의 GoogleSignIn 인스턴스를 주입받아 생성한다
final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  final googleSignIn = ref.watch(googleSignInProvider);
  return GoogleCalendarService(googleSignIn);
});
