// F1: 홈 대시보드 다가오는 일정 아이템 행 위젯
// 투두: 체크박스 + 색상바 + 제목 + 시간 / Google: 'G' 뱃지 + 색상바 + 제목 + 시간
// 일반 이벤트: 색상바 + 제목 + 시간 (표시만)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../providers/home_provider.dart';
import '../../../todo/providers/todo_provider.dart';

/// 다가오는 일정 아이템 행 위젯
class UpcomingEventItemRow extends ConsumerStatefulWidget {
  final UpcomingEventItem item;
  const UpcomingEventItemRow({super.key, required this.item});

  @override
  ConsumerState<UpcomingEventItemRow> createState() => _State();
}

class _State extends ConsumerState<UpcomingEventItemRow>
    with SingleTickerProviderStateMixin {
  AnimationController? _bc;
  Animation<double>? _ba;

  @override
  void initState() {
    super.initState();
    if (widget.item.isTodoEvent) {
      _bc = AnimationController(duration: AppAnimation.slow, vsync: this);
      _ba = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.02), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 30),
      ]).animate(CurvedAnimation(parent: _bc!, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() { _bc?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.item.isTodoEvent ? () {
        if (!MediaQuery.disableAnimationsOf(context)) _bc?.forward(from: 0.0);
        ref.read(toggleTodoProvider)(widget.item.id, !widget.item.isCompleted);
      } : null,
      behavior: widget.item.isTodoEvent
          ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      child: _ba != null
          ? ScaleTransition(scale: _ba!, child: _buildContent(context))
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final color = ColorTokens.eventColor(widget.item.colorIndex);
    return AnimatedOpacity(
      opacity: widget.item.isCompleted ? 0.50 : 1.0,
      duration: AppAnimation.textFade, curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.mdLg),
        child: Row(
          children: [
            // 투두: 빨간색 체크박스
            if (widget.item.isTodoEvent) ...[
              _buildCheckbox(context), const SizedBox(width: AppSpacing.md),
            ],
            // Google 이벤트: 'G' 뱃지
            if (widget.item.isGoogleEvent) ...[
              _buildGoogleBadge(), const SizedBox(width: AppSpacing.sm),
            ],
            // 색상 인디케이터 바
            Container(
              width: AppLayout.colorBarWidth, height: AppLayout.colorBarHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // 제목 (완료 시 빨간펜 취소선)
            Expanded(
              child: AnimatedStrikethrough(
                text: widget.item.title,
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimary,
                ),
                isActive: widget.item.isCompleted,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _buildTimeLabel(context),
          ],
        ),
      ),
    );
  }

  /// 투두 체크박스 (빨간색 스타일)
  Widget _buildCheckbox(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.slow, curve: Curves.easeInOut,
      width: AppLayout.checkboxMd, height: AppLayout.checkboxMd,
      decoration: BoxDecoration(
        color: widget.item.isCompleted
            ? ColorTokens.error.withValues(alpha: 0.20) : ColorTokens.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: widget.item.isCompleted
              ? ColorTokens.error
              : context.themeColors.textPrimaryWithAlpha(0.50),
          width: AppLayout.borderThick,
        ),
      ),
      child: AnimatedOpacity(
        opacity: widget.item.isCompleted ? 1.0 : 0.0,
        duration: AppAnimation.slow, curve: Curves.easeInOut,
        child: Icon(Icons.check, color: ColorTokens.error, size: AppSpacing.lg),
      ),
    );
  }

  /// Google 이벤트 'G' 뱃지 (소형 원형 마크)
  Widget _buildGoogleBadge() {
    return Container(
      width: AppLayout.iconSm, height: AppLayout.iconSm,
      decoration: BoxDecoration(
        color: ColorTokens.googleBrand.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text('G', style: AppTypography.captionSm.copyWith(
          color: ColorTokens.googleBrand,
          fontWeight: AppTypography.weightBold, fontSize: 8,
        )),
      ),
    );
  }

  /// 시간 라벨 (시계 아이콘 + 시간 텍스트)
  Widget _buildTimeLabel(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time_rounded, size: AppLayout.iconSm,
          color: context.themeColors.textPrimaryWithAlpha(0.55)),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(widget.item.timeLabel,
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.55)),
            overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ],
    );
  }
}
