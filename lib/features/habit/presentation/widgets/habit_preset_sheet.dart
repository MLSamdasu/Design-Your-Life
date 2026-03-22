// F4 위젯: HabitPresetSheet - 인기 습관 프리셋 선택 바텀 시트
// 미리 정의된 5개 인기 습관 중 선택 후 빈도(매일/특정 요일)를 설정한다.
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/habit.dart';
import '../../../habit/presentation/widgets/routine_form_widgets.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 습관 생성 결과 (프리셋 + 빈도 정보)
class HabitCreateResult {
  final HabitPreset preset;
  final HabitFrequency frequency;
  final List<int> repeatDays;

  const HabitCreateResult({
    required this.preset,
    required this.frequency,
    required this.repeatDays,
  });
}

/// 인기 습관 프리셋 선택 + 빈도 설정 바텀 시트
class HabitPresetSheet extends StatefulWidget {
  final ValueChanged<HabitCreateResult> onSelected;

  const HabitPresetSheet({required this.onSelected, super.key});

  @override
  State<HabitPresetSheet> createState() => _HabitPresetSheetState();
}

class _HabitPresetSheetState extends State<HabitPresetSheet> {
  /// 선택된 프리셋 (null이면 프리셋 선택 단계)
  HabitPreset? _selectedPreset;

  /// 빈도가 '특정 요일'인지 여부 (false면 매일)
  bool _isCustomFrequency = false;

  /// 선택된 요일 집합 (1=월 ... 7=일)
  final Set<int> _selectedDays = {};

  /// 프리셋 선택 시 빈도 설정 단계로 전환한다
  void _onPresetTap(HabitPreset preset) {
    setState(() {
      _selectedPreset = preset;
      _isCustomFrequency = false;
      _selectedDays.clear();
    });
  }

  /// 프리셋 선택 단계로 되돌아간다
  void _goBack() {
    setState(() {
      _selectedPreset = null;
      _isCustomFrequency = false;
      _selectedDays.clear();
    });
  }

  /// 습관 생성을 완료한다
  void _submit() {
    if (_selectedPreset == null) return;
    // 특정 요일 선택 시 요일이 하나 이상 필요하다
    if (_isCustomFrequency && _selectedDays.isEmpty) return;

    final frequency =
        _isCustomFrequency ? HabitFrequency.weekly : HabitFrequency.daily;
    final repeatDays = _isCustomFrequency
        ? (_selectedDays.toList()..sort())
        : <int>[];

    widget.onSelected(HabitCreateResult(
      preset: _selectedPreset!,
      frequency: frequency,
      repeatDays: repeatDays,
    ));
  }

