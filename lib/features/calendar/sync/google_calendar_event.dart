// C0.CalSync: Google Calendar 동기화 상태 + 이벤트 데이터 모델
// GoogleCalendarService에서 분리하여 SRP를 준수한다.
// CalendarSyncStatus: 동기화 UI 상태를 표현하는 열거형
// GoogleCalendarEvent: Google Calendar API 응답을 앱 내부 형태로 변환한 DTO

/// Google Calendar 동기화 상태
enum CalendarSyncStatus {
  /// 연동되지 않음 (스코프 미요청 또는 사용자 비활성화)
  notConnected,

  /// 연동됨 (스코프 승인 완료)
  connected,

  /// 동기화 진행 중
  syncing,

  /// 동기화 실패 (권한 거부 또는 네트워크 오류)
  error,
}

/// Google Calendar 이벤트 (API 응답에서 필요한 필드만 추출)
/// CalendarEvent(뷰 모델) 변환 전 중간 데이터 객체로 사용한다
class GoogleCalendarEvent {
  /// Google Calendar 이벤트 고유 ID
  final String id;

  /// 이벤트 제목 (summary 필드)
  final String title;

  /// 이벤트 시작 날짜
  final DateTime startDate;

  /// 이벤트 종료 날짜 (종일 이벤트 또는 범위 이벤트에서 사용)
  final DateTime? endDate;

  /// 시작 시간 (시) - 종일 이벤트이면 null
  final int? startHour;

  /// 시작 시간 (분) - 종일 이벤트이면 null
  final int? startMinute;

  /// 종료 시간 (시) - 종일 이벤트이면 null
  final int? endHour;

  /// 종료 시간 (분) - 종일 이벤트이면 null
  final int? endMinute;

  /// 이벤트 장소 (location 필드)
  final String? location;

  /// 이벤트 설명 (description 필드)
  final String? description;

  const GoogleCalendarEvent({
    required this.id,
    required this.title,
    required this.startDate,
    this.endDate,
    this.startHour,
    this.startMinute,
    this.endHour,
    this.endMinute,
    this.location,
    this.description,
  });
}
