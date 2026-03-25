// 데일리 리추얼 Pages 2-6: 목표 입력 페이지
// 한 페이지에 5개의 목표 입력 필드를 표시한다.
// pageIndex에 따라 목표 1-5, 6-10, 11-15, 16-20, 21-25를 표시한다.
// 이전에 저장된 목표가 있으면 자동으로 채워진다.

import 'package:flutter/material.dart';

import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../widgets/ritual_glass_container.dart';
import '../widgets/ritual_goal_field.dart';

/// 목표 입력 페이지 (Pages 2-6)
/// [pageIndex]: 0~4 (0이면 목표 1-5, 4이면 목표 21-25)
/// [controllers]: 해당 페이지의 5개 TextEditingController
/// [onGoalChanged]: 목표 텍스트 변경 콜백 (goalIndex, text)
/// [isPreFilled]: true이면 기존 데이터가 로드된 상태 (안내 문구 표시)
class RitualGoalsPage extends StatelessWidget {
  final int pageIndex;
  final List<TextEditingController> controllers;
  final void Function(int goalIndex, String text)? onGoalChanged;
  final bool isPreFilled;

  const RitualGoalsPage({
    super.key,
    required this.pageIndex,
    required this.controllers,
    this.onGoalChanged,
    this.isPreFilled = false,
  });

  /// 이 페이지에 표시할 목표 시작 번호 (1-based)
  int get _startNumber => pageIndex * 5 + 1;

  /// 이 페이지에 표시할 목표 끝 번호 (1-based)
  int get _endNumber => _startNumber + 4;

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    // 부모(DailyRitualScreen)에서 SafeArea + 상하 패딩을 이미 적용한다
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          // 페이지 제목 + 진행률
          _buildHeader(tc),
          const SizedBox(height: AppSpacing.xl),
          // 목표 입력 영역
          Expanded(
            child: RitualGlassContainer(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _buildGoalFields(tc),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  /// 페이지 헤더 (제목 + 진행률 + 프리필 안내 표시)
  Widget _buildHeader(ResolvedThemeColors tc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '목표 $_startNumber-$_endNumber',
          style: AppTypography.headingLg.copyWith(
            color: tc.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // 전체 25개 중 현재 그룹 위치 표시
        Row(
          children: [
            Text(
              '25개 중 ',
              style: AppTypography.bodySm.copyWith(
                color: tc.textPrimaryWithAlpha(0.55),
              ),
            ),
            Text(
              '$_startNumber-$_endNumber',
              style: AppTypography.bodyMd.copyWith(
                // 어두운 배경에서도 번호가 선명하도록 테마 인식 악센트 사용
                color: tc.accent,
              ),
            ),
          ],
        ),
        // 프리필 안내 문구 (재방문 사용자만)
        if (isPreFilled) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            '이전에 저장한 목표입니다. '
            '수정이 필요하면 변경하세요.',
            style: AppTypography.captionMd.copyWith(
              color: tc.accent.withValues(alpha: 0.70),
            ),
          ),
        ],
      ],
    );
  }

  /// 5개의 목표 입력 필드 리스트
  Widget _buildGoalFields(ResolvedThemeColors tc) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: controllers.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, i) {
        final goalNumber = _startNumber + i;
        return RitualGoalField(
          index: goalNumber,
          controller: controllers[i],
          onChanged: (text) {
            // 전체 목표 인덱스로 변환하여 콜백 호출
            onGoalChanged?.call(goalNumber - 1, text);
          },
        );
      },
    );
  }
}
