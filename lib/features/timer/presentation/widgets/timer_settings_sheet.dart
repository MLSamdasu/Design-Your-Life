// F6: 타이머 설정 바텀시트 위젯
// 집중 시간, 짧은 휴식, 긴 휴식, 긴 휴식 전 세션 횟수를 조절한다.
// 변경 즉시 Hive에 저장하여 앱 재시작 후에도 설정이 유지된다.
// idle 상태에서만 설정 변경이 가능하다 (실행 중 변경 방지).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/global_providers.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/timer_state.dart';
import '../../providers/timer_provider.dart';

/// 타이머 설정 바텀시트
/// 포모도로 시간 설정을 사용자가 직접 조절할 수 있다
class TimerSettingsSheet extends ConsumerWidget {
  const TimerSettingsSheet({super.key});

  /// 바텀시트를 표시하는 정적 팩토리 메서드
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      // 배경 투명 처리로 GlassCard 스타일 유지
      backgroundColor: ColorTokens.transparent,
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
      minChildSize: AppLayout.sheetMinSize,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return GlassCard(
          variant: GlassCardVariant.elevated,
          borderRadius: AppRadius.pill,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // 드래그 핸들
              _buildHandle(context),

              // 헤더
              _buildHeader(context),

              // 설정 항목 목록
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.md,
                  ),
                  children: [
                    // 집중 시간 설정 (5~60분, 5분 단위)
                    _SettingSliderTile(
                      label: '집중 시간',
                      value: focusMin,
                      min: 5,
                      max: 60,
                      step: 5,
                      unit: '분',
                      icon: Icons.local_fire_department_rounded,
                      iconColor: ColorTokens.errorLight,
                      onChanged: (val) => _saveFocusMinutes(ref, val),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 짧은 휴식 시간 설정 (1~15분, 1분 단위)
                    _SettingSliderTile(
                      label: '짧은 휴식',
                      value: shortBreakMin,
                      min: 1,
                      max: 15,
                      step: 1,
                      unit: '분',
                      icon: Icons.coffee_rounded,
                      iconColor: ColorTokens.success,
                      onChanged: (val) => _saveShortBreak(ref, val),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 긴 휴식 시간 설정 (5~30분, 5분 단위)
                    _SettingSliderTile(
                      label: '긴 휴식',
                      value: longBreakMin,
                      min: 5,
                      max: 30,
                      step: 5,
                      unit: '분',
                      icon: Icons.self_improvement_rounded,
                      iconColor: ColorTokens.infoLight,
                      onChanged: (val) => _saveLongBreak(ref, val),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 긴 휴식 전 세션 횟수 설정 (2~8회, 1회 단위)
                    _SettingSliderTile(
                      label: '긴 휴식 간격',
                      value: sessions,
                      min: 2,
                      max: 8,
                      step: 1,
                      unit: '세션',
                      icon: Icons.repeat_rounded,
                      iconColor: ColorTokens.warningDark,
                      onChanged: (val) => _saveSessionsBeforeLong(ref, val),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // 기본값 복원 버튼
                    _buildResetButton(context, ref),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  /// 헤더 영역
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(
            Icons.settings_rounded,
            color: context.themeColors.accent,
            size: AppLayout.iconLg,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '타이머 설정',
            style: AppTypography.titleLg.copyWith(
              color: context.themeColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 기본값 복원 버튼
  Widget _buildResetButton(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _resetToDefaults(ref),
        icon: Icon(
          Icons.restore_rounded,
          color: context.themeColors.textPrimaryWithAlpha(0.6),
          size: AppLayout.iconSm,
        ),
        label: Text(
          '기본값으로 복원',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.6),
          ),
        ),
      ),
    );
  }

  // ─── 설정 저장 메서드 ──────────────────────────────────────────────────

  /// 집중 시간을 Hive에 저장하고 Provider를 갱신한다
  void _saveFocusMinutes(WidgetRef ref, int value) {
    ref.read(timerFocusMinutesProvider.notifier).state = value;
    ref.read(hiveCacheServiceProvider).saveSetting(
          AppConstants.settingsKeyTimerFocusMinutes,
          value,
        );
    // idle 상태이면 타이머 표시도 갱신한다
    _refreshTimerIfIdle(ref);
  }

  /// 짧은 휴식 시간을 Hive에 저장하고 Provider를 갱신한다
  void _saveShortBreak(WidgetRef ref, int value) {
    ref.read(timerShortBreakMinutesProvider.notifier).state = value;
    ref.read(hiveCacheServiceProvider).saveSetting(
          AppConstants.settingsKeyTimerShortBreakMinutes,
          value,
        );
  }

  /// 긴 휴식 시간을 Hive에 저장하고 Provider를 갱신한다
  void _saveLongBreak(WidgetRef ref, int value) {
    ref.read(timerLongBreakMinutesProvider.notifier).state = value;
    ref.read(hiveCacheServiceProvider).saveSetting(
          AppConstants.settingsKeyTimerLongBreakMinutes,
          value,
        );
  }

  /// 긴 휴식 전 세션 횟수를 Hive에 저장하고 Provider를 갱신한다
  void _saveSessionsBeforeLong(WidgetRef ref, int value) {
    ref.read(timerSessionsBeforeLongBreakProvider.notifier).state = value;
    ref.read(hiveCacheServiceProvider).saveSetting(
          AppConstants.settingsKeyTimerSessionsBeforeLongBreak,
          value,
        );
  }

  /// idle 상태이면 타이머 표시를 새 설정값으로 갱신한다
  /// 실행 중이거나 일시정지 상태에서는 진행 상태를 보호하기 위해 리셋하지 않는다
  void _refreshTimerIfIdle(WidgetRef ref) {
    final phase = ref.read(timerStateProvider).phase;
    if (phase == TimerPhase.idle) {
      ref.read(timerStateProvider.notifier).reset();
    }
  }

  /// 모든 설정을 기본값으로 복원한다
  void _resetToDefaults(WidgetRef ref) {
    _saveFocusMinutes(ref, 25);
    _saveShortBreak(ref, 5);
    _saveLongBreak(ref, 15);
    _saveSessionsBeforeLong(ref, 4);
  }
}

/// 슬라이더가 포함된 설정 항목 타일
/// 라벨 + 아이콘 + 현재값 표시 + 슬라이더를 제공한다
class _SettingSliderTile extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final void Function(int) onChanged;

  const _SettingSliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 슬라이더의 divisions 수 계산 (범위 / 단위)
    final divisions = (max - min) ~/ step;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨 + 현재값 표시 행
        Row(
          children: [
            // 카테고리 아이콘
            Container(
              width: AppLayout.containerMd,
              height: AppLayout.containerMd,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: iconColor, size: AppLayout.iconSm),
            ),
            const SizedBox(width: AppSpacing.md),
            // 라벨
            Text(
              label,
              style: AppTypography.bodyLg.copyWith(
                color: context.themeColors.textPrimary,
                fontWeight: AppTypography.weightMedium,
              ),
            ),
            const Spacer(),
            // 현재값 뱃지
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.mdLg,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: context.themeColors.accentWithAlpha(0.15),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Text(
                '$value$unit',
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.accent,
                  fontWeight: AppTypography.weightSemiBold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // 슬라이더
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: context.themeColors.accent,
            inactiveTrackColor: context.themeColors.textPrimaryWithAlpha(0.15),
            thumbColor: context.themeColors.accent,
            overlayColor: context.themeColors.accentWithAlpha(0.15),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            onChanged: (val) {
              // step 단위로 반올림하여 정수 값으로 전달한다
              final stepped = (val / step).round() * step;
              onChanged(stepped.clamp(min, max));
            },
          ),
        ),
      ],
    );
  }
}
