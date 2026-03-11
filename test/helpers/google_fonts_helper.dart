// 테스트 헬퍼: GoogleFonts 테스트 환경 설정
// google_fonts 패키지가 테스트 환경에서 AssetManifest.json을 로드하지 못하는
// 문제를 방지하기 위해 HTTP 요청 비활성화 설정을 적용한다.
import 'package:google_fonts/google_fonts.dart';

/// 테스트 환경에서 GoogleFonts 네트워크 요청을 비활성화한다
/// 폰트를 다운로드하지 않고 시스템 기본 폰트로 대체한다
void setupGoogleFontsForTest() {
  GoogleFonts.config.allowRuntimeFetching = false;
}
