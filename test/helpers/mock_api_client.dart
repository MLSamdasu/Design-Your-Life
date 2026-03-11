// Mock Supabase 헬퍼: Supabase 의존성 없이 Repository 계층을 테스트한다.
// Supabase 마이그레이션 완료 후 Mock 클래스를 제공한다.
// 실제 Supabase 호출 대신 테스트 더블을 사용할 때 참조한다.

/// Supabase Mock 호출 기록
/// 테스트에서 어떤 테이블/메서드가 호출되었는지 추적한다
class MockSupabaseCall {
  final String table;
  final String method;
  final dynamic data;
  final Map<String, dynamic>? filters;

  const MockSupabaseCall(this.table, this.method, {this.data, this.filters});

  @override
  String toString() => 'MockSupabaseCall($method on $table, data: $data)';
}
