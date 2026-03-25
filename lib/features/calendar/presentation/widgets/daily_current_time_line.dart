// F2 위젯: DailyCurrentTimeLine - 현재 시간 빨간 가로선 (AC-CL-03)
// 빨간 원형 점에 펄스 스케일 애니메이션을 적용한다
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 현재 시간 빨간 가로선 (AC-CL-03)
/// 빨간 원형 점에 펄스 스케일 애니메이션을 적용한다
class DailyCurrentTimeLine extends StatelessWidget {
  /// 현재 시각
  final DateTime now;

  /// 1시간당 픽셀 높이
  final double hourHeight;

  /// 펄스 애니메이션 (외부에서 주입)
  final Animation<double> pulseAnimation;

  const DailyCurrentTimeLine({
    super.key,
    required this.now,
    required this.hourHeight,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final topOffset =
        now.hour * hourHeight + now.minute * (hourHeight / 60);
    // 접근성: 모션 축소 설정 시 펄스 정지
    final disableMotion = MediaQuery.disableAnimationsOf(context);

    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // 빨간 원형 점 — 펄스 스케일 애니메이션
          disableMotion
              ? _buildStaticDot()
              : ScaleTransition(
                  scale: pulseAnimation,
                  child: _buildStaticDot(),
                ),
          Expanded(
            child: Container(
              height: AppLayout.lineHeightMedium,
              color: ColorTokens.error,
            ),
          ),
        ],
      ),
    );
  }

  /// 빨간 원형 점 (정적, 애니메이션 없음)
  Widget _buildStaticDot() {
    return Container(
      width: AppSpacing.md,
      height: AppSpacing.md,
      decoration: const BoxDecoration(
        color: ColorTokens.error,
        shape: BoxShape.circle,
      ),
    );
  }
}
