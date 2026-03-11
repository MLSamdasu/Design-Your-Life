// F3 위젯: QuickInputBar - 자연어 빠른 투두 입력 바
// 텍스트 입력 시 NlpTodoParser로 실시간 파싱 → 미리보기 표시
// Enter 키 입력 시 파싱 결과를 onSubmit 콜백으로 전달한다
// Glassmorphism 스타일, GlassInputField 패턴을 따른다.
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/nlp/nlp_todo_parser.dart';
import '../../../../core/nlp/parsed_todo.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 빠른 입력 결과 콜백 타입
typedef QuickInputCallback = void Function(ParsedTodo result);

/// 자연어 빠른 입력 바 (F20)
/// [onSubmit]: 파싱 결과가 유효할 때 호출되는 콜백
/// Glassmorphism 스타일로 투두 화면 상단에 배치된다
class QuickInputBar extends StatefulWidget {
  /// 파싱 결과가 유효할 때 호출되는 콜백
  final QuickInputCallback onSubmit;

  const QuickInputBar({super.key, required this.onSubmit});

  @override
  State<QuickInputBar> createState() => _QuickInputBarState();
}

class _QuickInputBarState extends State<QuickInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  /// 현재 파싱된 결과 (실시간 업데이트)
  ParsedTodo? _parsed;

  /// 포커스 상태 (border 색상 전환에 사용)
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    // 포커스 변경 감지로 border 색상을 전환한다
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  /// 텍스트 변경 시 실시간으로 자연어를 파싱한다
  void _onChanged(String text) {
    if (text.trim().isEmpty) {
      // 빈 입력이면 미리보기를 숨긴다
      setState(() => _parsed = null);
      return;
    }
    // NlpTodoParser를 호출하여 파싱 결과를 갱신한다
    final result = NlpTodoParser.parse(text);
    setState(() => _parsed = result);
  }

  /// Enter 키 또는 전송 버튼 탭 시 파싱 결과를 제출한다
  void _onSubmit() {
    final parsed = _parsed;
    // 파싱 결과가 유효한 경우에만 제출한다 (제목이 비어있지 않아야 함)
    if (parsed == null || !parsed.isValid) return;

    widget.onSubmit(parsed);
    // 입력 필드와 미리보기를 초기화한다
    _controller.clear();
    setState(() => _parsed = null);
  }

  @override
  Widget build(BuildContext context) {
    final hasParsed = _parsed != null &&
        (_parsed!.hasDate || _parsed!.hasTime || _parsed!.title.isNotEmpty);
    final hasText = _controller.text.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassDecoration.defaultBlurSigma,
          sigmaY: GlassDecoration.defaultBlurSigma,
        ),
        child: AnimatedContainer(
          duration: AppAnimation.normal,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.12),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              // 포커스 상태에서 border를 밝게 한다
              color: _isFocused
                  ? context.themeColors.textPrimaryWithAlpha(0.45)
                  : context.themeColors.textPrimaryWithAlpha(0.18),
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 입력 행: 번개 아이콘 + 텍스트 필드 + (전송 버튼)
              Row(
                children: [
                  const SizedBox(width: AppSpacing.lgXl),
                  // 빠른 입력 아이콘: 배경 테마에 맞는 악센트 색상으로 강조한다
                  Icon(
                    Icons.flash_on_rounded,
                    color: context.themeColors.accent,
                    size: AppLayout.iconLg,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onChanged,
                      onSubmitted: (_) => _onSubmit(),
                      cursorColor: context.themeColors.textPrimary,
                      style: AppTypography.bodyMd.copyWith(
                    color: context.themeColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: "빠른 입력: '내일 오후 3시 미팅' 입력 후 Enter",
                        hintStyle: AppTypography.bodyMd.copyWith(
                          color: context.themeColors.textPrimaryWithAlpha(0.38),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: AppSpacing.lg,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  // 전송 버튼: 텍스트가 있을 때만 표시한다
                  if (hasText)
                    IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        // 전송 버튼: 배경 테마에 맞는 악센트 색상을 사용한다
                        color: context.themeColors.accent,
                        size: AppLayout.iconLg,
                      ),
                      onPressed: _onSubmit,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                    )
                  else
                    const SizedBox(width: AppSpacing.lgXl),
                ],
              ),
              // 파싱 미리보기: 파싱 결과가 있을 때만 표시한다
              if (hasParsed) ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  color: context.themeColors.textPrimaryWithAlpha(0.12),
                  indent: 14,
                  endIndent: 14,
                ),
                _ParsePreview(parsed: _parsed!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 파싱 결과 미리보기 위젯 (QuickInputBar 내부 private 위젯)
/// 날짜/시간/제목이 파싱된 경우 각각 아이콘과 함께 표시한다
class _ParsePreview extends StatelessWidget {
  /// 표시할 파싱 결과
  final ParsedTodo parsed;

  const _ParsePreview({required this.parsed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          // 날짜 표시: 파싱된 날짜가 있을 때만 보여준다
          if (parsed.hasDate)
            _PreviewChip(
              emoji: '📅',
              label: AppDateUtils.toShortDate(parsed.date!),
            ),
          // 시간 표시: 파싱된 시간이 있을 때만 보여준다
          if (parsed.hasTime)
            _PreviewChip(
              emoji: '⏰',
              label: _formatTime(parsed.time!),
            ),
          // 제목 표시: 제목이 있을 때만 보여준다
          if (parsed.title.isNotEmpty)
            _PreviewChip(
              emoji: '✏️',
              label: parsed.title,
            ),
        ],
      ),
    );
  }

  /// TimeOfDay를 "오전/오후 H:MM" 형식으로 포맷한다
  String _formatTime(TimeOfDay time) {
    final isAm = time.hour < 12;
    final displayHour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minuteStr = time.minute.toString().padLeft(2, '0');
    final amPm = isAm ? '오전' : '오후';
    return '$amPm $displayHour:$minuteStr';
  }
}

/// 미리보기 개별 칩 위젯 (이모지 + 라벨 조합)
class _PreviewChip extends StatelessWidget {
  /// 앞에 표시할 이모지
  final String emoji;

  /// 표시할 텍스트 라벨
  final String label;

  const _PreviewChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: AppTypography.captionMd.copyWith(fontSize: 12),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.captionMd.copyWith(
            // 파싱 미리보기 라벨: 배경 테마에 맞는 악센트 색상을 사용한다
            color: context.themeColors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
