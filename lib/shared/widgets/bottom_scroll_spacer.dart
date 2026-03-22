// 공용 위젯: BottomScrollSpacer
// 스크롤 최하단에 화면 높이의 절반만큼 여백을 추가하여
// 마지막 콘텐츠를 화면 중앙까지 올릴 수 있도록 한다.
// 모든 탭/화면의 스크롤 뷰 하단에 배치한다.
import 'package:flutter/material.dart';

/// 스크롤 하단 여백 위젯
/// 화면 높이의 절반(50%)을 빈 공간으로 채워
/// 최하단 콘텐츠를 화면 중앙까지 스크롤할 수 있게 한다
class BottomScrollSpacer extends StatelessWidget {
  /// 화면 높이 대비 비율 (기본 0.5 = 50%)
  final double ratio;

  const BottomScrollSpacer({super.key, this.ratio = 0.5});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(height: screenHeight * ratio);
  }

  /// ListView 등에서 padding으로 사용할 때 동적 하단 여백을 계산한다
  static double height(BuildContext context, {double ratio = 0.5}) {
    return MediaQuery.of(context).size.height * ratio;
  }
}
