// C0.CalSync: Google Calendar API 읽기 서비스
// Google Sign-In 인증 토큰을 사용하여 Calendar API v3를 호출한다.
// 읽기 전용: events.list만 호출하며, 쓰기 작업은 수행하지 않는다.
// 점진적 스코프 요청 방식: 사용자가 설정에서 연동을 켤 때만 Calendar 스코프를 요청한다.
// 입력: GoogleSignIn 인스턴스 (인증된 상태)
// 출력: List<GoogleCalendarEvent> (Google Calendar 이벤트 목록)
import 'dart:developer' as developer;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import '../../../core/auth/auth_service.dart';
import 'google_calendar_event.dart';

/// Google Calendar API 서비스 (읽기 전용)
/// GoogleSignIn 인스턴스를 통해 인증된 HTTP 클라이언트를 획득하고
/// Calendar API v3의 events.list 엔드포인트를 호출한다
class GoogleCalendarService {
  final GoogleSignIn _googleSignIn;

  const GoogleCalendarService(this._googleSignIn);

  /// Google Calendar 읽기 전용 OAuth 스코프
  static const String _calendarReadScope =
      'https://www.googleapis.com/auth/calendar.readonly';

  /// Calendar API 접근 권한을 요청한다
  /// 설정 화면에서 "Google Calendar 연동"을 켤 때 호출한다.
  /// 이미 승인된 스코프는 사용자 개입 없이 즉시 true를 반환한다.
  /// [반환값]: 스코프 승인 여부
  Future<bool> requestAccess() async {
    // Google Sign-In 미지원 플랫폼(Windows 등)에서 크래시를 방지한다
    if (!AuthService.isAuthSupported) return false;
    try {
      final granted = await _googleSignIn.requestScopes([_calendarReadScope]);
      return granted;
    } catch (e, stack) {
      // 스코프 요청 중 오류 발생 시 로그 기록 후 false 반환 (사용자 취소 포함)
      developer.log(
        '[GoogleCalendarService] requestAccess 실패: $e',
        name: 'CalendarSync',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// 현재 Calendar API 스코프가 승인되었는지 확인한다
  /// 앱 재시작 후 기존 설정 복원 시 실제 권한 상태를 확인하는 데 사용한다
  Future<bool> hasAccess() async {
    final currentUser = _googleSignIn.currentUser;
    // 로그인된 Google 계정이 없으면 접근 불가
    if (currentUser == null) return false;
    try {
      // requestScopes는 이미 승인된 스코프면 사용자 인터랙션 없이 즉시 true 반환한다
      return await _googleSignIn.requestScopes([_calendarReadScope]);
    } catch (e, stack) {
      // 스코프 확인 실패 시 로그 기록 후 false 반환
      developer.log(
        '[GoogleCalendarService] hasAccess 확인 실패: $e',
        name: 'CalendarSync',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// 특정 월의 Google Calendar 이벤트를 가져온다
  /// [month]: 조회할 월 (해당 월의 1일~말일 범위)
  /// [반환값]: Google Calendar 이벤트 목록
  /// [예외]: 인증 실패, 스코프 미승인, 네트워크 오류 시 예외 발생
  Future<List<GoogleCalendarEvent>> fetchEventsForMonth(DateTime month) async {
    // Google Sign-In 미지원 플랫폼(Windows 등)에서 크래시를 방지한다
    if (!AuthService.isAuthSupported) return [];
    // 1. extension_google_sign_in_as_googleapis_auth를 사용하여
    //    GoogleSignIn에서 인증된 HTTP 클라이언트를 가져온다
    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient == null) {
      throw Exception('Google 인증 클라이언트를 가져올 수 없습니다. 로그인 상태를 확인해주세요.');
    }

    try {
      // 2. Calendar API v3 클라이언트 생성
      final calendarApi = gcal.CalendarApi(httpClient);

      // 3. 조회 월 범위 계산 (UTC로 변환하여 API에 전달)
      final monthStart = DateTime(month.year, month.month, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 1);

      // 4. primary 캘린더의 이벤트 목록 조회
      // singleEvents: true → 반복 이벤트를 개별 인스턴스로 전개
      // orderBy: 'startTime' → 시작 시간 오름차순 정렬
      final events = await calendarApi.events.list(
        'primary',
        timeMin: monthStart.toUtc(),
        timeMax: monthEnd.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 250, // 월간 이벤트 최대 250개 제한
      );

      // 5. Google Event → GoogleCalendarEvent 변환 (제목 없는 이벤트 제외)
      return (events.items ?? [])
          .where((event) => event.summary != null && event.summary!.isNotEmpty)
          .map(_convertEvent)
          .toList();
    } finally {
      // HTTP 클라이언트는 반드시 닫아 리소스를 해제한다
      httpClient.close();
    }
  }

  /// Google Calendar Event를 앱 내부 GoogleCalendarEvent로 변환한다
  /// dateTime: 시간 포함 이벤트 / date: 종일 이벤트를 구분하여 처리한다
  GoogleCalendarEvent _convertEvent(gcal.Event event) {
    final start = event.start;
    final end = event.end;

    DateTime startDate;
    int? startHour;
    int? startMinute;

    if (start?.dateTime != null) {
      // 시간 포함 이벤트: 로컬 타임존으로 변환하여 시/분 추출
      final dt = start!.dateTime!.toLocal();
      startDate = DateTime(dt.year, dt.month, dt.day);
      startHour = dt.hour;
      startMinute = dt.minute;
    } else if (start?.date != null) {
      // 종일 이벤트: 날짜만 사용, 시간 정보 없음
      startDate = start!.date!;
    } else {
      // 시작 날짜 정보가 없는 경우 현재 시간으로 폴백한다
      startDate = DateTime.now();
    }

    DateTime? endDate;
    int? endHour;
    int? endMinute;

    if (end?.dateTime != null) {
      final dt = end!.dateTime!.toLocal();
      // 종료 날짜는 시작 날짜와 다를 수 있으므로 별도 저장
      endDate = DateTime(dt.year, dt.month, dt.day);
      endHour = dt.hour;
      endMinute = dt.minute;
    } else if (end?.date != null) {
      // 종일 이벤트의 종료일: Google API는 exclusive end date를 반환한다
      // 예: 1월 1일 종일 이벤트의 end.date = 1월 2일
      // 따라서 1일을 빼서 실제 종료일로 조정한다
      endDate = end!.date!.subtract(const Duration(days: 1));
      // 조정 후 시작일과 동일하면 종료일 필드를 null로 처리 (단일 종일 이벤트)
      if (endDate == startDate) endDate = null;
    }

    return GoogleCalendarEvent(
      id: event.id ?? '',
      title: event.summary ?? '',
      startDate: startDate,
      endDate: endDate,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      location: event.location,
      description: event.description,
    );
  }
}
