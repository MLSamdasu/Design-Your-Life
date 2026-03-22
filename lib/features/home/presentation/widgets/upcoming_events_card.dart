// F1: 홈 대시보드 다가오는 일정 카드
// upcomingEventsProvider에서 오늘의 남은 이벤트 + 미완료 투두를 시간순으로 표시한다.
// 탭 시 캘린더 화면으로 이동한다.
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
import '../../../todo/providers/todo_provider.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';

/// 홈 대시보드 - 다가오는 일정 카드
/// 캘린더 화면 진입점 역할을 한다
class UpcomingEventsCard extends ConsumerWidget {
  const UpcomingEventsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 동기 Provider: 직접 값을 사용한다
    final items = ref.watch(upcomingEventsProvider);

    return GlassCard(
      variant: GlassCardVariant.defaultCard,
      child: _buildContent(context, ref, items),
    );
  }

  /// 실제 콘텐츠
  Widget _buildContent(BuildContext context, WidgetRef ref, List<UpcomingEventItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 카드 헤더: 아이콘 + 제목 + 캘린더 이동 화살표
        Row(
          children: [
            // 일정 아이콘 컨테이너
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
                Icons.event_note_rounded,
                // WCAG 대비: accent 배경 위에서 테마 색상으로 고대비 확보
                color: context.themeColors.textPrimaryWithAlpha(0.8),
                size: AppLayout.iconXxl,
              ),
            ),
            const SizedBox(width: AppSpacing.xl),

            // 일정 제목 + 개수 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '다가오는 일정',
                    style: AppTypography.titleLg.copyWith(
                      color: context.themeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    items.isEmpty
                        ? '오늘 남은 일정이 없어요'
                        : '${items.length}개의 일정이 남아있어요',
                    style: AppTypography.bodyMd.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.70),
                    ),
                  ),
                ],
              ),
            ),

            // 캘린더 화면으로 이동 화살표
            GestureDetector(
              onTap: () => context.go(RoutePaths.calendar),
              child: Icon(
                Icons.chevron_right_rounded,
                color: context.themeColors.textPrimaryWithAlpha(0.40),
                size: AppLayout.iconXl,
              ),
            ),
          ],
        ),

        // 일정 목록 또는 빈 상태
        if (items.isEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          EmptyState(
            icon: Icons.event_available_rounded,
            mainText: '오늘 남은 일정이 없어요',
            ctaLabel: '캘린더 보러 가기',
            onCtaTap: () => context.go(RoutePaths.calendar),
            minHeight: 100,
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.xl),
          Divider(color: context.themeColors.dividerColor, height: 1),
          const SizedBox(height: AppSpacing.lg),
          // 일정 아이템 목록 (시간순 정렬)
          ...items.map((item) {
            return _UpcomingEventItemRow(item: item);
          }),
        ],
      ],
    );
  }
}

/// 다가오는 일정 아이템 행 위젯
/// 투두 이벤트: 체크박스(빨간 스타일) + 색상 인디케이터 + 제목 + 시간 라벨
/// 일반 이벤트: 색상 인디케이터 + 제목 + 시간 라벨 (표시만)
/// 투두 이벤트만 스케일 바운스 애니메이션을 적용한다
class _UpcomingEventItemRow extends ConsumerStatefulWidget {
  final UpcomingEventItem item;

  const _UpcomingEventItemRow({required this.item});

  @override
  ConsumerState<_UpcomingEventItemRow> createState() =>
      _UpcomingEventItemRowState();
}

class _UpcomingEventItemRowState extends ConsumerState<_UpcomingEventItemRow>
    with SingleTickerProviderStateMixin {
  /// 투두 이벤트만 AnimationController를 생성한다 (비투두 이벤트는 null)
  AnimationController? _bounceController;
  Animation<double>? _bounceAnimation;

  @override
  void initState() {
    super.initState();
    // 투두 이벤트만 스케일 바운스 애니메이션을 생성한다
    // 비대화형 일반 이벤트는 AnimationController를 생성하지 않아 리소스를 절약한다
    if (widget.item.isTodoEvent) {
      _bounceController = AnimationController(
        duration: AppAnimation.slow,
        vsync: this,
      );
      _bounceAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.02), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 30),
      ]).animate(CurvedAnimation(
        parent: _bounceController!,
        curve: Curves.easeInOut,
      ));
    }
  }

  @override
  void dispose() {
    _bounceController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 투두 이벤트만 탭으로 완료 토글을 지원한다
      onTap: widget.item.isTodoEvent
          ? () {
              // Reduced Motion 확인: 접근성 설정 시 바운스 생략
              final reduceMotion = MediaQuery.disableAnimationsOf(context);
              if (!reduceMotion) {
                _bounceController?.forward(from: 0.0);
              }
              ref.read(toggleTodoProvider)(widget.item.id, !widget.item.isCompleted);
            }
          : null,
      behavior: widget.item.isTodoEvent
          ? HitTestBehavior.opaque
          : HitTestBehavior.deferToChild,
      // 투두 이벤트만 ScaleTransition 바운스를 적용한다
      // 비투두 이벤트는 AnimationController가 null이므로 ScaleTransition을 생략한다
      child: _bounceAnimation != null
          ? ScaleTransition(
              scale: _bounceAnimation!,
              child: _buildContent(context),
            )
          : _buildContent(context),
    );
  }

  /// 이벤트 아이템 콘텐츠 (ScaleTransition과 분리하여 재사용한다)
  Widget _buildContent(BuildContext context) {
    final color = ColorTokens.eventColor(widget.item.colorIndex);
    return AnimatedOpacity(
      opacity: widget.item.isCompleted ? 0.50 : 1.0,
      duration: AppAnimation.textFade,
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.mdLg),
        child: Row(
          children: [
            // 투두 이벤트: 빨간색 체크박스 표시
            if (widget.item.isTodoEvent) ...[
              AnimatedContainer(
                duration: AppAnimation.slow,
                curve: Curves.easeInOut,
                width: AppLayout.checkboxMd,
                height: AppLayout.checkboxMd,
                decoration: BoxDecoration(
                  color: widget.item.isCompleted
                      ? ColorTokens.error.withValues(alpha: 0.20)
                      : ColorTokens.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: widget.item.isCompleted
                        ? ColorTokens.error
                        : context.themeColors.textPrimaryWithAlpha(0.50),
                    width: AppLayout.borderThick,
                  ),
                ),
                // 체크 아이콘: 조건부 렌더링 대신 AnimatedOpacity로 부드럽게 전환
                child: AnimatedOpacity(
                  opacity: widget.item.isCompleted ? 1.0 : 0.0,
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
            ],

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

            // 일정/투두 제목 (완료 시 빨간펜 취소선 애니메이션 적용)
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

            // 시간 라벨 표시
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
                  widget.item.timeLabel,
                  style: AppTypography.captionMd.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.55),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
