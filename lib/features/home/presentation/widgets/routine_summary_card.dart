// F1: 홈 대시보드 오늘의 루틴 요약 카드
// todayRoutinesProvider에서 오늘 요일의 루틴을 시간순으로 표시한다.
// 탭 시 습관/루틴 화면으로 이동한다.
// GlassCard(defaultCard variant) 사용.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../providers/home_provider.dart';
import '../../../habit/providers/routine_log_provider.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';

/// 홈 대시보드 - 오늘의 루틴 요약 카드
/// 습관/루틴 화면 진입점 역할을 한다
class RoutineSummaryCard extends ConsumerWidget {
  const RoutineSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 동기 Provider: 직접 값을 사용한다
    final summary = ref.watch(todayRoutinesProvider);

    return GlassCard(
      variant: GlassCardVariant.defaultCard,
      child: _buildContent(context, ref, summary),
    );
  }

  /// 실제 콘텐츠
  Widget _buildContent(BuildContext context, WidgetRef ref, RoutineSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 카드 헤더: 아이콘 + 제목 + 전체 보기
        Row(
          children: [
            // 루틴 아이콘 컨테이너
            Container(
              width: AppLayout.containerRoutine,
              height: AppLayout.containerRoutine,
              decoration: BoxDecoration(
                color: context.themeColors.accentWithAlpha(0.20),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: context.themeColors.accentWithAlpha(0.30),
                ),
              ),
              child: Icon(
                Icons.schedule_rounded,
                // WCAG 대비: accent 배경 위에서 테마 색상으로 고대비 확보
                color: context.themeColors.textPrimaryWithAlpha(0.8),
                size: AppLayout.iconXxl,
              ),
            ),
            const SizedBox(width: AppSpacing.xl),

            // 루틴 제목 + 개수 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘의 루틴',
                    style: AppTypography.titleLg.copyWith(
                      color: context.themeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    summary.total == 0
                        ? '오늘 예정된 루틴이 없어요'
                        : '${summary.total}개의 루틴이 예정되어 있어요',
                    style: AppTypography.bodyMd.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.70),
                    ),
                  ),
                ],
              ),
            ),

            // 습관/루틴 화면으로 이동 화살표
            GestureDetector(
              onTap: () => context.go(RoutePaths.habit),
              child: Icon(
                Icons.chevron_right_rounded,
                color: context.themeColors.textPrimaryWithAlpha(0.40),
                size: AppLayout.iconXl,
              ),
            ),
          ],
        ),

        // 루틴 목록 또는 빈 상태
        if (summary.routineItems.isEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          EmptyState(
            icon: Icons.event_repeat_rounded,
            mainText: '오늘 예정된 루틴이 없어요',
            ctaLabel: '루틴 등록하러 가기',
            onCtaTap: () => context.go(RoutePaths.habit),
            minHeight: 100,
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.xl),
          Divider(color: context.themeColors.dividerColor, height: 1),
          const SizedBox(height: AppSpacing.lg),
          // 루틴 아이템 목록 (시간순 정렬, 완료 토글 지원)
          ...summary.routineItems.map((item) {
            return _RoutineItemRow(
              item: item,
              date: DateTime.now(),
            );
          }),
        ],
      ],
    );
  }
}

/// 루틴 아이템 행 위젯
/// 체크박스(빨간 스타일) + 색상 인디케이터 + 루틴명 + 시간 범위를 표시한다
/// 탭 시 routineCompletionProvider를 참조하여 완료 토글을 수행한다
/// 스케일 바운스 애니메이션으로 탭 피드백을 제공한다
class _RoutineItemRow extends ConsumerStatefulWidget {
  final RoutinePreviewItem item;

  /// 완료 상태 조회/토글에 사용할 날짜 (보통 오늘)
  final DateTime date;

  const _RoutineItemRow({required this.item, required this.date});

  @override
  ConsumerState<_RoutineItemRow> createState() => _RoutineItemRowState();
}

class _RoutineItemRowState extends ConsumerState<_RoutineItemRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    // 스케일 바운스: CheckItem 패턴과 동일한 TweenSequence (500ms)
    _bounceController = AnimationController(
      duration: AppAnimation.slow,
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.02), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.eventColor(widget.item.colorIndex);
    final isCompleted = ref.watch(
      routineCompletionProvider((routineId: widget.item.id, date: widget.date)),
    );

    return GestureDetector(
      onTap: () {
        // Reduced Motion 확인: 접근성 설정 시 바운스 생략
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        if (!reduceMotion) {
          _bounceController.forward(from: 0.0);
        }
        // 완료 상태를 반전하여 토글한다
        ref.read(toggleRoutineLogProvider)(widget.item.id, widget.date, !isCompleted);
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: AnimatedOpacity(
          opacity: isCompleted ? 0.50 : 1.0,
          duration: AppAnimation.textFade,
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.mdLg),
            child: Row(
              children: [
                // 완료 체크박스 (빨간색 스타일, CheckItem과 동일한 애니메이션 파라미터)
                AnimatedContainer(
                  duration: AppAnimation.slow,
                  curve: Curves.easeInOut,
                  width: AppLayout.checkboxMd,
                  height: AppLayout.checkboxMd,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? ColorTokens.error.withValues(alpha: 0.20)
                        : ColorTokens.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isCompleted
                          ? ColorTokens.error
                          : context.themeColors.textPrimaryWithAlpha(0.50),
                      width: AppLayout.borderThick,
                    ),
                  ),
                  // 체크 아이콘: 조건부 렌더링 대신 AnimatedOpacity로 부드럽게 전환
                  child: AnimatedOpacity(
                    opacity: isCompleted ? 1.0 : 0.0,
                    duration: AppAnimation.slow,
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.check,
                      color: ColorTokens.error,
                      size: AppSpacing.lg,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // 색상 인디케이터 바
                Container(
                  width: AppLayout.colorBarWidth,
                  height: AppLayout.colorBarHeight,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),

                // 루틴명 (완료 시 빨간펜 취소선 애니메이션 적용)
                Expanded(
                  child: AnimatedStrikethrough(
                    text: widget.item.name,
                    style: AppTypography.bodyMd.copyWith(
                      color: context.themeColors.textPrimary,
                    ),
                    isActive: isCompleted,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // 시간 범위 표시
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: AppLayout.iconSm,
                      color: context.themeColors.textPrimaryWithAlpha(0.55),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      '${widget.item.startTime} ~ ${widget.item.endTime}',
                      style: AppTypography.captionMd.copyWith(
                        color: context.themeColors.textPrimaryWithAlpha(0.55),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
