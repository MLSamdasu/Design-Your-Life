// 공유 모델: UserProfile
// Hive userProfileBox에 저장되는 사용자 프로필 모델이다.
// 필드: id (uuid), display_name, email, photo_url, is_dark_mode,
//   schema_version, total_xp, created_at, updated_at
import '../../core/utils/date_parser.dart';
import '../../core/error/app_exception.dart';

/// 사용자 프로필 모델
/// Hive userProfileBox에 저장된다
class UserProfile {
  /// 사용자 UID
  final String uid;

  /// 표시 이름 (최대 50자)
  final String displayName;

  /// 이메일 주소
  final String email;

  /// 프로필 사진 URL (선택)
  final String? photoUrl;

  /// 다크 모드 사용 여부
  final bool isDarkMode;

  /// 데이터 마이그레이션 버전 (초기값 1)
  final int schemaVersion;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.isDarkMode = false,
    this.schemaVersion = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Map 데이터에서 UserProfile 객체를 생성한다
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    try {
      return UserProfile(
        uid: (map['id'] ?? map['uid'] ?? '').toString(),
        displayName: (map['display_name'] ?? map['displayName'] ?? '') as String,
        email: (map['email'] ?? '') as String,
        photoUrl: (map['photo_url'] ?? map['photoUrl']) as String?,
        isDarkMode: map['is_dark_mode'] as bool? ??
            map['isDarkMode'] as bool? ??
            false,
        // JSON 역직렬화 시 num → int 안전 변환 (int/double 모두 처리)
        schemaVersion: (map['schema_version'] as num?)?.toInt() ??
            (map['schemaVersion'] as num?)?.toInt() ??
            1,
        createdAt: DateParser.parse(
            map['created_at'] ?? map['createdAt'] ?? DateTime.now()),
        updatedAt: DateParser.parse(
            map['updated_at'] ?? map['updatedAt'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'UserProfile 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// UPDATE용 Map (id 제외)
  Map<String, dynamic> toUpdateMap() {
    return {
      'display_name': displayName,
      'email': email,
      'photo_url': photoUrl,
      'is_dark_mode': isDarkMode,
      'schema_version': schemaVersion,
    };
  }

  /// 레거시 호환: 기존 toMap 호출부를 위한 별칭
  Map<String, dynamic> toMap() => toUpdateMap();

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    bool? isDarkMode,
    int? schemaVersion,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
