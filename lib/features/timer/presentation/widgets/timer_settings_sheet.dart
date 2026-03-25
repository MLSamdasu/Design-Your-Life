// F6: 타이머 설정 바텀시트 위젯
// 집중·짧은 휴식·긴 휴식·세션 횟수를 조절하고 Hive에 즉시 저장한다.
// idle 상태에서만 변경 가능 (실행 중 변경 방지).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/timer_provider.dart';
import 'timer_setting_slider_tile.dart';
import 'timer_settings_persistence.dart';

/// 타이머 설정 바텀시트 — 포모도로 시간을 사용자가 직접 조절한다
class TimerSettingsSheet extends ConsumerWidget {
  const TimerSettingsSheet({super.key});

  /// 바텀시트를 표시하는 정적 팩토리 메서드
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.transparent, // GlassCard 스타일 유지
      isScrollControlled: true,
      builder: (_) => const TimerSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusMin = ref.watch(timerFocusMinutesProvider);
    final shortBreakMin = ref.watch(timerShortBreakMinutesProvider);
    final longBreakMin = ref.watch(timerLongBreakMinutesProvider);
    final sessions = ref.watch(timerSessionsBeforeLongBreakProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: MiscLayout.sheetMinSize,
      maxChildSize: 0.7,
      builder: (context, scrollController) => GlassCard(
        variant: GlassCardVariant.elevated,
        borderRadius: AppRadius.pill,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildHandle(context),
            _buildHeader(context),
            Expanded(
              child: _buildSettingsList(
                context, ref, scrollController,
                focusMin: focusMin,
                shortBreakMin: shortBreakMin,
                longBreakMin: longBreakMin,
                sessions: sessions,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 드래그 핸들 (바텀시트 상단)
  Widget _buildHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Container(
        width: AppSpacing.massive,
        height: AppSpacing.xs,
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.30),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),
    );
  }

  /// 헤더 영역 — 아이콘 + 타이틀
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(Icons.settings_rounded,
              color: context.themeColors.accent, size: AppLayout.iconLg),
          const SizedBox(width: AppSpacing.md),
          Text(
            '타이머 설정',
            style: AppTypography.titleLg
                .copyWith(color: context.themeColors.textPrimary),
          ),
        ],
      ),
    );
  }

  /// 설정 슬라이더 목록 + 기본값 복원 버튼
  Widget _buildSettingsList(
    BuildContext context,
    WidgetRef ref,
    ScrollController scrollController, {
    required int focusMin,
    required int shortBreakMin,
    required int longBreakMin,
    required int sessions,
  }) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl, vertical: AppSpacing.md,
      ),
      children: [
        // 집중 시간 (5~60분, 5분 단위)
        TimerSettingSliderTile(
          label: '집중 시간', value: focusMin,
          min: 5, max: 60, step: 5, unit: '분',
          icon: Icons.local_fire_department_rounded,
          iconColor: ColorTokens.errorLight,
          onChanged: (v) => saveFocusMinutes(ref, v),
        ),
        const SizedBox(height: AppSpacing.lg),
        // 짧은 휴식 (1~15분, 1분 단위)
        TimerSettingSliderTile(
          label: '짧은 휴식', value: shortBreakMin,
          min: 1, max: 15, step: 1, unit: '분',
          icon: Icons.coffee_rounded,
          iconColor: ColorTokens.success,
          onChanged: (v) => saveShortBreak(ref, v),
        ),
        const SizedBox(height: AppSpacing.lg),
        // 긴 휴식 (5~30분, 5분 단위)
        TimerSettingSliderTile(
          label: '긴 휴식', value: longBreakMin,
          min: 5, max: 30, step: 5, unit: '분',
          icon: Icons.self_improvement_rounded,
          iconColor: ColorTokens.infoLight,
          onChanged: (v) => saveLongBreak(ref, v),
        ),
        const SizedBox(height: AppSpacing.lg),
        // 긴 휴식 전 세션 횟수 (2~8회, 1회 단위)
        TimerSettingSliderTile(
          label: '긴 휴식 간격', value: sessions,
          min: 2, max: 8, step: 1, unit: '세션',
          icon: Icons.repeat_rounded,
          iconColor: ColorTokens.warningDark,
          onChanged: (v) => saveSessionsBeforeLong(ref, v),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _buildResetButton(context, ref),
      ],
    );
  }

  /// 기본값 복원 버튼
  Widget _buildResetButton(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        onPressed: () => resetTimerSettingsToDefaults(ref),
        icon: Icon(Icons.restore_rounded,
            color: context.themeColors.textPrimaryWithAlpha(0.6),
            size: AppLayout.iconSm),
        label: Text(
          '기본값으로 복원',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.6),
          ),
        ),
      ),
    );
  }
}
