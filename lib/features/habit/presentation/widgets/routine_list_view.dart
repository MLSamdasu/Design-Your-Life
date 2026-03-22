// F4 위젯: RoutineListView - 내 루틴 뷰
// 루틴 카드 리스트 + 주간 시간표 그리드를 표시한다.
// 빈 상태: "아직 등록된 루틴이 없어요" + "첫 루틴 만들기" CTA
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/routine.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../providers/routine_provider.dart';
import 'routine_card.dart';
import 'routine_create_dialog.dart';
import 'weekly_timetable.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/bottom_scroll_spacer.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

/// 내 루틴 서브탭 뷰
class RoutineListView extends ConsumerWidget {
  const RoutineListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // routinesProvider는 동기 Provider이므로 직접 사용한다
    final routines = ref.watch(routinesProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoutineListSection(routines: routines),
          const SizedBox(height: AppSpacing.xxl),
          () {
            final active = routines.where((x) => x.isActive).toList();
            return active.isEmpty
                ? const SizedBox.shrink()
                : _WeeklySection(routines: active);
          }(),
          // 하단 여백: 마지막 콘텐츠를 화면 중앙까지 스크롤 가능하도록 화면 절반 높이
          const BottomScrollSpacer(),
        ],
      ),
    );
  }
}

class _RoutineListSection extends ConsumerWidget {
  final List<Routine> routines;
  const _RoutineListSection({required this.routines});

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
          // routinesProvider는 동기 Provider이므로 직접 사용한다
          () {
            if (routines.isEmpty) {
              return EmptyState(
                icon: Icons.repeat_rounded,
                mainText: '아직 등록된 루틴이 없어요',
                subText: '루틴을 추가하여 주간 시간표를 만들어보세요!',
                ctaLabel: '첫 루틴 만들기',
                onCtaTap: () => _showDialog(context, ref),
              );
            }
            // 개별 루틴 카드를 RepaintBoundary로 감싸 불필요한 리페인트를 방지한다
            return Column(
              children: routines
                  .map((r) => RepaintBoundary(
                        child: RoutineCard(
                          key: Key(r.id),
                          routine: r,
                          // 루틴 삭제 실패 시 SnackBar로 오류를 표시한다
                          onDelete: () async {
                            try {
                              await ref.read(deleteRoutineProvider).call(r.id);
                            } catch (e) {
                              if (context.mounted) {
                                AppSnackBar.showError(context, '루틴 삭제에 실패했습니다');
                              }
                            }
                          },
                          // 루틴 수정 다이얼로그를 표시한다
                          onEdit: () => _showEditDialog(context, ref, r),
                          // 루틴 활성 상태 토글 실패 시 SnackBar로 오류를 표시한다
                          onToggleActive: (a) async {
                            try {
                              await ref.read(toggleRoutineActiveProvider).call(r.id, a);
                            } catch (e) {
                              if (context.mounted) {
                                AppSnackBar.showError(context, '루틴 상태 변경에 실패했습니다');
                              }
                            }
                          },
                        ),
                      ))
                  .toList(),
            );
          }(),
        ],
      ),
    );
  }

  /// 루틴 수정 다이얼로그를 표시한다 (RoutineCreateDialog를 수정 모드로 열기)
  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, Routine routine) async {
    // 기존 루틴 데이터를 RoutineCreateResult로 변환하여 초기값으로 전달한다
    final initialData = RoutineCreateResult(
      name: routine.name,
      repeatDays: routine.repeatDays,
      startTime: routine.startTime,
      endTime: routine.endTime,
      colorIndex: routine.colorIndex,
    );
    final result = await RoutineCreateDialog.show(context, initialData: initialData);
    if (result == null) return;
    // 루틴 수정 실패 시 SnackBar로 사용자에게 오류를 알린다
    try {
      final updated = routine.copyWith(
        name: result.name,
        repeatDays: result.repeatDays,
        startTime: result.startTime,
        endTime: result.endTime,
        colorIndex: result.colorIndex,
      );
      await ref.read(updateRoutineProvider).call(routine.id, updated);
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, '루틴 수정에 실패했습니다');
      }
    }
  }

  Future<void> _showDialog(BuildContext context, WidgetRef ref) async {
    final result = await RoutineCreateDialog.show(context);
    if (result == null) return;
    // 로컬 퍼스트: 인증 없이도 루틴을 생성할 수 있다
    final userId = ref.read(currentUserIdProvider) ?? AppConstants.localUserId;
    final now = DateTime.now();
    // 루틴 생성 실패 시 SnackBar로 사용자에게 오류를 알린다
    try {
      await ref.read(createRoutineProvider).call(Routine(
            id: '',  // Repository에서 UUID v4로 ID를 생성하므로 빈 문자열 전달
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
        AppSnackBar.showError(context, '루틴 추가에 실패했습니다');
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
