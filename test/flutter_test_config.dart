// 전역 테스트 설정
// GoogleFonts 네트워크/에셋 로딩을 비활성화하여 테스트 환경에서
// AssetManifest 미존재 오류를 방지한다.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // GoogleFonts 런타임 폰트 다운로드 비활성화
  GoogleFonts.config.allowRuntimeFetching = false;

  // 빈 AssetManifest를 주입하여 로딩 에러 방지
  // Flutter 3.38+에서는 AssetManifest.bin(StandardMessageCodec)을 사용하므로
  // .json과 .bin 모두 처리해야 한다.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
    final String key = utf8.decode(message!.buffer.asUint8List());
    if (key == 'AssetManifest.json') {
      // AssetManifest.json 요청에 대해 빈 JSON 반환
      return ByteData.view(
        Uint8List.fromList(utf8.encode('{}')).buffer,
      );
    }
    if (key == 'AssetManifest.bin') {
      // AssetManifest.bin 요청에 대해 빈 맵을 StandardMessageCodec으로 인코딩하여 반환
      return const StandardMessageCodec().encodeMessage(<String, Object>{});
    }
    return null;
  });

  await testMain();
}