  /// 완료 버튼 활성화 조건: 매일이거나, 특정 요일에서 1개 이상 선택
  bool get _canSubmit =>
      !_isCustomFrequency || _selectedDays.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.massive)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppLayout.modalBlurSigma, sigmaY: AppLayout.modalBlurSigma),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.15),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadius.massive)),
            border: Border.all(
                color: context.themeColors.textPrimaryWithAlpha(0.2)),
          ),
          child: AnimatedSwitcher(
            duration: AppAnimation.normal,
            child: _selectedPreset == null
                ? _buildPresetList(context)
                : _buildFrequencyStep(context),
          ),
        ),
        ),
      ),
    );
  }

  /// 단계 1: 프리셋 목록
  Widget _buildPresetList(BuildContext context) {
    return Column(
      key: const ValueKey('preset_list'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '인기 습관으로 시작하기',
          style: AppTypography.titleMd
              .copyWith(color: context.themeColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xl),
        // 프리셋이 많을 경우 화면 높이의 50%로 제한하여 오버플로우 방지
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * AppLayout.bottomSheetContentMaxRatio,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: HabitPreset.presets.length,
            itemBuilder: (context, index) {
              final preset = HabitPreset.presets[index];
              return GestureDetector(
                onTap: () => _onPresetTap(preset),
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: context.themeColors.textPrimaryWithAlpha(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                        color: context.themeColors
                            .textPrimaryWithAlpha(0.15)),
                  ),
                  child: Row(
                    children: [
                      // emojiLg 토큰 사용 (22px 이모지 전용)
                      Text(preset.icon, style: AppTypography.emojiLg),
                      const SizedBox(width: AppSpacing.lg),
                      // 긴 프리셋명 오버플로우 방지
                      Expanded(
                        child: Text(
                          preset.name,
                          style: AppTypography.bodyMd.copyWith(
                              color: context.themeColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: context.themeColors
                            .textPrimaryWithAlpha(0.4),
                        size: AppLayout.iconSm,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  /// 단계 2: 빈도 설정
  Widget _buildFrequencyStep(BuildContext context) {
    return Column(
      key: const ValueKey('frequency_step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더: 뒤로가기 + 선택된 습관 이름
        Row(
          children: [
            GestureDetector(
              onTap: _goBack,
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: context.themeColors.textPrimaryWithAlpha(0.6),
                size: AppLayout.iconMd,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            if (_selectedPreset!.icon.isNotEmpty) ...[
              Text(_selectedPreset!.icon, style: AppTypography.emojiLg),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                _selectedPreset!.name,
                style: AppTypography.titleMd
                    .copyWith(color: context.themeColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        // 빈도 라벨
        RoutineFormLabel(label: '반복 빈도'),
        const SizedBox(height: AppSpacing.md),

        // 매일 / 특정 요일 토글
        Row(
          children: [
            Expanded(
              child: _FrequencyToggle(
                label: '매일',
                isSelected: !_isCustomFrequency,
                onTap: () => setState(() {
                  _isCustomFrequency = false;
                  _selectedDays.clear();
                }),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _FrequencyToggle(
                label: '특정 요일',
                isSelected: _isCustomFrequency,
                onTap: () => setState(() => _isCustomFrequency = true),
              ),
            ),
          ],
        ),

        // 특정 요일 선택 시 요일 선택기 표시
        if (_isCustomFrequency) ...[
          const SizedBox(height: AppSpacing.xl),
          RoutineFormLabel(label: '반복 요일'),
          const SizedBox(height: AppSpacing.md),
          RoutineDaySelector(
            selectedDays: _selectedDays,
            onToggle: (day) => setState(() {
              _selectedDays.contains(day)
                  ? _selectedDays.remove(day)
                  : _selectedDays.add(day);
            }),
          ),
        ],

        const SizedBox(height: AppSpacing.xxl),

        // 완료 버튼
        GestureDetector(
          onTap: _canSubmit ? _submit : null,
          child: AnimatedContainer(
            duration: AppAnimation.fast,
            height: AppLayout.formButtonHeight,
            decoration: BoxDecoration(
              color: _canSubmit
                  ? ColorTokens.main
                  : context.themeColors.textPrimaryWithAlpha(0.12),
              borderRadius: BorderRadius.circular(AppRadius.xlLg),
              boxShadow: _canSubmit
                  ? [
                      BoxShadow(
                        color: ColorTokens.main.withValues(alpha: 0.4),
                        blurRadius: AppLayout.shadowBlurMd,
                        offset: const Offset(0, AppLayout.shadowOffsetSm),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '습관 추가하기',
                style: AppTypography.titleMd.copyWith(
                  // MAIN 컬러 배경 위이므로 활성 시 흰색이 적절하다
                  color: _canSubmit
                      ? ColorTokens.white
                      : context.themeColors.textPrimaryWithAlpha(0.35),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// 빈도 토글 버튼 (매일 / 특정 요일)
class _FrequencyToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.mdLg),
        decoration: BoxDecoration(
          color: isSelected
              ? context.themeColors.accentWithAlpha(0.85)
              : context.themeColors.textPrimaryWithAlpha(0.08),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isSelected
                ? context.themeColors.accent
                : context.themeColors.textPrimaryWithAlpha(0.18),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              color: context.themeColors.textPrimary,
              fontWeight: isSelected ? AppTypography.weightBold : AppTypography.weightRegular,
            ),
          ),
        ),
      ),
    );
  }
}
