// F4 위젯: RoutineListView - 내 루틴 뷰
// 루틴 카드 리스트 + 주간 시간표 그리드를 표시한다.
// 빈 상태: "아직 등록된 루틴이 없어요" + "첫 루틴 만들기" CTA
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/routine.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../providers/routine_provider.dart';
import 'routine_card.dart';
import 'routine_create_dialog.dart';
import 'weekly_timetable.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 내 루틴 서브탭 뷰
class RoutineListView extends ConsumerWidget {
  const RoutineListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoutineListSection(routinesAsync: routinesAsync),
          const SizedBox(height: AppSpacing.xxl),
          routinesAsync.when(
            data: (r) {
              final active = r.where((x) => x.isActive).toList();
              return active.isEmpty
                  ? const SizedBox.shrink()
                  : _WeeklySection(routines: active);
            },
            loading: () => const SizedBox.shrink(),
            // 루틴 로드 실패 시 빈 위젯 대신 오류 메시지를 표시한다
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                '루틴 정보를 불러오지 못했어요',
                style: AppTypography.bodyMd.copyWith(
                  color: ColorTokens.infoHint.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _RoutineListSection extends ConsumerWidget {
  final AsyncValue<List<Routine>> routinesAsync;
  const _RoutineListSection({required this.routinesAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('내 루틴',
                  style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary)),
              const Spacer(),
              _AddBtn(onTap: () => _showDialog(context, ref)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          routinesAsync.when(
            data: (routines) {
              if (routines.isEmpty) {
                return EmptyState(
                  icon: Icons.repeat_rounded,
                  mainText: '아직 등록된 루틴이 없어요',
                  subText: '루틴을 추가하여 주간 시간표를 만들어보세요!',
                  ctaLabel: '첫 루틴 만들기',
                  onCtaTap: () => _showDialog(context, ref),
                );
              }
              return AnimatedSwitcher(
                duration: AppAnimation.medium,
                child: Column(
                  key: ValueKey(routines.length),
                  children: routines
                      .map((r) => RoutineCard(
                            key: Key(r.id),
                            routine: r,
                            // 루틴 삭제 실패 시 SnackBar로 오류를 표시한다
                            onDelete: () async {
                              try {
                                await ref.read(deleteRoutineProvider).call(r.id);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('루틴 삭제에 실패했습니다'),
                                      backgroundColor: ColorTokens.infoHintBg,
                                    ),
                                  );
                                }
                              }
                            },
                            // 루틴 활성 상태 토글 실패 시 SnackBar로 오류를 표시한다
                            onToggleActive: (a) async {
                              try {
                                await ref.read(toggleRoutineActiveProvider).call(r.id, a);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('루틴 상태 변경에 실패했습니다'),
                                      backgroundColor: ColorTokens.infoHintBg,
                                    ),
                                  );
                                }
                              }
                            },
                          ))
                      .toList(),
                ),
              );
            },
            loading: () => Column(
              children: List.generate(
                2,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.mdLg),
                  child: LoadingSkeleton(height: 72, borderRadius: 16),
                ),
              ),
            ),
            // 루틴 목록 로드 실패 시 빈 위젯 대신 오류 메시지를 표시한다
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                '루틴 목록을 불러오지 못했어요',
                style: AppTypography.bodyMd.copyWith(
                  color: ColorTokens.infoHint.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref) async {
    final result = await RoutineCreateDialog.show(context);
    if (result == null) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final now = DateTime.now();
    // 루틴 생성 실패 시 SnackBar로 사용자에게 오류를 알린다
    try {
      await ref.read(createRoutineProvider).call(Routine(
            id: ref.read(generateRoutineIdProvider).call(),
            userId: userId,
            name: result.name,
            repeatDays: result.repeatDays,
            startTime: result.startTime,
            endTime: result.endTime,
            colorIndex: result.colorIndex,
            createdAt: now,
            updatedAt: now,
          ));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('루틴 추가에 실패했습니다'),
            backgroundColor: ColorTokens.infoHintBg,
          ),
        );
      }
    }
  }
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBtn({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mdLg, vertical: AppSpacing.xs),
        // 추가 버튼: 배경 테마에 맞는 악센트 색상으로 표시한다
        decoration: BoxDecoration(
          color: context.themeColors.accentWithAlpha(0.3),
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(color: context.themeColors.accentWithAlpha(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: AppLayout.iconSm, color: context.themeColors.textPrimary),
            const SizedBox(width: AppSpacing.xs),
            Text('추가',
                style: AppTypography.captionLg.copyWith(color: context.themeColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _WeeklySection extends StatelessWidget {
  final List<Routine> routines;
  const _WeeklySection({required this.routines});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Text('주간 시간표',
              style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary)),
        ),
        GlassmorphicCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: WeeklyTimetable(routines: routines),
        ),
      ],
    );
  }
}
