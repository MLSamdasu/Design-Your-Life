// F4 위젯: TimetableTimeAxis — 시간 레이블 열
import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 시간 레이블 열
class TimetableTimeAxis extends StatelessWidget {
  final int startHour;
  final int endHour;
  final double hh;
  final double width;

  const TimetableTimeAxis({
    required this.startHour,
    required this.endHour,
    required this.hh,
    required this.width,
    super.key,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Stack(
          children: List.generate(
            endHour - startHour,
            (i) => Positioned(
              top: i * hh - 6,
              left: 0,
              width: width,
              child: Text(
                '${startHour + i}',
                style: AppTypography.captionSm.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.5),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
      );
}
