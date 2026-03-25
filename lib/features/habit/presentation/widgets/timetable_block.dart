// F4 위젯: TimetableBlock — 시간표 내 루틴 블록 (배치 단위)
// blockLeft/blockWidth로 겹치는 루틴을 나란히 배치한다
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/models/routine.dart';

/// 루틴 블록 (시간표 내 배치 단위)
/// blockLeft/blockWidth로 겹치는 루틴을 나란히 배치한다
class TimetableBlock extends StatelessWidget {
  final Routine routine;
  final int startHour;
  final double hh;
  final bool isZoomed;
  final double blockLeft;
  final double blockWidth;

  const TimetableBlock({
    required this.routine,
    required this.startHour,
    required this.hh,
    required this.isZoomed,
    required this.blockLeft,
    required this.blockWidth,
    super.key,
  });

  /// 배경색 밝기에 따라 대비가 높은 텍스트 색상을 반환한다
  /// WCAG 기준: 밝은 배경 -> 어두운 텍스트, 어두운 배경 -> 흰색 텍스트
  static Color contrastTextColor(Color bgColor) {
    // 상대 휘도 계산 (W3C 공식)
    final luminance = bgColor.computeLuminance();
    // 임계값 0.4: 밝은 이벤트 색상(노랑, 연두 등)에서 어두운 텍스트로 전환
    return luminance > 0.4
        ? ColorTokens.gray900 // 어두운 남색 대체 (밝은 배경용)
        : ColorTokens.white; // 흰색 (어두운 배경용)
  }

  @override
  Widget build(BuildContext context) {
    final sm = routine.startTime.hour * 60 + routine.startTime.minute;
    final em = routine.endTime.hour * 60 + routine.endTime.minute;
    final dur = (em - sm).clamp(15, 1440).toDouble();
    final top = (sm - startHour * 60) / 60 * hh;
    final h = dur / 60 * hh;
    if (top + h <= 0) return const SizedBox.shrink();

    final color = ColorTokens.eventColor(routine.colorIndex);
    // 블록 배경색 기준 대비 텍스트 색상 — 밝은 이벤트 색상에서도 가독성 보장
    final textColor = contrastTextColor(color);
    return Positioned(
      top: top.clamp(0.0, double.infinity),
      left: blockLeft,
      width: blockWidth,
      height: h.clamp(12.0, double.infinity),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 루틴 이름 — 배경 밝기 기반 대비 텍스트 색상 (6개 테마 전부 대응)
              Text(
                routine.name,
                style: (isZoomed
                        ? AppTypography.bodyMd
                        : AppTypography.captionSm)
                    .copyWith(
                  color: textColor,
                  fontWeight: AppTypography.weightSemiBold,
                  height: 1.2,
                ),
                maxLines: isZoomed ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
              // 시간 정보 — 블록 높이 30px 이상일 때 표시, 약간 투명도를 낮춰 보조 텍스트 역할
              if (h > 30) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${routine.startTime.hour.toString().padLeft(2, '0')}:'
                  '${routine.startTime.minute.toString().padLeft(2, '0')}'
                  ' ~ '
                  '${routine.endTime.hour.toString().padLeft(2, '0')}:'
                  '${routine.endTime.minute.toString().padLeft(2, '0')}',
                  style: AppTypography.captionSm.copyWith(
                    color: textColor.withValues(alpha: 0.85),
                    height: 1.2,
                  ),
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
